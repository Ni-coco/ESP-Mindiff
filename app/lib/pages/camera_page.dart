import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

// ---------------------------------------------------------------------------
// Squat Analyzer
// ---------------------------------------------------------------------------

enum SquatPhase { standing, descending, bottom, ascending }

class SquatFeedback {
  final int repCount;
  final SquatPhase phase;
  final double kneeAngle;      // angle au genou (degrés)
  final double hipAngle;       // angle à la hanche
  final String advice;         // conseil textuel
  final Color skeletonColor;   // couleur du skeleton selon qualité

  const SquatFeedback({
    required this.repCount,
    required this.phase,
    required this.kneeAngle,
    required this.hipAngle,
    required this.advice,
    required this.skeletonColor,
  });
}

class SquatAnalyzer {
  int _repCount = 0;
  SquatPhase _phase = SquatPhase.standing;

  // Seuils en degrés
  static const double _standingThreshold = 160.0;  // genou quasi droit
  static const double _bottomThreshold = 100.0;    // genou bien fléchi
  static const double _goodSquatAngle = 90.0;      // angle idéal

  SquatFeedback analyze(Pose pose) {
    final lHip = pose.landmarks[PoseLandmarkType.leftHip];
    final lKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final lAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

    // Fallback si points non détectés
    if (lHip == null || lKnee == null || lAnkle == null || lShoulder == null) {
      return SquatFeedback(
        repCount: _repCount,
        phase: _phase,
        kneeAngle: 0,
        hipAngle: 0,
        advice: 'Positionnez tout le corps dans le cadre',
        skeletonColor: const Color(0xFF00E5FF),
      );
    }

    final kneeAngle = _calcAngle(lHip, lKnee, lAnkle);
    final hipAngle = _calcAngle(lShoulder, lHip, lKnee);

    // Machine à états pour compter les reps
    switch (_phase) {
      case SquatPhase.standing:
        if (kneeAngle < _standingThreshold - 20) {
          _phase = SquatPhase.descending;
        }
      case SquatPhase.descending:
        if (kneeAngle <= _bottomThreshold) {
          _phase = SquatPhase.bottom;
        } else if (kneeAngle > _standingThreshold) {
          _phase = SquatPhase.standing; // remonté sans aller en bas
        }
      case SquatPhase.bottom:
        if (kneeAngle > _bottomThreshold + 15) {
          _phase = SquatPhase.ascending;
        }
      case SquatPhase.ascending:
        if (kneeAngle >= _standingThreshold) {
          _phase = SquatPhase.standing;
          _repCount++;
        }
    }

    final advice = _getAdvice(kneeAngle, hipAngle, _phase);
    final color = _getColor(kneeAngle, hipAngle, _phase);

    return SquatFeedback(
      repCount: _repCount,
      phase: _phase,
      kneeAngle: kneeAngle,
      hipAngle: hipAngle,
      advice: advice,
      skeletonColor: color,
    );
  }

  double _calcAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final cross = ab.dx * cb.dy - ab.dy * cb.dx;
    return (atan2(cross.abs(), dot) * 180 / pi).abs();
  }

  String _getAdvice(double knee, double hip, SquatPhase phase) {
    if (phase == SquatPhase.standing) return 'Prêt — fléchissez les genoux';
    if (phase == SquatPhase.descending) {
      if (knee > 130) return 'Continuez à descendre...';
      if (hip < 70) return 'Gardez le dos droit !';
      return 'Bonne descente, continuez';
    }
    if (phase == SquatPhase.bottom) {
      if (knee > _goodSquatAngle + 15) return 'Descendez encore un peu';
      if (hip < 60) return 'Attention au dos, gardez-le droit';
      return '✓ Bonne profondeur !';
    }
    if (phase == SquatPhase.ascending) return 'Remontez en poussant sur les talons';
    return '';
  }

  Color _getColor(double knee, double hip, SquatPhase phase) {
    if (phase == SquatPhase.standing) return const Color(0xFF00E5FF); // cyan neutre
    if (phase == SquatPhase.bottom) {
      // Vert si bon angle, orange si trop haut
      if (knee <= _goodSquatAngle + 15) return const Color(0xFF00E676); // vert
      return const Color(0xFFFF9100); // orange
    }
    if (hip < 65) return const Color(0xFFFF5252); // rouge = dos penché
    return const Color(0xFF00E5FF);
  }

  void reset() {
    _repCount = 0;
    _phase = SquatPhase.standing;
  }
}

// ---------------------------------------------------------------------------
// CameraPage
// ---------------------------------------------------------------------------

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  final SquatAnalyzer _squatAnalyzer = SquatAnalyzer();
  List<Pose> _poses = [];
  SquatFeedback? _feedback;
  bool _isDetecting = false;
  bool _permissionGranted = false;
  bool _initialized = false;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndInit();
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
      SquatFeedback? feedback;
      if (poses.isNotEmpty) {
        feedback = _squatAnalyzer.analyze(poses.first);
      }
      setState(() {
        _poses = poses;
        _imageSize = imageSize;
        _feedback = feedback;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) return _buildPermissionDenied();
    if (!_initialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),

        // Skeleton overlay
        if (_poses.isNotEmpty && _imageSize != null)
          CustomPaint(
            painter: PoseOverlayPainter(
              poses: _poses,
              imageSize: _imageSize!,
              skeletonColor: _feedback?.skeletonColor ?? const Color(0xFF00E5FF),
            ),
          ),

        // Rep counter (top left)
        Positioned(
          top: 48,
          left: 16,
          child: _RepCounter(count: _feedback?.repCount ?? 0),
        ),

        // Angle display (top right)
        if (_feedback != null && _feedback!.kneeAngle > 0)
          Positioned(
            top: 48,
            right: 16,
            child: _AngleDisplay(
              kneeAngle: _feedback!.kneeAngle,
              hipAngle: _feedback!.hipAngle,
            ),
          ),

        // Advice banner (bottom)
        Positioned(
          bottom: 32,
          left: 16,
          right: 16,
          child: _AdviceBanner(
            advice: _feedback?.advice ?? 'Positionnez-vous devant la caméra',
            color: _feedback?.skeletonColor ?? const Color(0xFF00E5FF),
          ),
        ),

        // Reset button
        Positioned(
          top: 48,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                _squatAnalyzer.reset();
                setState(() => _feedback = null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Squat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Accès caméra requis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Veuillez autoriser l\'accès à la caméra\ndans les paramètres.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: openAppSettings,
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// UI Widgets
// ---------------------------------------------------------------------------

class _RepCounter extends StatelessWidget {
  final int count;
  const _RepCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('REPS', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5)),
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1)),
        ],
      ),
    );
  }
}

class _AngleDisplay extends StatelessWidget {
  final double kneeAngle;
  final double hipAngle;
  const _AngleDisplay({required this.kneeAngle, required this.hipAngle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _angleLine('Genou', kneeAngle),
          const SizedBox(height: 4),
          _angleLine('Hanche', hipAngle),
        ],
      ),
    );
  }

  Widget _angleLine(String label, double angle) {
    final color = label == 'Genou'
        ? (angle < 100 ? const Color(0xFF00E676) : Colors.white)
        : (angle < 70 ? const Color(0xFFFF5252) : Colors.white);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text('${angle.toStringAsFixed(0)}°', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _AdviceBanner extends StatelessWidget {
  final String advice;
  final Color color;
  const _AdviceBanner({required this.advice, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Text(
        advice,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600),
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

    for (final pose in poses) {
      for (final connection in _skeletonConnections) {
        final start = pose.landmarks[connection[0]];
        final end = pose.landmarks[connection[1]];
        if (start == null || end == null) continue;
        if (start.likelihood < 0.5 || end.likelihood < 0.5) continue;
        canvas.drawLine(_tp(start.x, start.y, size), _tp(end.x, end.y, size), linePaint);
      }

      for (final landmark in pose.landmarks.values) {
        if (landmark.likelihood < 0.5) continue;
        canvas.drawCircle(_tp(landmark.x, landmark.y, size), 5, dotPaint);
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
