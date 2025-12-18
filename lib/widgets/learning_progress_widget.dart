import 'package:flutter/material.dart';
import '../models/learning_progress_config.dart';

class LearningProgressWidget extends StatelessWidget {
  final LearningProgressConfig config;
  final Function(double) onProgressChanged;
  final bool isEditable;

  const LearningProgressWidget({
    super.key,
    required this.config,
    required this.onProgressChanged,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    switch (config.type) {
      case LearningProgressType.percentage:
        return _buildPercentageBar(context);
      case LearningProgressType.count:
        return _buildCountBar(context);
      case LearningProgressType.stages:
        return _buildStagesBar(context);
    }
  }

  Widget _buildPercentageBar(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progress', style: TextStyle(fontWeight: FontWeight.w500)),
            Text('${config.current.toInt()}%'),
          ],
        ),
        Slider(
          value: config.current.clamp(0.0, 100.0),
          min: 0,
          max: 100,
          divisions: 100,
          label: '${config.current.toInt()}%',
          onChanged: isEditable ? onProgressChanged : null,
        ),
      ],
    );
  }

  Widget _buildCountBar(BuildContext context) {
    final current = config.current.toInt();
    final max = config.maxCount;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Count: $current / $max', style: const TextStyle(fontWeight: FontWeight.w500)),
            if (isEditable)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: current > 0 ? () => onProgressChanged((current - 1).toDouble()) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: current < max ? () => onProgressChanged((current + 1).toDouble()) : null,
                  ),
                ],
              ),
          ],
        ),
        LinearProgressIndicator(
          value: max > 0 ? current / max : 0,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildStagesBar(BuildContext context) {
    final currentStageIndex = config.current.toInt();
    final stages = config.stages;

    if (stages.isEmpty) return const Text('No stages defined');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentStageIndex >= 0 && currentStageIndex < stages.length)
             Padding(
               padding: const EdgeInsets.only(bottom: 8.0),
               child: Text(
                 'Current Stage: ${stages[currentStageIndex]}',
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
               ),
             ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(stages.length, (index) {
              final isCompleted = index < currentStageIndex;
              final isCurrent = index == currentStageIndex;
              
              return GestureDetector(
                onTap: isEditable ? () => onProgressChanged(index.toDouble()) : null,
                child: Container(
                  margin: const EdgeInsets.only(right: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isCurrent 
                        ? Theme.of(context).colorScheme.primary 
                        : (isCompleted ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey[400]!,
                    ),
                  ),
                  child: Text(
                    stages[index],
                    style: TextStyle(
                      color: isCurrent 
                          ? Theme.of(context).colorScheme.onPrimary 
                          : (isCompleted ? Theme.of(context).colorScheme.onSurface : Colors.grey[600]),
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
