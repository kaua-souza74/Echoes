import 'dart:convert';

import 'package:flutter/services.dart';

class MemoryEntry {
  const MemoryEntry({
    required this.id,
    required this.collectibleId,
    required this.stageId,
    required this.title,
    required this.narrative,
    required this.characterOrEvent,
    required this.concept,
    required this.explanation,
    required this.illustrationAsset,
  });

  final String id;
  final String collectibleId;
  final String stageId;
  final String title;
  final String narrative;
  final String characterOrEvent;
  final String concept;
  final String explanation;
  final String illustrationAsset;

  factory MemoryEntry.fromJson(Map<String, dynamic> json) => MemoryEntry(
    id: json['id'] as String,
    collectibleId: json['collectible_id'] as String,
    stageId: json['stage_id'] as String,
    title: json['title'] as String,
    narrative: json['narrative'] as String,
    characterOrEvent: json['character_or_event'] as String,
    concept: json['concept'] as String,
    explanation: json['explanation'] as String,
    illustrationAsset: json['illustration_asset'] as String,
  );
}

class MemoryLearningCheck {
  const MemoryLearningCheck({
    required this.id,
    required this.stageId,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.feedbackCorrect,
    required this.feedbackIncorrect,
    required this.memoryIds,
  });

  final String id;
  final String stageId;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String feedbackCorrect;
  final String feedbackIncorrect;
  final List<String> memoryIds;

  factory MemoryLearningCheck.fromJson(Map<String, dynamic> json) =>
      MemoryLearningCheck(
        id: json['id'] as String,
        stageId: json['stage_id'] as String,
        prompt: json['prompt'] as String,
        options: List<String>.unmodifiable(json['options'] as List<dynamic>),
        correctIndex: json['correct_index'] as int,
        feedbackCorrect: json['feedback_correct'] as String,
        feedbackIncorrect: json['feedback_incorrect'] as String,
        memoryIds: List<String>.unmodifiable(
          json['memory_ids'] as List<dynamic>,
        ),
      );
}

class MemoryCatalog {
  const MemoryCatalog({required this.entries, required this.learningChecks});

  final List<MemoryEntry> entries;
  final List<MemoryLearningCheck> learningChecks;

  static Future<MemoryCatalog> load({AssetBundle? bundle}) async {
    final source = await (bundle ?? rootBundle).loadString(
      'assets/narrative/memory_catalog.json',
    );
    final json = jsonDecode(source) as Map<String, dynamic>;
    return MemoryCatalog(
      entries: List<MemoryEntry>.unmodifiable(
        (json['entries'] as List<dynamic>).map(
          (entry) => MemoryEntry.fromJson(entry as Map<String, dynamic>),
        ),
      ),
      learningChecks: List<MemoryLearningCheck>.unmodifiable(
        (json['learning_checks'] as List<dynamic>).map(
          (check) =>
              MemoryLearningCheck.fromJson(check as Map<String, dynamic>),
        ),
      ),
    );
  }
}
