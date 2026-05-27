import 'package:flutter/material.dart';
import '../../services/section_state_service.dart';

class CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final String persistenceKey;
  final bool initiallyExpanded;
  final Widget? trailing;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    required this.persistenceKey,
    this.initiallyExpanded = true,
    this.trailing,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late final SectionStateService _stateService;
  final ExpansibleController _controller = ExpansibleController();

  @override
  void initState() {
    super.initState();
    _stateService = SectionStateService();
    _stateService.addListener(_onStateServiceChanged);
  }

  @override
  void dispose() {
    _stateService.removeListener(_onStateServiceChanged);
    super.dispose();
  }

  void _onStateServiceChanged() {
    final shouldBeExpanded = _stateService.isExpanded(
      widget.persistenceKey,
      defaultValue: widget.initiallyExpanded,
    );
    if (shouldBeExpanded != _controller.isExpanded) {
      if (shouldBeExpanded) {
        _controller.expand();
      } else {
        _controller.collapse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use secondaryContainer for a subtle but distinct header background
    final headerColor = colorScheme.secondaryContainer.withValues(alpha: 0.5);
    final onHeaderColor = colorScheme.onSecondaryContainer;

    IconData getSectionIcon(String title) {
      final t = title.toLowerCase();
      if (t.contains('group')) return Icons.folder_outlined;
      if (t.contains('practice')) return Icons.history_rounded;
      if (t.contains('tag')) return Icons.label_outline_rounded;
      if (t.contains('media')) return Icons.description_outlined;
      return Icons.segment_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        controller: _controller,
        initiallyExpanded: _stateService.isExpanded(
          widget.persistenceKey,
          defaultValue: widget.initiallyExpanded,
        ),
        collapsedBackgroundColor: headerColor,
        backgroundColor: headerColor,
        textColor: onHeaderColor,
        collapsedTextColor: onHeaderColor,
        iconColor: onHeaderColor,
        collapsedIconColor: onHeaderColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        leading: Icon(getSectionIcon(widget.title), size: 20),
        title: Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        trailing: widget.trailing != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.trailing!,
                  const Icon(Icons.expand_more),
                ],
              )
            : null,
        onExpansionChanged: (expanded) {
          _stateService.setExpanded(widget.persistenceKey, expanded);
        },
        children: [
          Container(
            color: theme.scaffoldBackgroundColor,
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
