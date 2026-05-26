import 'package:flutter/material.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/models/group.dart';
import 'package:repertoire/models/music_piece.dart';

class GroupsDisplay extends StatelessWidget {
  final MusicPiece musicPiece;
  final bool showTitle;

  const GroupsDisplay({
    super.key, 
    required this.musicPiece,
    this.showTitle = true,
  });

  Future<List<Group>> _loadGroups() async {
    final repository = MusicPieceRepository();
    final allGroups = await repository.getGroups();
    return allGroups.where((g) => musicPiece.groupIds.contains(g.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (musicPiece.groupIds.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<Group>>(
      future: _loadGroups(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final groups = snapshot.data!;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                'Groups',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
            ],
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: groups.map((group) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      group.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
