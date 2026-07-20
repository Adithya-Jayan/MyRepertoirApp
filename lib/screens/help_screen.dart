import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:repertoire/l10n/l10n.dart';

/// A screen that provides help information and answers to frequently asked questions.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.helpAndFaq)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            _buildCategoryHeader(
              theme,
              context.l10n.frequentlyAskedQuestions,
              Icons.question_answer_outlined,
            ),
            _buildSettingsCard([
              _buildFAQTile(
                context.l10n.howFindPieceQuestion,
                context.l10n.howFindPieceAnswer,
              ),
              _buildFAQTile(
                context.l10n.customCategoriesQuestion,
                context.l10n.customCategoriesAnswer,
              ),
              _buildFAQTile(
                context.l10n.appearanceQuestion,
                context.l10n.appearanceAnswer,
              ),
              _buildFAQTile(
                context.l10n.backupQuestion,
                context.l10n.backupAnswer,
              ),
              _buildFAQTile(
                context.l10n.reorderMediaQuestion,
                context.l10n.reorderMediaAnswer,
              ),
            ]),

            const SizedBox(height: 16),
            _buildCategoryHeader(
              theme,
              context.l10n.supportAndResources,
              Icons.support_outlined,
            ),
            _buildSettingsCard([
              ListTile(
                leading: const Icon(Icons.public, color: Colors.blue),
                title: Text(context.l10n.websiteAndDocumentation),
                subtitle: Text(
                  context.l10n.adithyajayanInMyrepertoirapp,
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () =>
                    _launchUrl('https://adithyajayan.in/MyRepertoirApp/'),
              ),
              ListTile(
                leading: const Icon(Icons.code, color: Colors.black),
                title: Text(context.l10n.sourceCodeOnGithub),
                subtitle: Text(
                  context.l10n.githubComAdithyaJayanMyrepertoirapp,
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => _launchUrl(
                  'https://github.com/Adithya-Jayan/MyRepertoirApp',
                ),
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
    return Builder(
      builder: (context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      childrenPadding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
      children: [
        Text(answer, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}
