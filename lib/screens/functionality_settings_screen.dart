import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repertoire/services/update_service.dart';


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
  bool _showPracticeTimeStats = false;
  bool _notifyNewReleases = false;

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
      _showPracticeTimeStats = prefs.getBool('show_practice_time_stats') ?? false;
      _notifyNewReleases = prefs.getBool('notifyNewReleases') ?? false;
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
    await prefs.setBool('show_practice_time_stats', _showPracticeTimeStats);
    await prefs.setBool('notifyNewReleases', _notifyNewReleases);
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
              const Divider(),
              SwitchListTile(
                title: const Text('Show Practice Time Statistics'),
                subtitle: const Text('Display duration and time-based statistics in practice logs'),
                value: _showPracticeTimeStats,
                onChanged: (bool value) {
                  setState(() {
                    _showPracticeTimeStats = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Notify New Releases'),
                subtitle: const Text('Show a popup when a new version is available on GitHub.'),
                value: _notifyNewReleases,
                onChanged: (bool value) {
                  setState(() {
                    _notifyNewReleases = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.update),
                  label: const Text('Check for Updates Now'),
                  onPressed: () {
                    UpdateService().checkForUpdates(context, manual: true);
                  },
                ),
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
