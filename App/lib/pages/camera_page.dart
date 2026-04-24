import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mindiff_app/controllers/active_programme_controller.dart';
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
  List<CameraDescription> _cameras = [];
  bool _isFrontCamera = true;
  bool _isAnalyzing = false;

  // Pause entre séries
  bool _isResting = false;
  int _restSeconds = 0;
  static const _restDuration = 60; // secondes de pause

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
  bool _isSpeaking = false;
  bool _ttsEnabled = true;
  int _lastSpokenRep = 0;
  String _pendingAdvice = '';
  int _pendingAdviceFrames = 0;
  String _lastSpokenAdvice = '';
  DateTime _lastAdviceAt = DateTime(2000);
  static const _adviceCooldown = Duration(seconds: 4);
  static const _adviceFrameThreshold = 8;

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

  static final _emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}'
    r'\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}'
    r'\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}\u{200D}\u{20E3}'
    r'\u{E0020}-\u{E007F}]',
    unicode: true,
  );

  void _speak(String text) {
    final clean = text.replaceAll(_emojiRegex, '').trim();
    if (clean.isEmpty) return;
    if (_isSpeaking) {
      _tts.stop();
    }
    _isSpeaking = true;
    _tts.speak(clean);
  }

  void _processTts(ExerciseFeedback feedback) {
    if (!_ttsEnabled) return;

    // 1. Reps : toujours annoncer quand ça change
    if (feedback.repCount > 0 && feedback.repCount != _lastSpokenRep) {
      _lastSpokenRep = feedback.repCount;
      _speak('${feedback.repCount}');
      return;
    }

    // 2. Conseils de correction : seulement si le même conseil persiste
    final advice = feedback.advice;
    if (advice.isEmpty || advice == 'Positionnez-vous devant la caméra') return;

    if (advice == _pendingAdvice) {
      _pendingAdviceFrames++;
    } else {
      _pendingAdvice = advice;
      _pendingAdviceFrames = 1;
    }

    if (_pendingAdviceFrames >= _adviceFrameThreshold &&
        advice != _lastSpokenAdvice &&
        DateTime.now().difference(_lastAdviceAt) > _adviceCooldown) {
      _lastSpokenAdvice = advice;
      _lastAdviceAt = DateTime.now();
      _speak(advice);
    }
  }

  // === MODIFICATION RGPD : TRANSPARENCE AVANT DEMANDE ===
  Future<void> _requestPermissionAndInit() async {
    // Vérifie si on a déjà la permission
    var status = await Permission.camera.status;

    if (status.isGranted) {
      if (!mounted) return;
      setState(() => _permissionGranted = true);
      await _initCamera();
      return;
    }

    // Si on n'a pas la permission, on affiche un dialogue RGPD
    if (mounted) {
      await Get.defaultDialog(
        title: "Analyse de posture par IA",
        titlePadding: const EdgeInsets.only(top: 24),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          children: [
            const Text(
              "Mindiff a besoin de votre caméra pour analyser vos mouvements en temps réel.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🔒 Traitement 100% local", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                  SizedBox(height: 4),
                  Text("❌ Aucune vidéo enregistrée", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                  SizedBox(height: 4),
                  Text("❌ Aucune image envoyée sur nos serveurs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
        barrierDismissible: false,
        confirm: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 45),
          ),
          onPressed: () async {
            Get.back(); // Ferme le dialogue explicatif

            // Déclenche la VRAIE demande système
            status = await Permission.camera.request();
            if (!mounted) return;

            if (status.isGranted) {
              setState(() => _permissionGranted = true);
              await _initCamera();
            } else {
              setState(() => _permissionGranted = false);
            }
          },
          child: const Text("J'ai compris, autoriser"),
        ),
      );
    }
  }
  // ========================================================

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    _poseDetector ??= PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );

    await _startCamera();
  }

  Future<void> _startCamera() async {
    final direction = _isFrontCamera
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final camera = _cameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _cameras.first,
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
      if (!_isAnalyzing || _isDetecting) return;
      _isDetecting = true;
      _detectPose(image, camera.sensorOrientation).then((_) {
        _isDetecting = false;
      });
    });
  }

  Future<void> _switchCamera() async {
    setState(() => _initialized = false);
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _isFrontCamera = !_isFrontCamera;
    _poses = [];
    _feedback = null;
    await _startCamera();
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final nv21 = Uint8List(width * height + (width * height ~/ 2));

    // Copy Y plane
    int index = 0;
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        nv21[index++] = yPlane.bytes[row * yPlane.bytesPerRow + col];
      }
    }

    // Interleave V and U planes into NV21 format (VUVU...)
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;
    for (int row = 0; row < uvHeight; row++) {
      for (int col = 0; col < uvWidth; col++) {
        nv21[index++] = vPlane.bytes[row * vPlane.bytesPerRow + col * (vPlane.bytesPerPixel ?? 1)];
        nv21[index++] = uPlane.bytes[row * uPlane.bytesPerRow + col * (uPlane.bytesPerPixel ?? 1)];
      }
    }

    return nv21;
  }

  bool _isPoseReliable(Pose pose) {
    // Vérifier que les landmarks clés du corps ont une confiance > 0.7
    const keyLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    ];
    for (final type in keyLandmarks) {
      final lm = pose.landmarks[type];
      if (lm == null || lm.likelihood < 0.7) return false;
    }
    return true;
  }

  Future<void> _detectPose(CameraImage image, int sensorOrientation) async {
    if (_poseDetector == null) return;

    final bytes = _yuv420ToNv21(image);

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(sensorOrientation) ??
            InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );

    final poses = await _poseDetector!.processImage(inputImage);

    if (mounted) {
      final imageSize = Size(image.height.toDouble(), image.width.toDouble());
      ExerciseFeedback? feedback;
      if (poses.isNotEmpty && _isPoseReliable(poses.first)) {
        feedback = _analyzers[_selectedIndex].analyze(poses.first);
      }
      setState(() {
        _poses = poses;
        _imageSize = imageSize;
        _feedback = feedback;
      });
      if (feedback != null) {
        _processTts(feedback);
        _checkAutoValidate(feedback.repCount);
      }
    }
  }

  void _onPageChanged(int index) {
    if (index == _selectedIndex) return;
    _analyzers[_selectedIndex].reset();
    _lastSpokenRep = 0;
    _lastSpokenAdvice = '';
    _pendingAdvice = '';
    _pendingAdviceFrames = 0;
    _tts.stop();
    setState(() {
      _selectedIndex = index;
      _feedback = null;
      _isAnalyzing = false;
      _poses = [];
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

  void _toggleAnalyzing() {
    if (_isAnalyzing) {
      // On arrête l'analyse — valider la série si programme actif
      final reps = _feedback?.repCount ?? 0;
      final analyzerKey = _analyzerKeyForIndex(_selectedIndex);
      _tryValidateSerie(analyzerKey, reps);
      setState(() {
        _isAnalyzing = false;
        _poses = [];
        _feedback = null;
        _tts.stop();
      });
    } else {
      // Reset l'analyzer avant de démarrer
      _analyzers[_selectedIndex].reset();
      _lastSpokenRep = 0;
      setState(() {
        _isAnalyzing = true;
        _feedback = null;
      });
    }
  }

  String? _analyzerKeyForIndex(int index) {
    for (final entry in kAnalyzerKeyToIndex.entries) {
      if (entry.value == index) return entry.key;
    }
    return null;
  }

  String? _getProgrammeInfo(String? analyzerKey) {
    if (analyzerKey == null) return null;
    try {
      final ctrl = Get.find<ActiveProgrammeController>();
      if (!ctrl.hasActive) return null;
      final data = ctrl.activeProgramme.value!;
      final seance = data.seanceEnCours;
      if (seance == null) return null;
      final exo = data.exercices.cast<ProgrammeExercice?>().firstWhere(
            (e) => e!.analyzerKey == analyzerKey,
            orElse: () => null,
          );
      if (exo == null) return null;
      final prog = seance.progressions[analyzerKey];
      final serie = (prog?.seriesCompletes ?? 0) + 1;
      final unit = exo.isSeconds ? 'sec' : 'reps';
      return '${data.nom} — Série $serie/${exo.series} • Objectif ${exo.repsCible} $unit';
    } catch (_) {
      return null;
    }
  }

  void _checkAutoValidate(int reps) {
    if (!_isAnalyzing || reps <= 0) return;
    final analyzerKey = _analyzerKeyForIndex(_selectedIndex);
    if (analyzerKey == null) return;

    try {
      final ctrl = Get.find<ActiveProgrammeController>();
      if (!ctrl.hasActive) return;
      final data = ctrl.activeProgramme.value!;
      final seance = data.seanceEnCours;
      if (seance == null) return;

      final exo = data.exercices.cast<ProgrammeExercice?>().firstWhere(
            (e) => e!.analyzerKey == analyzerKey,
            orElse: () => null,
          );
      if (exo == null) return;

      final prog = seance.progressions[analyzerKey];
      if (prog != null && prog.estTermine(exo)) return;

      // Auto-valider quand on atteint les reps cibles
      if (reps >= exo.repsCible) {
        _tryValidateSerie(analyzerKey, reps);
        _startRest(exo, prog);
      }
    } catch (_) {}
  }

  void _startRest(ProgrammeExercice exo, ExerciceProgression? prog) {
    final seriesFaites = prog?.seriesCompletes ?? 0;
    // Si toutes les séries sont faites, pas de pause
    if (seriesFaites >= exo.series) {
      _speak('${exo.nom} terminé !');
      setState(() {
        _isAnalyzing = false;
        _poses = [];
        _feedback = null;
      });
      return;
    }

    // Lancer la pause
    _speak('Série terminée. Repos.');
    setState(() {
      _isAnalyzing = false;
      _isResting = true;
      _restSeconds = _restDuration;
      _poses = [];
      _feedback = null;
    });

    _tickRest();
  }

  Future<void> _tickRest() async {
    while (_restSeconds > 0 && _isResting && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isResting) return;
      setState(() => _restSeconds--);
    }
    if (!mounted || !_isResting) return;

    // Fin de la pause — relancer l'analyse
    _speak('C\'est reparti !');
    _analyzers[_selectedIndex].reset();
    _lastSpokenRep = 0;
    setState(() {
      _isResting = false;
      _isAnalyzing = true;
      _feedback = null;
    });
  }

  void _skipRest() {
    setState(() {
      _isResting = false;
      _restSeconds = 0;
    });
    _analyzers[_selectedIndex].reset();
    _lastSpokenRep = 0;
    setState(() {
      _isAnalyzing = true;
      _feedback = null;
    });
  }

  void _tryValidateSerie(String? analyzerKey, int reps) {
    if (analyzerKey == null || reps <= 0) return;
    try {
      final ctrl = Get.find<ActiveProgrammeController>();
      if (!ctrl.hasActive) return;
      final data = ctrl.activeProgramme.value!;
      final seance = data.seanceEnCours;
      if (seance == null) return;
      // Vérifier que cet exercice fait partie du programme
      final hasExo =
          data.exercices.any((e) => e.analyzerKey == analyzerKey);
      if (!hasExo) return;
      ctrl.validerSerie(analyzerKey, reps);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Série validée ! $reps reps'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  void _resetCurrentExercise() {
    _analyzers[_selectedIndex].reset();
    _lastSpokenRep = 0;
    _lastSpokenAdvice = '';
    _pendingAdvice = '';
    _pendingAdviceFrames = 0;
    setState(() => _feedback = null);
  }

  @override
  void dispose() {
    _isResting = false;
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
          if (_isAnalyzing && _poses.isNotEmpty && _imageSize != null)
            CustomPaint(
              painter: PoseOverlayPainter(
                poses: _poses,
                imageSize: _imageSize!,
                isFrontCamera: _isFrontCamera,
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

          // ── Top bar: exercise name + actions ──────────────────────────────
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
                        color: _isAnalyzing
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isAnalyzing
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.3),
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
                            style: TextStyle(
                              color: _isAnalyzing
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_isAnalyzing) ...[
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
                      const SizedBox(width: 8),
                    ],
                    // Switch camera button
                    GestureDetector(
                      onTap: _switchCamera,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(Icons.cameraswitch_rounded,
                            color: Colors.white70, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Play / Stop analysis button
                    GestureDetector(
                      onTap: _isResting ? null : _toggleAnalyzing,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isAnalyzing
                              ? Colors.red.withValues(alpha: 0.25)
                              : const Color(0xFF00E5FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isAnalyzing
                                ? Colors.red.withValues(alpha: 0.6)
                                : const Color(0xFF00E5FF).withValues(alpha: 0.6),
                          ),
                        ),
                        child: Icon(
                          _isAnalyzing
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: _isAnalyzing
                              ? Colors.red
                              : const Color(0xFF00E5FF),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Programme objective badge ────────────────────────────────────
          if (_isAnalyzing) Builder(builder: (_) {
            final key = _analyzerKeyForIndex(_selectedIndex);
            final info = _getProgrammeInfo(key);
            if (info == null) return const SizedBox.shrink();
            return Positioned(
              top: 80,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  info,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),

          // ── Analyzing UI (rep counter, angles, advice) ────────────────────
          if (_isAnalyzing) ...[
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
          ],

          // ── Rest timer overlay ─────────────────────────────────────────
          if (_isResting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'REPOS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_restSeconds}s',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _restSeconds / _restDuration,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF00E5FF)),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _skipRest,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white30, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PASSER',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
        if (start.likelihood < 0.75 || end.likelihood < 0.75) continue;
        canvas.drawLine(
            _tp(start.x, start.y, size), _tp(end.x, end.y, size), linePaint);
      }

      for (final landmark in pose.landmarks.values) {
        if (landmark.likelihood < 0.75) continue;
        final pt = _tp(landmark.x, landmark.y, size);
        canvas.drawCircle(pt, 7, highlightPaint);
        canvas.drawCircle(pt, 4, dotPaint);
      }
    }
  }

  Offset _tp(double x, double y, Size canvasSize) {
    double dx = (x / imageSize.width) * canvasSize.width;
    final dy = (y / imageSize.height) * canvasSize.height;
    if (isFrontCamera) {
      dx = canvasSize.width - dx;
    }
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(PoseOverlayPainter old) =>
      old.poses != poses || old.skeletonColor != skeletonColor;
}