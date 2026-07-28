/// Nhóm lựa chọn thực phẩm theo bước (chỉ tên món).
class FoodSelectCategory {
  const FoodSelectCategory({required this.title, required this.items});

  final String title;
  final List<String> items;
}
