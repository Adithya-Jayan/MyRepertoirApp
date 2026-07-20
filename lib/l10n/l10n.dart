import 'package:flutter/widgets.dart';
import 'package:repertoire/models/group.dart';
import 'package:repertoire/models/learning_progress_config.dart';
import 'package:repertoire/models/media_type.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension LocalizedGroupX on Group {
  String localizedName(AppLocalizations l10n) {
    return switch (id) {
      'all_group' => l10n.all,
      'ungrouped_group' => l10n.ungrouped,
      _ => name,
    };
  }
}

extension LocalizedLearningProgressTypeX on LearningProgressType {
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      LearningProgressType.percentage => l10n.percentage,
      LearningProgressType.count => l10n.count,
      LearningProgressType.stages => l10n.stagesLabel,
    };
  }
}

extension LocalizedMediaTypeX on MediaType {
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      MediaType.markdown => l10n.markdownText,
      MediaType.pdf => l10n.pdf,
      MediaType.image => l10n.image,
      MediaType.audio => l10n.audio,
      MediaType.mediaLink => l10n.link,
      MediaType.thumbnails => l10n.thumbnail,
      MediaType.learningProgress => l10n.learningProgress,
      MediaType.localVideo => l10n.localVideo,
      MediaType.midi => l10n.midi,
    };
  }
}
