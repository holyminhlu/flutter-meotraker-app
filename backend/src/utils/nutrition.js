const ACTIVITY_FACTORS = {
  sedentary: 1.2,
  light: 1.375,
  moderate: 1.55,
  active: 1.725,
  very_active: 1.9,
};

function round1(n) {
  return Math.round(n * 10) / 10;
}

function round0(n) {
  return Math.round(n);
}

/**
 * Mifflin-St Jeor BMR + TDEE + calorie target for weight goal.
 * Default surplus +400 kcal/day for gain_weight.
 */
function calculateMetrics({
  heightCm,
  weightKg,
  targetWeightKg,
  age,
  sex,
  activityLevel,
}) {
  const heightM = heightCm / 100;
  const bmi = weightKg / (heightM * heightM);

  const sexOffset = sex === 'female' ? -161 : 5; // male/other use male formula
  const bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + sexOffset;

  const factor = ACTIVITY_FACTORS[activityLevel] || ACTIVITY_FACTORS.moderate;
  const tdee = bmr * factor;

  let goalType = 'maintain';
  let surplus = 0;
  if (targetWeightKg > weightKg + 0.5) {
    goalType = 'gain_weight';
    const gap = targetWeightKg - weightKg;
    surplus = gap >= 5 ? 500 : 400;
  } else if (targetWeightKg < weightKg - 0.5) {
    goalType = 'lose_weight';
    surplus = -400;
  }

  const calorieTarget = tdee + surplus;

  return {
    bmi: round1(bmi),
    bmr: round0(bmr),
    tdee: round0(tdee),
    calorieTarget: round0(calorieTarget),
    goalType,
    surplusKcal: surplus,
  };
}

function bmiCategory(bmi) {
  if (bmi < 18.5) return 'Thiếu cân';
  if (bmi < 23) return 'Bình thường';
  if (bmi < 25) return 'Thừa cân';
  return 'Béo phì';
}

module.exports = {
  ACTIVITY_FACTORS,
  calculateMetrics,
  bmiCategory,
};
