import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A screen that provides help information and answers to frequently asked questions.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            _buildCategoryHeader(theme, 'Frequently Asked Questions', Icons.question_answer_outlined),
            _buildSettingsCard([
              _buildFAQTile('How do I quickly find a specific music piece?', 
                'Use the search bar at the top of the main library screen. You can search by title, artist/composer, or tags.'),
              _buildFAQTile('Can I organize my music into custom categories?', 
                'Yes, navigate to Settings > Groups to create and manage custom groups for your pieces.'),
              _buildFAQTile('How do I change the app\'s appearance?', 
                'Go to Settings > Personalization to switch themes, accent colors, and layout options.'),
              _buildFAQTile('Is there a way to backup my data?', 
                'Yes, visit Settings > Backup & Restore to perform manual or automatic local backups.'),
              _buildFAQTile('How can I reorder media or tags?', 
                'On the Edit Piece screen, use the drag handles on the left of media items to reorder them.'),
            ]),

            const SizedBox(height: 16),
            _buildCategoryHeader(theme, 'Support & Resources', Icons.support_outlined),
            _buildSettingsCard([
              ListTile(
                leading: const Icon(Icons.public, color: Colors.blue),
                title: const Text('Website & Documentation'),
                subtitle: const Text('adithyajayan.in/MyRepertoirApp/', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => _launchUrl('https://adithyajayan.in/MyRepertoirApp/'),
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Colors.black),
                title: const Text('Source Code on GitHub'),
                subtitle: const Text('github.com/Adithya-Jayan/MyRepertoirApp', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => _launchUrl('https://github.com/Adithya-Jayan/MyRepertoirApp'),
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _buildCategoryHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Builder(builder: (context) => Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
      child: Column(children: children),
    ));
  }

  Widget _buildFAQTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      childrenPadding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
      children: [
        Text(answer, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}