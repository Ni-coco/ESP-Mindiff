import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  List<Pose> _poses = [];
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

    // Prefer front camera
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
      // sensorOrientation=90: image buffer is landscape (640x480)
      // but ML Kit processes it rotated → coords are in portrait space (480x640)
      final imageSize = Size(image.height.toDouble(), image.width.toDouble());

      setState(() {
        _poses = poses;
        _imageSize = imageSize;
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
    if (!_permissionGranted) {
      return _buildPermissionDenied();
    }
    if (!_initialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        if (_poses.isNotEmpty && _imageSize != null)
          CustomPaint(
            painter: PoseOverlayPainter(
              poses: _poses,
              imageSize: _imageSize!,
              previewSize: MediaQuery.of(context).size,
              isFrontCamera: false,
            ),
          ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _poses.isEmpty
                    ? 'Positionnez-vous devant la caméra'
                    : '${_poses.length} personne(s) détectée(s)',
                style: const TextStyle(color: Colors.white, fontSize: 14),
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
          const Text(
            'Accès caméra requis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
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

// --- Skeleton connections ---
const _skeletonConnections = [
  // Face
  [PoseLandmarkType.leftEar, PoseLandmarkType.leftEye],
  [PoseLandmarkType.leftEye, PoseLandmarkType.nose],
  [PoseLandmarkType.nose, PoseLandmarkType.rightEye],
  [PoseLandmarkType.rightEye, PoseLandmarkType.rightEar],
  // Shoulders
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
  // Left arm
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
  [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
  // Right arm
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
  [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  // Torso
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
  // Left leg
  [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
  [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
  // Right leg
  [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
  [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
];

class PoseOverlayPainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final Size previewSize;
  final bool isFrontCamera;

  PoseOverlayPainter({
    required this.poses,
    required this.imageSize,
    required this.previewSize,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      // Draw connections
      for (final connection in _skeletonConnections) {
        final start = pose.landmarks[connection[0]];
        final end = pose.landmarks[connection[1]];
        if (start == null || end == null) continue;
        if (start.likelihood < 0.5 || end.likelihood < 0.5) continue;

        final startOffset = _translatePoint(start.x, start.y, size);
        final endOffset = _translatePoint(end.x, end.y, size);
        canvas.drawLine(startOffset, endOffset, linePaint);
      }

      // Draw dots
      for (final landmark in pose.landmarks.values) {
        if (landmark.likelihood < 0.5) continue;
        final point = _translatePoint(landmark.x, landmark.y, size);
        canvas.drawCircle(point, 5, dotPaint);
      }

    }
  }

  Offset _translatePoint(double x, double y, Size canvasSize) {
    // imageSize is now 480x640 (portrait after swap)
    // Normalize directly
    final dx = (x / imageSize.width) * canvasSize.width;
    final dy = (y / imageSize.height) * canvasSize.height;
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) =>
      oldDelegate.poses != poses;
}
