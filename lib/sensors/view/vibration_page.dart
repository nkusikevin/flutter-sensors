import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class VibrationPage extends StatefulWidget {
  const VibrationPage({super.key});

  @override
  State<VibrationPage> createState() => _VibrationPageState();
}

class _VibrationPageState extends State<VibrationPage> {
  bool _hasVibrator = false;
  bool _hasAmplitudeControl = false;
  bool _hasCustomDurationSupport = false;

  @override
  void initState() {
    super.initState();
    _checkVibrationCapabilities();
  }

  Future<void> _checkVibrationCapabilities() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    final hasAmplitudeControl = await Vibration.hasAmplitudeControl() ?? false;
    final hasCustomDurationSupport =
        await Vibration.hasCustomVibrationsSupport() ?? false;

    setState(() {
      _hasVibrator = hasVibrator;
      _hasAmplitudeControl = hasAmplitudeControl;
      _hasCustomDurationSupport = hasCustomDurationSupport;
    });
  }

  void _singleVibration() {
    if (_hasVibrator) {
      Vibration.vibrate();
    }
  }

  void _customDurationVibration(int duration) {
    if (_hasVibrator) {
      Vibration.vibrate(duration: duration);
    }
  }

  void _patternVibration() {
    if (_hasVibrator) {
      // Pattern: wait 500ms, vibrate 1000ms, wait 500ms, vibrate 2000ms
      Vibration.vibrate(pattern: [500, 1000, 500, 2000]);
    }
  }

  void _amplitudeVibration() {
    if (_hasVibrator && _hasAmplitudeControl) {
      // Pattern with different amplitudes
      Vibration.vibrate(
        pattern: [500, 1000, 500, 2000],
        intensities: [128, 255, 64, 255],
      );
    }
  }

  void _cancelVibration() {
    Vibration.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Capabilities',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _CapabilityRow(
                      capability: 'Has Vibrator',
                      isSupported: _hasVibrator,
                    ),
                    const SizedBox(height: 8),
                    _CapabilityRow(
                      capability: 'Has Amplitude Control',
                      isSupported: _hasAmplitudeControl,
                    ),
                    const SizedBox(height: 8),
                    _CapabilityRow(
                      capability: 'Has Custom Duration Support',
                      isSupported: _hasCustomDurationSupport,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Vibration Controls',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _VibrationButton(
                    title: 'Single Vibration',
                    icon: Icons.vibration,
                    onPressed: _hasVibrator ? _singleVibration : null,
                  ),
                  _VibrationButton(
                    title: 'Short Vibration (200ms)',
                    icon: Icons.vibration,
                    onPressed: _hasVibrator
                        ? () => _customDurationVibration(200)
                        : null,
                  ),
                  _VibrationButton(
                    title: 'Long Vibration (1000ms)',
                    icon: Icons.vibration,
                    onPressed: _hasVibrator
                        ? () => _customDurationVibration(1000)
                        : null,
                  ),
                  _VibrationButton(
                    title: 'Pattern Vibration',
                    icon: Icons.waves,
                    onPressed: _hasVibrator ? _patternVibration : null,
                  ),
                  _VibrationButton(
                    title: 'Amplitude Vibration',
                    icon: Icons.graphic_eq,
                    onPressed: _hasVibrator && _hasAmplitudeControl
                        ? _amplitudeVibration
                        : null,
                  ),
                  _VibrationButton(
                    title: 'Cancel Vibration',
                    icon: Icons.cancel,
                    onPressed: _hasVibrator ? _cancelVibration : null,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.capability,
    required this.isSupported,
  });

  final String capability;
  final bool isSupported;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isSupported ? Icons.check_circle : Icons.cancel,
          color: isSupported ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          capability,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _VibrationButton extends StatelessWidget {
  const _VibrationButton({
    required this.title,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color != null
          ? color!.withOpacity(onPressed == null ? 0.3 : 0.8)
          : Theme.of(context).colorScheme.primaryContainer.withOpacity(
                onPressed == null ? 0.3 : 1,
              ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: onPressed == null
                    ? Colors.grey
                    : color != null
                        ? Colors.white
                        : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: onPressed == null
                      ? Colors.grey
                      : color != null
                          ? Colors.white
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
