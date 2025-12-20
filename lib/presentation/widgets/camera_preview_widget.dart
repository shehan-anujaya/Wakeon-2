/// Camera Preview Widget
/// 
/// Displays real-time camera feed with face detection overlay.

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../../core/di/injection_container.dart';
import '../../data/datasources/camera_datasource.dart';

/// Widget for displaying camera preview
class CameraPreviewWidget extends StatefulWidget {
  final bool showLandmarks;
  
  const CameraPreviewWidget({
    super.key,
    this.showLandmarks = true,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No cameras available');
        return;
      }
      
      // Use front camera for driver monitoring
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.white54),
          ),
        ),
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        Transform.scale(
          scaleX: -1, // Mirror for front camera
          child: CameraPreview(_controller!),
        ),
        
        // Face detection overlay
        if (widget.showLandmarks)
          CustomPaint(
            painter: FaceLandmarkPainter(),
          ),
          
        // Corner guides
        _buildCornerGuides(),
      ],
    );
  }
  
  Widget _buildCornerGuides() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CustomPaint(
          painter: CornerGuidesPainter(),
        ),
      ),
    );
  }
}

/// Paints face landmarks overlay
class FaceLandmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Will be updated with actual landmark positions
    // from the detection system
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Paints corner guides for face positioning
class CornerGuidesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    const cornerLength = 40.0;
    const offset = 20.0;
    
    // Top-left corner
    canvas.drawLine(
      Offset(offset, offset),
      Offset(offset + cornerLength, offset),
      paint,
    );
    canvas.drawLine(
      Offset(offset, offset),
      Offset(offset, offset + cornerLength),
      paint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(size.width - offset, offset),
      Offset(size.width - offset - cornerLength, offset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - offset, offset),
      Offset(size.width - offset, offset + cornerLength),
      paint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(offset, size.height - offset),
      Offset(offset + cornerLength, size.height - offset),
      paint,
    );
    canvas.drawLine(
      Offset(offset, size.height - offset),
      Offset(offset, size.height - offset - cornerLength),
      paint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - offset, size.height - offset),
      Offset(size.width - offset - cornerLength, size.height - offset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - offset, size.height - offset),
      Offset(size.width - offset, size.height - offset - cornerLength),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
