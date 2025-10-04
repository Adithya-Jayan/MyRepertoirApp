import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class FunctionalitySettingsScreen extends StatefulWidget {
  const FunctionalitySettingsScreen({super.key});

  @override
  State<FunctionalitySettingsScreen> createState() =>
      _FunctionalitySettingsScreenState();
}

class _FunctionalitySettingsScreenState
    extends State<FunctionalitySettingsScreen> {
  final TextEditingController _greenPeriodController =
      TextEditingController();
  final TextEditingController _greenToYellowController =
      TextEditingController();
  final TextEditingController _yellowToRedController =
      TextEditingController();
  final TextEditingController _redToBlackController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _greenPeriodController.text =
          (prefs.getInt('greenPeriod') ?? 7).toString();
      _greenToYellowController.text =
          (prefs.getInt('greenToYellowTransition') ?? 7).toString();
      _yellowToRedController.text =
          (prefs.getInt('yellowToRedTransition') ?? 16).toString();
      _redToBlackController.text =
          (prefs.getInt('redToBlackTransition') ?? 30).toString();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'greenPeriod', int.parse(_greenPeriodController.text));
    await prefs.setInt(
        'greenToYellowTransition', int.parse(_greenToYellowController.text));
    await prefs.setInt(
        'yellowToRedTransition', int.parse(_yellowToRedController.text));
    await prefs.setInt(
        'redToBlackTransition', int.parse(_redToBlackController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Functionality'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Practice Tracking Dot',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _greenPeriodController,
                decoration: const InputDecoration(
                  labelText: 'Days to remain green',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _greenToYellowController,
                decoration: const InputDecoration(
                  labelText: 'Green to yellow transition (days)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _yellowToRedController,
                decoration: const InputDecoration(
                  labelText: 'Yellow to red transition (days)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _redToBlackController,
                decoration: const InputDecoration(
                  labelText: 'Red to black transition (days)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
