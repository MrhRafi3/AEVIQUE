import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../core/models/edit_state.dart';

/// A custom user-defined preset storing non-destructive EditState adjustments.
@immutable
class CustomPreset {
  final String id;
  final String name;
  final String description;
  final EditState state;
  final DateTime createdAt;

  const CustomPreset({
    required this.id,
    required this.name,
    this.description = 'Custom User Preset',
    required this.state,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'state': state.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory CustomPreset.fromJson(Map<String, dynamic> json) => CustomPreset(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? 'Custom User Preset',
    state: EditState.fromJson(Map<String, dynamic>.from(json['state'] as Map)),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );

  CustomPreset copyWith({
    String? id,
    String? name,
    String? description,
    EditState? state,
    DateTime? createdAt,
  }) => CustomPreset(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    state: state ?? this.state,
    createdAt: createdAt ?? this.createdAt,
  );
}

/// Repository for managing persistent custom user presets.
class PresetRepository {
  static final List<CustomPreset> _inMemoryCache = [];
  static bool _initialized = false;

  /// Loads all custom presets from disk.
  static Future<List<CustomPreset>> getCustomPresets() async {
    if (_initialized) return List.unmodifiable(_inMemoryCache);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/lumafix_custom_presets.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = jsonDecode(content) as List<dynamic>;
        _inMemoryCache.clear();
        for (final item in list) {
          try {
            _inMemoryCache.add(
              CustomPreset.fromJson(Map<String, dynamic>.from(item as Map)),
            );
          } catch (e) {
            if (kDebugMode) debugPrint('[PresetRepository] Parse error: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PresetRepository] Load error: $e');
    }

    _initialized = true;
    return List.unmodifiable(_inMemoryCache);
  }

  /// Saves a new custom preset or updates an existing one.
  static Future<void> savePreset(CustomPreset preset) async {
    final idx = _inMemoryCache.indexWhere((p) => p.id == preset.id);
    if (idx >= 0) {
      _inMemoryCache[idx] = preset;
    } else {
      _inMemoryCache.add(preset);
    }
    await _persist();
  }

  /// Deletes a custom preset by ID.
  static Future<void> deletePreset(String id) async {
    _inMemoryCache.removeWhere((p) => p.id == id);
    await _persist();
  }

  /// Renames a custom preset.
  static Future<void> renamePreset(String id, String newName) async {
    final idx = _inMemoryCache.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      _inMemoryCache[idx] = _inMemoryCache[idx].copyWith(name: newName);
      await _persist();
    }
  }

  static Future<void> _persist() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/lumafix_custom_presets.json');
      final jsonStr = jsonEncode(_inMemoryCache.map((p) => p.toJson()).toList());
      await file.writeAsString(jsonStr, flush: true);
    } catch (e) {
      if (kDebugMode) debugPrint('[PresetRepository] Persist error: $e');
    }
  }
}
