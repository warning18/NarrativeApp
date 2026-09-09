import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../gamedata/game_config_schema.dart';

class GameConfigScreen extends StatefulWidget {
  const GameConfigScreen({super.key});

  @override
  State<GameConfigScreen> createState() => _GameConfigScreenState();
}

class _GameConfigScreenState extends State<GameConfigScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    for (final field in gameConfigFields) {
      _controllers[field.key] = TextEditingController();
    }
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(gameConfigPrefsKey);
    Map<String, dynamic> values;
    if (saved != null) {
      values = json.decode(saved) as Map<String, dynamic>;
    } else {
      final raw = await rootBundle.loadString(gameConfigAssetPath);
      values = json.decode(raw) as Map<String, dynamic>;
    }
    for (final field in gameConfigFields) {
      final value = values[field.key] ?? field.defaultValue;
      _controllers[field.key]!.text = value?.toString() ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final values = <String, dynamic>{};
    for (final field in gameConfigFields) {
      values[field.key] = int.tryParse(_controllers[field.key]!.text.trim()) ?? 0;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(gameConfigPrefsKey, json.encode(values));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved.')),
    );
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(gameConfigPrefsKey);
    setState(() => _loading = true);
    await _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Game Defaults'),
        actions: [
          IconButton(icon: const Icon(Icons.check), tooltip: 'Save', onPressed: _save),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to defaults',
            onPressed: _reset,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: gameConfigFields
                  .map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _controllers[field.key],
                        keyboardType: const TextInputType.numberWithOptions(signed: true),
                        decoration: InputDecoration(
                          labelText: field.label,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
