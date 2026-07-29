import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:meo_traker/core/meal/meal_schedule.dart';
import 'package:meo_traker/core/meal/nutrition_advice.dart';
import 'package:meo_traker/core/storage/app_storage.dart';
import 'package:meo_traker/core/time/app_clock.dart';

class MealFoodLog {
  const MealFoodLog({
    required this.period,
    required this.foodItems,
    required this.advice,
    required this.recordedAtIso,
    this.description,
  });

  final MealPeriod period;
  final List<String> foodItems;
  final String advice;
  final String recordedAtIso;
  final String? description;

  Map<String, dynamic> toJson() => {
        'period': period.name,
        'foodItems': foodItems,
        'advice': advice,
        'recordedAtIso': recordedAtIso,
        'description': description,
      };

  factory MealFoodLog.fromJson(Map<String, dynamic> json) {
    final periodName = json['period']?.toString() ?? 'breakfast';
    final period = MealPeriod.values.firstWhere(
      (e) => e.name == periodName,
      orElse: () => MealPeriod.breakfast,
    );
    return MealFoodLog(
      period: period,
      foodItems: ((json['foodItems'] as List?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      advice: json['advice']?.toString() ?? '',
      recordedAtIso: json['recordedAtIso']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

/// Lưu lịch sử món AI nhận diện theo ngày (cho Chuyên gia dinh dưỡng).
class MealLogService extends ChangeNotifier {
  MealLogService._();
  static final MealLogService instance = MealLogService._();

  String _dateKey = '';
  final Map<MealPeriod, MealFoodLog> _logs = {};

  static const _key = 'meal_food_logs.json';

  String _todayKey([DateTime? now]) {
    final d = now ?? AppClock.instance.now();
    return AppClock.instance.todayKey(d);
  }

  MealFoodLog? logFor(MealPeriod period) {
    _ensureToday();
    return _logs[period];
  }

  List<MealFoodLog> get todayLogs {
    _ensureToday();
    return MealPeriod.values
        .map((p) => _logs[p])
        .whereType<MealFoodLog>()
        .toList();
  }

  Future<void> load() async {
    try {
      final text = await AppStorage.readString(_key);
      if (text == null) {
        _ensureToday();
        notifyListeners();
        return;
      }
      final raw = jsonDecode(text) as Map<String, dynamic>;
      _dateKey = raw['dateKey']?.toString() ?? '';
      final today = _todayKey();
      _logs.clear();
      if (_dateKey == today) {
        final map = raw['logs'] as Map<String, dynamic>? ?? {};
        for (final e in map.entries) {
          final period = MealPeriod.values.firstWhere(
            (p) => p.name == e.key,
            orElse: () => MealPeriod.breakfast,
          );
          _logs[period] =
              MealFoodLog.fromJson(Map<String, dynamic>.from(e.value as Map));
        }
      } else {
        _dateKey = today;
        await _persist();
      }
    } catch (_) {
      _ensureToday();
    }
    notifyListeners();
  }

  void _ensureToday() {
    final today = _todayKey();
    if (_dateKey != today) {
      _dateKey = today;
      _logs.clear();
    }
  }

  Future<void> saveRecognition({
    required MealPeriod period,
    required List<String> foodItems,
    String? description,
  }) async {
    _ensureToday();
    final items = foodItems
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.isEmpty && (description == null || description.trim().isEmpty)) {
      return;
    }

    final advice = buildNutritionAdvice(
      period: period,
      foodItems: items,
      description: description,
    );
    _logs[period] = MealFoodLog(
      period: period,
      foodItems: items,
      description: description,
      advice: advice,
      recordedAtIso: AppClock.instance.now().toIso8601String(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await AppStorage.writeString(
      _key,
      jsonEncode({
        'dateKey': _dateKey,
        'logs': {
          for (final e in _logs.entries) e.key.name: e.value.toJson(),
        },
      }),
    );
  }
}
