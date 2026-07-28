import 'package:meo_traker/core/constants/food_select_category.dart';

/// Thực phẩm dễ gây dị ứng / kích ứng địa phương (chỉ tên).
const List<FoodSelectCategory> kAllergyFoodCategories = [
  FoodSelectCategory(
    title: 'Thủy hải sản có vỏ',
    items: [
      'Ba khía muối',
      'Cua biển Duyên Hải / Cua đồng',
      'Tôm sú, tôm đất, tép bạc',
      'Các loại ốc (ốc len, ốc mỡ, ốc bươu, ốc giác)',
      'Bề bề (Tích tôm) / Mực / Bạch tuộc',
    ],
  ),
  FoodSelectCategory(
    title: 'Đặc sản côn trùng & Động vật độc lạ',
    items: [
      'Đuông dừa / Đuông chà là',
      'Nhộng ong vò vẽ, ong ruồi',
      'Dế cơm chiên giòn / Nhái bầu',
    ],
  ),
  FoodSelectCategory(
    title: 'Thực phẩm lên men (Mắm truyền thống)',
    items: [
      'Mắm bò hóc (Prohok)',
      'Mắm cá sặc, mắm cá linh',
      'Mắm tôm chua / Mắm tép',
    ],
  ),
  FoodSelectCategory(
    title: 'Cá da trơn & Cá biển',
    items: [
      'Cá ngát, cá trê, cá chạch',
      'Cá ngừ, cá nục, cá bạc má',
    ],
  ),
  FoodSelectCategory(
    title: 'Thực vật & Nông sản dễ gây kích ứng',
    items: [
      'Bạc hà (Dọc mùng) / Khoai môn',
      'Trái khóm (Thơm/Dứa)',
      'Đậu phộng (Lạc)',
      'Củ sắn (Củ đậu)',
      'Sầu riêng / Mít',
    ],
  ),
];
