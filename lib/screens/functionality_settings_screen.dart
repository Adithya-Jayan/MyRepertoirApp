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
    
    // Helper to save int safely
    Future<void> saveInt(String key, String value) async {
      if (value.isNotEmpty) {
        final intVal = int.tryParse(value);
        if (intVal != null) {
          await prefs.setInt(key, intVal);
        }
      }
    }

    await saveInt('greenPeriod', _greenPeriodController.text);
    await saveInt('greenToYellowTransition', _greenToYellowController.text);
    await saveInt('yellowToRedTransition', _yellowToRedController.text);
    await saveInt('redToBlackTransition', _redToBlackController.text);
    
    await prefs.setBool('show_practice_time_stats', _showPracticeTimeStats);
    await prefs.setBool('notifyNewReleases', _notifyNewReleases);
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
        body: SingleChildScrollView(
          child: Padding(
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
                  onChanged: (_) => _saveSettings(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _greenToYellowController,
                  decoration: const InputDecoration(
                    labelText: 'Green to yellow transition (days)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _saveSettings(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _yellowToRedController,
                  decoration: const InputDecoration(
                    labelText: 'Yellow to red transition (days)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _saveSettings(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _redToBlackController,
                  decoration: const InputDecoration(
                    labelText: 'Red to black transition (days)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _saveSettings(),
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
                    _saveSettings();
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
                    _saveSettings();
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
                // Save button removed
              ],
            ),
          ),
        ),
      ),
    );
  }
}