class NutritionMetrics {
  const NutritionMetrics({
    required this.bmi,
    required this.bmiLabel,
    required this.bmr,
    required this.tdee,
    required this.calorieTarget,
    required this.goalType,
    required this.surplusKcal,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.age,
    required this.sex,
    required this.activityLevel,
  });

  final double bmi;
  final String bmiLabel;
  final double bmr;
  final double tdee;
  final double calorieTarget;
  final String goalType;
  final double surplusKcal;
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final int age;
  final String sex;
  final String activityLevel;

  factory NutritionMetrics.fromJson(Map<String, dynamic> json) {
    return NutritionMetrics(
      bmi: (json['bmi'] as num).toDouble(),
      bmiLabel: (json['bmiLabel'] as String?) ?? '',
      bmr: (json['bmr'] as num).toDouble(),
      tdee: (json['tdee'] as num).toDouble(),
      calorieTarget: (json['calorieTarget'] as num).toDouble(),
      goalType: (json['goalType'] as String?) ?? 'gain_weight',
      surplusKcal: (json['surplusKcal'] as num?)?.toDouble() ?? 0,
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      targetWeightKg: (json['targetWeightKg'] as num).toDouble(),
      age: (json['age'] as num).toInt(),
      sex: json['sex'] as String,
      activityLevel: json['activityLevel'] as String,
    );
  }
}
