import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class MicrophonePage extends StatefulWidget {
  const MicrophonePage({super.key});

  @override
  State<MicrophonePage> createState() => _MicrophonePageState();
}

class _MicrophonePageState extends State<MicrophonePage> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPermissionGranted = false;
  String? _recordedFilePath;
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _checkMicrophonePermission();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _checkMicrophonePermission() async {
    // Check both permission systems to ensure compatibility
    final permissionStatus = await Permission.microphone.status;
    final hasRecorderPermission = await _audioRecorder.hasPermission();

    setState(() {
      _isPermissionGranted =
          permissionStatus.isGranted && hasRecorderPermission;
    });

    // If permission_handler says granted but recorder doesn't, try requesting again
    if (permissionStatus.isGranted && !hasRecorderPermission) {
      await _requestMicrophonePermission();
    }
  }

  Future<void> _requestMicrophonePermission() async {
    try {
      // Request permission using permission_handler first
      final status = await Permission.microphone.request();

      // Then check with the audio recorder
      final hasRecorderPermission = await _audioRecorder.hasPermission();

      setState(() {
        _isPermissionGranted = status.isGranted && hasRecorderPermission;
      });

      // If still no permission, show helpful message
      if (!_isPermissionGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Microphone permission is required to record audio. Please enable it in app settings.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      // Double-check permissions before starting
      if (!_isPermissionGranted || !await _audioRecorder.hasPermission()) {
        await _checkMicrophonePermission();
        if (!_isPermissionGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Microphone permission is required to start recording.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/audio_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      final audioConfig = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(audioConfig, path: filePath);

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = 0;
        _recordedFilePath = filePath;
      });

      _startTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();

    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordedFilePath = path;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioRecorder.pause();
      setState(() {
        _isPaused = true;
      });
      _recordingTimer?.cancel();
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _audioRecorder.resume();
      setState(() {
        _isPaused = false;
      });
      _startTimer();
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    }
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Microphone'),
      ),
      body: _isPermissionGranted
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Recording status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Recording Status',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isRecording
                                    ? (_isPaused ? Icons.pause : Icons.mic)
                                    : Icons.mic_off,
                                color: _isRecording
                                    ? (_isPaused ? Colors.orange : Colors.red)
                                    : Colors.grey,
                                size: 48,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                _isRecording
                                    ? (_isPaused ? 'Paused' : 'Recording...')
                                    : 'Not Recording',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                          if (_isRecording || _recordedFilePath != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _isRecording
                                    ? 'Duration: ${_formatDuration(_recordingDuration)}'
                                    : 'Recording saved',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Recording controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!_isRecording)
                        FloatingActionButton.extended(
                          onPressed: _startRecording,
                          icon: const Icon(Icons.mic),
                          label: const Text('Start'),
                          backgroundColor: Colors.green,
                        )
                      else ...[
                        FloatingActionButton(
                          onPressed: _stopRecording,
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.stop),
                        ),
                        FloatingActionButton(
                          onPressed:
                              _isPaused ? _resumeRecording : _pauseRecording,
                          backgroundColor:
                              _isPaused ? Colors.green : Colors.orange,
                          child:
                              Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Recording file info
                  if (_recordedFilePath != null && !_isRecording)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recording Info',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'File: ${_recordedFilePath!.split('/').last}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<FileStat>(
                              future: File(_recordedFilePath!).stat(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final fileSizeKB = snapshot.data!.size / 1024;
                                  return Text(
                                    'Size: ${fileSizeKB.toStringAsFixed(2)} KB',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  );
                                }
                                return const Text('Calculating size...');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mic_off,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Microphone Permission Required',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This app needs access to your microphone to record audio. Please grant permission to continue.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _requestMicrophonePermission,
                          icon: const Icon(Icons.mic),
                          label: const Text('Grant Permission'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await openAppSettings();
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('App Settings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _checkMicrophonePermission,
                      child: const Text('Refresh Permission Status'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
