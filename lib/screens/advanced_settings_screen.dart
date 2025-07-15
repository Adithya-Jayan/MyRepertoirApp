import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_logger.dart';
import '../utils/theme_notifier.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  bool _debugLogsEnabled = false;

  @override
  void initState() {
    super.initState();
    _debugLogsEnabled = AppLogger.debugLogsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Debug Logs'),
            value: _debugLogsEnabled,
            onChanged: (bool value) {
              setState(() {
                _debugLogsEnabled = value;
              });
              AppLogger.setDebugLogsEnabled(value);
            },
          ),
        ],
      ),
    );
  }
}
