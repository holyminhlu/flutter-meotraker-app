import 'package:meo_traker/core/meal/meal_schedule.dart';

/// Lời khuyên sau bữa dựa trên món AI nhận diện (mức chung, tăng cân lành mạnh).
String buildNutritionAdvice({
  required MealPeriod period,
  required List<String> foodItems,
  String? description,
}) {
  final joined = '${foodItems.join(' ')} ${description ?? ''}'.toLowerCase();
  final tips = <String>[];

  final hasCarb = _any(joined, const [
    'cơm',
    'bánh mì',
    'mì',
    'phở',
    'bún',
    'cháo',
    'khoai',
    'ngũ cốc',
    'xôi',
  ]);
  final hasProtein = _any(joined, const [
    'thịt',
    'gà',
    'cá',
    'trứng',
    'tôm',
    'bò',
    'heo',
    'đậu',
    'sữa',
    'đậu hũ',
    'đậu phụ',
  ]);
  final hasVeg = _any(joined, const [
    'rau',
    'cải',
    'salad',
    'cà chua',
    'dưa',
    'bông cải',
    'cà rốt',
  ]);
  final hasFruit = _any(joined, const [
    'trái cây',
    'chuối',
    'táo',
    'cam',
    'đu đủ',
    'xoài',
    'bơ',
  ]);
  final hasDairy = _any(joined, const ['sữa', 'sữa chua', 'phô mai', 'yogurt']);
  final hasSoup = _any(joined, const ['canh', 'súp', 'cháo']);

  if (!hasProtein) {
    tips.add(
      'Bữa này hơi thiếu đạm — sau 1–2 giờ có thể bổ sung trứng luộc hoặc sữa đậu nành.',
    );
  } else {
    tips.add('Có nguồn đạm tốt — giúp tăng cơ. Uống thêm nước ấm sau ăn 20–30 phút.');
  }

  if (!hasCarb && period != MealPeriod.dinner) {
    tips.add(
      'Ít tinh bột — bữa sau thêm cơm/bánh mì để đủ năng lượng tăng cân.',
    );
  } else if (hasCarb) {
    tips.add(
      'Đã có tinh bột — đi bộ nhẹ 5–10 phút sau ăn để tiêu hóa tốt hơn.',
    );
  }

  if (!hasVeg && !hasFruit) {
    tips.add(
      'Thiếu rau/trái cây — bổ sung chuối hoặc ít rau xào trong bữa kế tiếp.',
    );
  } else if (hasVeg || hasFruit) {
    tips.add('Có rau/trái cây — ổn cho vi chất. Giữ nhịp này nhé.');
  }

  if (hasSoup) {
    tips.add('Có canh/súp — tốt cho tiêu hóa. Tránh nằm ngay sau khi ăn no.');
  }

  if (!hasDairy && period == MealPeriod.breakfast) {
    tips.add('Buổi sáng có thể thêm ly sữa ấm để tăng calo nhẹ nhàng.');
  }

  if (period == MealPeriod.dinner) {
    tips.add(
      'Sau bữa chiều/tối: tránh ăn vặt muộn, ngủ đúng giờ để tăng cân lành mạnh.',
    );
  }

  // Giữ 2–3 lời khuyên ngắn gọn.
  return tips.take(3).join(' ');
}

bool _any(String text, List<String> keys) =>
    keys.any((k) => text.contains(k));
