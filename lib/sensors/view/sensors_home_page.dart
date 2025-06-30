import 'package:flutter/material.dart';
import 'package:my_app/sensors/sensors.dart';

class SensorsHomePage extends StatelessWidget {
  const SensorsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Sensors Demo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SensorCard(
            title: 'GPS Location',
            icon: Icons.location_on,
            description: 'Access device location data',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const GpsPage(),
              ),
            ),
          ),
          _SensorCard(
            title: 'Camera',
            icon: Icons.camera_alt,
            description: 'Access device camera',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const CameraPage(),
              ),
            ),
          ),
          _SensorCard(
            title: 'Microphone',
            icon: Icons.mic,
            description: 'Record audio using the microphone',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const MicrophonePage(),
              ),
            ),
          ),
          _SensorCard(
            title: 'Vibration',
            icon: Icons.vibration,
            description: 'Control device vibration',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const VibrationPage(),
              ),
            ),
          ),
          _SensorCard(
            title: 'Bluetooth',
            icon: Icons.bluetooth,
            description: 'Scan and connect to Bluetooth devices',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const BluetoothPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                radius: 28,
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
