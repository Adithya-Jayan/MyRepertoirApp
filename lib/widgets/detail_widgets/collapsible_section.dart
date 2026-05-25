import 'package:flutter/material.dart';
import '../../services/section_state_service.dart';

class CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final String persistenceKey;
  final bool initiallyExpanded;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    required this.persistenceKey,
    this.initiallyExpanded = true,
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
    // This provides better visual separation than just using primaryColor with alpha
    final headerColor = colorScheme.secondaryContainer;
    final onHeaderColor = colorScheme.onSecondaryContainer;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
        // Explicitly set colors to avoid theme inheritance issues and fix the 'invisible title' bug
        textColor: onHeaderColor,
        collapsedTextColor: onHeaderColor,
        iconColor: onHeaderColor,
        collapsedIconColor: onHeaderColor,
        // Remove default dividers from ExpansionTile to maintain clean card look
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        onExpansionChanged: (expanded) {
          _stateService.setExpanded(widget.persistenceKey, expanded);
        },
        children: [
          Container(
            color: theme.scaffoldBackgroundColor, // Revert to normal background for content
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
