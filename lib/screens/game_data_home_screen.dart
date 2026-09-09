import 'package:flutter/material.dart';

import '../gamedata/db_schema.dart';
import '../utils/game_icons.dart';
import 'game_config_screen.dart';
import 'game_db_list_screen.dart';

class GameDataHomeScreen extends StatelessWidget {
  const GameDataHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('New Game Defaults'),
            subtitle: const Text('Starting stats for a new player save'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GameConfigScreen()),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(),
        ),
        ...gameDbSchemas.map(
          (schema) => Card(
            child: ListTile(
              leading: Icon(gameDbIcon(schema.id)),
              title: Text(schema.label),
              subtitle: Text('key: ${schema.primaryKeyField} · ${schema.fields.length} fields'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GameDbListScreen(schema: schema)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
