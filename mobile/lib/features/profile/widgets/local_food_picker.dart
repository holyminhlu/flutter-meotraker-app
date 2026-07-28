import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/allergy_foods.dart';
import 'package:meo_traker/core/constants/eligible_foods.dart';
import 'package:meo_traker/core/constants/food_select_category.dart';
import 'package:meo_traker/core/constants/liked_disliked_foods.dart';
import 'package:meo_traker/core/constants/local_foods.dart';
import 'package:meo_traker/core/theme/app_colors.dart';

Set<String> parseFoodSelection(String value) {
  return value
      .split(RegExp(r'[;\n|]'))
      .expand((part) {
        // Chỉ tách bằng ", " để giảm rủi ro cắt nhầm tên có dấu phẩy.
        if (part.contains(', ')) {
          return part.split(', ');
        }
        return [part];
      })
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();
}

String joinFoodSelection(Iterable<String> items) => items.join('\n');

/// Chọn nguồn thực phẩm địa phương theo từng bước.
Future<List<String>?> showLocalFoodPicker(
  BuildContext context, {
  Iterable<String> initialSelected = const [],
}) {
  return showMultiStepFoodPicker(
    context,
    categories: kLocalFoodCategories,
    initialSelected: initialSelected,
  );
}

/// Chọn món đủ điều kiện (địa phương) theo từng bước.
Future<List<String>?> showEligibleFoodPicker(
  BuildContext context, {
  Iterable<String> initialSelected = const [],
}) {
  return showMultiStepFoodPicker(
    context,
    categories: kEligibleFoodCategories,
    initialSelected: initialSelected,
  );
}

/// Chọn dị ứng / hạn chế theo từng bước.
Future<List<String>?> showAllergyFoodPicker(
  BuildContext context, {
  Iterable<String> initialSelected = const [],
}) {
  return showMultiStepFoodPicker(
    context,
    categories: kAllergyFoodCategories,
    initialSelected: initialSelected,
  );
}

/// Chọn món thích / món ghét (gộp nguồn TP địa phương + món đủ điều kiện).
Future<List<String>?> showLikedDislikedFoodPicker(
  BuildContext context, {
  Iterable<String> initialSelected = const [],
}) {
  return showMultiStepFoodPicker(
    context,
    categories: kLikedDislikedFoodCategories,
    initialSelected: initialSelected,
  );
}

Future<List<String>?> showMultiStepFoodPicker(
  BuildContext context, {
  required List<FoodSelectCategory> categories,
  Iterable<String> initialSelected = const [],
}) {
  return Navigator.of(context).push<List<String>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => MultiStepFoodPickerPage(
        categories: categories,
        initialSelected: {...initialSelected},
      ),
    ),
  );
}

class MultiStepFoodPickerPage extends StatefulWidget {
  const MultiStepFoodPickerPage({
    super.key,
    required this.categories,
    required this.initialSelected,
  });

  final List<FoodSelectCategory> categories;
  final Set<String> initialSelected;

  @override
  State<MultiStepFoodPickerPage> createState() =>
      _MultiStepFoodPickerPageState();
}

class _MultiStepFoodPickerPageState extends State<MultiStepFoodPickerPage> {
  late final Set<String> _catalog;
  late final Set<String> _selected;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _catalog = {for (final cat in widget.categories) ...cat.items};
    _selected = {...widget.initialSelected};
  }

  FoodSelectCategory get _category => widget.categories[_step];
  bool get _isLast => _step >= widget.categories.length - 1;

  List<String> get _customItems =>
      _selected.where((s) => !_catalog.contains(s)).toList()..sort();

  void _toggle(String item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
  }

  Future<void> _addCustom() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tự nhập món'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Tên món',
            hintText: 'Ví dụ: Canh chua cá lóc',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    setState(() => _selected.add(name));
  }

  List<String> _orderedSelection() {
    final ordered = <String>[];
    final seen = <String>{};
    for (final cat in widget.categories) {
      for (final item in cat.items) {
        if (_selected.contains(item) && seen.add(item)) {
          ordered.add(item);
        }
      }
    }
    for (final item in _customItems) {
      if (seen.add(item)) ordered.add(item);
    }
    return ordered;
  }

  void _finish() {
    Navigator.of(context).pop(_orderedSelection());
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.categories.length;
    final stepSelected =
        _category.items.where(_selected.contains).length;
    final customs = _customItems;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bước ${_step + 1}/$total'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (_step + 1) / total,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text(
                  _category.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn nhiều món · đã chọn $stepSelected ở bước này'
                  ' (${_selected.length} tổng)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in _category.items)
                      FilterChip(
                        label: Text(item),
                        selected: _selected.contains(item),
                        selectedColor: AppColors.primary,
                        checkmarkColor: AppColors.onPrimary,
                        onSelected: (_) => _toggle(item),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addCustom,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Tự nhập món khác'),
                ),
                if (customs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Món tự nhập',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in customs)
                        FilterChip(
                          label: Text(item),
                          selected: true,
                          selectedColor: AppColors.primary,
                          checkmarkColor: AppColors.onPrimary,
                          onSelected: (_) => _toggle(item),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Quay lại'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLast
                          ? _finish
                          : () => setState(() => _step++),
                      child: Text(_isLast ? 'Lưu lựa chọn' : 'Tiếp theo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
