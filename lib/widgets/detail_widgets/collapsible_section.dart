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
    final headerColor = theme.primaryColor.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          controller: _controller,
          initiallyExpanded: _stateService.isExpanded(
            widget.persistenceKey,
            defaultValue: widget.initiallyExpanded,
          ),
          collapsedBackgroundColor: headerColor,
          backgroundColor: headerColor,
          title: Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
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
      ),
    );
  }
}
