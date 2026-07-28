import 'package:meo_traker/core/constants/eligible_foods.dart';
import 'package:meo_traker/core/constants/food_select_category.dart';
import 'package:meo_traker/core/constants/local_foods.dart';

/// Gộp nguồn thực phẩm địa phương + món đủ điều kiện cho Món thích / Món ghét.
final List<FoodSelectCategory> kLikedDislikedFoodCategories = [
  ...kLocalFoodCategories,
  ...kEligibleFoodCategories,
];
