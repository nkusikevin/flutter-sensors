import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;
  bool _isPermissionDenied = false;
  File? _imageFile;
  int _selectedCameraIndex = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      setState(() {
        _isCameraInitialized = false;
      });
    } else if (state == AppLifecycleState.resumed && _isPermissionGranted) {
      _initializeCameraController(cameraController.description);
    }
  }

  Future<void> _checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      setState(() {
        _isPermissionGranted = status.isGranted;
        _isPermissionDenied = status.isPermanentlyDenied;
        _error = null;
      });

      if (_isPermissionGranted) {
        await _initializeCamera();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to check camera permission: $e';
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      setState(() {
        _isPermissionGranted = status.isGranted;
        _isPermissionDenied = status.isPermanentlyDenied;
        _error = null;
      });

      if (_isPermissionGranted) {
        await _initializeCamera();
      } else if (_isPermissionDenied) {
        setState(() {
          _error =
              'Camera permission is permanently denied. Please enable it in app settings.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to request camera permission: $e';
      });
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _error = null;
      });

      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initializeCameraController(_cameras[_selectedCameraIndex]);
      } else {
        setState(() {
          _error = 'No cameras available on this device.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error initializing camera: $e';
      });
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _initializeCameraController(
    CameraDescription cameraDescription,
  ) async {
    // Dispose previous controller
    await _controller?.dispose();

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = cameraController;

    try {
      await cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _isCameraInitialized = false;
        _error = 'Error initializing camera controller: $e';
      });
      debugPrint('Error initializing camera controller: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final XFile file = await _controller!.takePicture();
      setState(() {
        _imageFile = File(file.path);
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error taking picture: $e';
      });
      debugPrint('Error taking picture: $e');
    }
  }

  void _switchCamera() {
    if (_cameras.isEmpty) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      _isCameraInitialized = false;
      _error = null;
    });
    _initializeCameraController(_cameras[_selectedCameraIndex]);
  }

  Widget _buildPermissionScreen() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header section
          _buildHeaderCard(),
          const SizedBox(height: 32),

          // Permission card
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Camera Permission Required',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isPermissionDenied
                          ? 'Camera permission is permanently denied. Please enable it in app settings to use the camera.'
                          : 'This app needs access to your camera to take photos and videos.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: _isPermissionDenied
                          ? ElevatedButton.icon(
                              onPressed: _openAppSettings,
                              icon: const Icon(Icons.settings, size: 18),
                              label: const Text('Open Settings'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: _requestCameraPermission,
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Grant Permission'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Camera',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capture photos with your device camera',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: _buildHeaderCard(),
        ),

        // Camera preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _isCameraInitialized
                  ? Stack(
                      children: [
                        // Camera preview
                        CameraPreview(_controller!),

                        // Camera controls overlay
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: _buildCameraControls(),
                        ),
                      ],
                    )
                  : _buildLoadingOrError(),
            ),
          ),
        ),

        // Image preview
        if (_imageFile != null) _buildImagePreview(),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCameraControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_cameras.length > 1)
            _CameraControlButton(
              icon: Icons.flip_camera_ios,
              onPressed: _switchCamera,
              heroTag: 'switchCamera',
            ),
          _CameraControlButton(
            icon: Icons.camera,
            onPressed: _takePicture,
            heroTag: 'takePicture',
            isPrimary: true,
          ),
          const SizedBox(width: 56), // Balance spacing when no switch button
        ],
      ),
    );
  }

  Widget _buildLoadingOrError() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: _error != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _initializeCamera,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 120,
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Row(
          children: [
            Expanded(
              child: Image.file(
                _imageFile!,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              width: 60,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _imageFile = null;
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          if (_isPermissionGranted && _cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body:
          !_isPermissionGranted ? _buildPermissionScreen() : _buildCameraView(),
    );
  }
}

class _CameraControlButton extends StatelessWidget {
  const _CameraControlButton({
    required this.icon,
    required this.onPressed,
    required this.heroTag,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String heroTag;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: isPrimary ? const Color(0xFF3B82F6) : Colors.white,
      foregroundColor: isPrimary ? Colors.white : const Color(0xFF64748B),
      elevation: isPrimary ? 4 : 2,
      child: Icon(icon, size: isPrimary ? 28 : 24),
    );
  }
}
