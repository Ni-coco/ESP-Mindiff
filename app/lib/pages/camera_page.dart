import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'exercise_analyzer.dart';

// ---------------------------------------------------------------------------
// CameraPage
// ---------------------------------------------------------------------------

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {
  // Camera & ML
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  List<Pose> _poses = [];
  bool _isDetecting = false;
  bool _permissionGranted = false;
  bool _initialized = false;
  Size? _imageSize;

  // Exercise selection
  int _selectedIndex = 0;
  late List<ExerciseAnalyzer> _analyzers;
  ExerciseFeedback? _feedback;
  final PageController _pageController = PageController(
    viewportFraction: 0.38,
    initialPage: 0,
  );

  // Animation
  late AnimationController _switchAnim;
  late Animation<double> _fadeAnim;

  // TTS
  final FlutterTts _tts = FlutterTts();
  String _lastSpokenAdvice = '';
  bool _isSpeaking = false;
  bool _ttsEnabled = true;

  @override
  void initState() {
    super.initState();
    _analyzers = kExercises;
    _switchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _switchAnim, curve: Curves.easeInOut);
    _switchAnim.forward();
    _initTts();
    _requestPermissionAndInit();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() => _isSpeaking = false);
  }

  void _speakAdvice(String advice) {
    if (!_ttsEnabled || advice == _lastSpokenAdvice || _isSpeaking) return;
    if (advice == 'Positionnez-vous devant la caméra') return;
    _lastSpokenAdvice = advice;
    _isSpeaking = true;
    _tts.speak(advice);
  }

  Future<void> _requestPermissionAndInit() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _permissionGranted = true);
      await _initCamera();
    } else {
      setState(() => _permissionGranted = false);
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() => _initialized = true);

    _cameraController!.startImageStream((CameraImage image) {
      if (_isDetecting) return;
      _isDetecting = true;
      _detectPose(image, camera.sensorOrientation).then((_) {
        _isDetecting = false;
      });
    });
  }

  Future<void> _detectPose(CameraImage image, int sensorOrientation) async {
    if (_poseDetector == null) return;

    final Uint8List bytes = Uint8List.fromList(
      image.planes.expand((plane) => plane.bytes).toList(),
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(sensorOrientation) ??
            InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    final poses = await _poseDetector!.processImage(inputImage);

    if (mounted) {
      final imageSize = Size(image.height.toDouble(), image.width.toDouble());
      ExerciseFeedback? feedback;
      if (poses.isNotEmpty) {
        feedback = _analyzers[_selectedIndex].analyze(poses.first);
      }
      setState(() {
        _poses = poses;
        _imageSize = imageSize;
        _feedback = feedback;
      });
      if (feedback != null && feedback.advice.isNotEmpty) {
        _speakAdvice(feedback.advice);
      }
    }
  }

  void _onPageChanged(int index) {
    if (index == _selectedIndex) return;
    _analyzers[_selectedIndex].reset();
    _lastSpokenAdvice = '';
    _tts.stop();
    setState(() {
      _selectedIndex = index;
      _feedback = null;
    });
    _switchAnim.forward(from: 0);
  }

  void _selectExercise(int index) {
    if (index == _selectedIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _resetCurrentExercise() {
    _analyzers[_selectedIndex].reset();
    _lastSpokenAdvice = '';
    setState(() => _feedback = null);
  }

  @override
  void dispose() {
    _tts.stop();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseDetector?.close();
    _pageController.dispose();
    _switchAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) return _buildPermissionDenied();
    if (!_initialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF00E5FF)),
              SizedBox(height: 16),
              Text('Initialisation de la caméra...',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final exercise = _analyzers[_selectedIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera feed ──────────────────────────────────────────────────
          CameraPreview(_cameraController!),

          // ── Skeleton overlay ─────────────────────────────────────────────
          if (_poses.isNotEmpty && _imageSize != null)
            CustomPaint(
              painter: PoseOverlayPainter(
                poses: _poses,
                imageSize: _imageSize!,
                skeletonColor:
                    _feedback?.skeletonColor ?? const Color(0xFF00E5FF),
              ),
            ),

          // ── Dark gradient top ─────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Dark gradient bottom ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Top bar: exercise name + reset ───────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Exercise badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              const Color(0xFF00E5FF).withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(exercise.emoji,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            exercise.name.replaceAll('\n', ' '),
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // TTS toggle button
                    GestureDetector(
                      onTap: () {
                        setState(() => _ttsEnabled = !_ttsEnabled);
                        if (!_ttsEnabled) _tts.stop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          _ttsEnabled
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: _ttsEnabled
                              ? const Color(0xFF00E5FF)
                              : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Reset button
                    GestureDetector(
                      onTap: _resetCurrentExercise,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: Colors.white70, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Rep counter + angles (top overlay) ──────────────────────────
          Positioned(
            top: 100,
            left: 16,
            child: _RepCounter(
              count: _feedback?.repCount ?? 0,
              isSeconds: _analyzers[_selectedIndex] is PlankAnalyzer,
            ),
          ),

          if (_feedback != null && _feedback!.angles.isNotEmpty)
            Positioned(
              top: 100,
              right: 16,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _AngleDisplay(angles: _feedback!.angles),
              ),
            ),

          // ── Advice banner ────────────────────────────────────────────────
          Positioned(
            bottom: 130,
            left: 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _AdviceBanner(
                advice: _feedback?.advice ??
                    'Positionnez-vous devant la caméra',
                color: _feedback?.skeletonColor ?? const Color(0xFF00E5FF),
                phase: _feedback?.phase ?? '',
              ),
            ),
          ),

          // ── Exercise Slider ───────────────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _ExerciseSlider(
              exercises: _analyzers,
              selectedIndex: _selectedIndex,
              pageController: _pageController,
              onPageChanged: _onPageChanged,
              onTap: _selectExercise,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Accès caméra requis',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            const Text(
              'Veuillez autoriser l\'accès à la caméra\ndans les paramètres.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: openAppSettings,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black),
              child: const Text('Ouvrir les paramètres'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise Slider Widget
// ---------------------------------------------------------------------------

class _ExerciseSlider extends StatelessWidget {
  final List<ExerciseAnalyzer> exercises;
  final int selectedIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onTap;

  const _ExerciseSlider({
    required this.exercises,
    required this.selectedIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: PageView.builder(
        controller: pageController,
        itemCount: exercises.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final exercise = exercises[index];
          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: isSelected ? 0 : 10,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00E5FF)
                      : Colors.white.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    exercise.emoji,
                    style: TextStyle(
                        fontSize: isSelected ? 28 : 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF00E5FF)
                          : Colors.white70,
                      fontSize: isSelected ? 11 : 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// UI Widgets
// ---------------------------------------------------------------------------

class _RepCounter extends StatelessWidget {
  final int count;
  final bool isSeconds;
  const _RepCounter({required this.count, this.isSeconds = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            isSeconds ? 'SEC' : 'REPS',
            style: const TextStyle(
                color: Colors.white54, fontSize: 10, letterSpacing: 2),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AngleDisplay extends StatelessWidget {
  final Map<String, double> angles;
  const _AngleDisplay({required this.angles});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: angles.entries
            .map((e) => _angleLine(e.key, e.value))
            .toList(),
      ),
    );
  }

  Widget _angleLine(String label, double angle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ',
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Text('${angle.toStringAsFixed(0)}°',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AdviceBanner extends StatelessWidget {
  final String advice;
  final Color color;
  final String phase;
  const _AdviceBanner(
      {required this.advice, required this.color, required this.phase});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              advice,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton Painter
// ---------------------------------------------------------------------------

const _skeletonConnections = [
  [PoseLandmarkType.leftEar, PoseLandmarkType.leftEye],
  [PoseLandmarkType.leftEye, PoseLandmarkType.nose],
  [PoseLandmarkType.nose, PoseLandmarkType.rightEye],
  [PoseLandmarkType.rightEye, PoseLandmarkType.rightEar],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
  [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
  [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
  [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
  [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
  [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
];

class PoseOverlayPainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final bool isFrontCamera;
  final Color skeletonColor;

  PoseOverlayPainter({
    required this.poses,
    required this.imageSize,
    this.isFrontCamera = false,
    this.skeletonColor = const Color(0xFF00E5FF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = skeletonColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = skeletonColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      for (final connection in _skeletonConnections) {
        final start = pose.landmarks[connection[0]];
        final end = pose.landmarks[connection[1]];
        if (start == null || end == null) continue;
        if (start.likelihood < 0.5 || end.likelihood < 0.5) continue;
        canvas.drawLine(
            _tp(start.x, start.y, size), _tp(end.x, end.y, size), linePaint);
      }

      for (final landmark in pose.landmarks.values) {
        if (landmark.likelihood < 0.5) continue;
        final pt = _tp(landmark.x, landmark.y, size);
        canvas.drawCircle(pt, 7, highlightPaint);
        canvas.drawCircle(pt, 4, dotPaint);
      }
    }
  }

  Offset _tp(double x, double y, Size canvasSize) {
    final dx = (x / imageSize.width) * canvasSize.width;
    final dy = (y / imageSize.height) * canvasSize.height;
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(PoseOverlayPainter old) =>
      old.poses != poses || old.skeletonColor != skeletonColor;
}
