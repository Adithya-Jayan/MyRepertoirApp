import 'package:flutter/material.dart';
import 'package:repertoire/database/music_piece_repository.dart';
import 'package:repertoire/models/group.dart';
import 'package:repertoire/models/music_piece.dart';

class GroupsDisplay extends StatelessWidget {
  final MusicPiece musicPiece;

  const GroupsDisplay({super.key, required this.musicPiece});

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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Groups:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: groups.map((group) {
                return Chip(
                  label: Text(group.name),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),
          ],
        );
      },
    );
  }
}
