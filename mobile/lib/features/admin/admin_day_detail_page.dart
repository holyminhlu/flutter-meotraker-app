import 'package:flutter/material.dart';
import 'package:meo_traker/core/theme/app_colors.dart';
import 'package:meo_traker/data/services/admin_api.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:meo_traker/features/admin/admin_meal_photo_detail_page.dart';

/// Chi tiết một ngày: ảnh nén user đã upload + món AI nhận diện.
class AdminDayDetailPage extends StatefulWidget {
  const AdminDayDetailPage({
    super.key,
    required this.userId,
    required this.displayName,
    required this.initialDate,
  });

  final String userId;
  final String displayName;
  final DateTime initialDate;

  @override
  State<AdminDayDetailPage> createState() => _AdminDayDetailPageState();
}

class _AdminDayDetailPageState extends State<AdminDayDetailPage> {
  late DateTime _date;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _meals = [];
  Map<String, dynamic>? _progress;

  String get _dateKey =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _date = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdminApi.getUserDetail(widget.userId, date: _dateKey);
      if (!mounted) return;
      setState(() {
        _meals = ((data['meals'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _progress = data['progress'] == null
            ? null
            : Map<String, dynamic>.from(data['progress'] as Map);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _load();
  }

  void _shiftDay(int delta) {
    final next = _date.add(Duration(days: delta));
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final earliest = todayOnly.subtract(const Duration(days: 365));
    if (next.isAfter(todayOnly) || next.isBefore(earliest)) return;
    setState(() => _date = next);
    _load();
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      default:
        return period;
    }
  }

  Future<void> _openMeal(Map<String, dynamic> meal) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminMealPhotoDetailPage(
          userId: widget.userId,
          displayName: widget.displayName,
          meal: meal,
          periodLabel: _periodLabel(meal['period']?.toString() ?? ''),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final withPhoto = _meals.where((m) => m['hasImage'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết ngày'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Chọn ngày',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _shiftDay(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Ngày trước',
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _dateKey,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _loading
                              ? 'Đang tải…'
                              : '${_meals.length} bữa · $withPhoto ảnh',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shiftDay(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Ngày sau',
                  ),
                ],
              ),
            ),
          ),
          if (_progress != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Tiến độ: Sáng ${_bool(_progress!['mealBreakfast'])} · '
                'Trưa ${_bool(_progress!['mealLunch'])} · '
                'Tối ${_bool(_progress!['mealDinner'])} · '
                'Nước ${_countTrue(_progress!['waterSlots'])}/6 · '
                'VĐ ${_countTrue(_progress!['exerciseSlots'])}/3',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _load,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _meals.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.sizeOf(context).height * 0.4,
                                    child: Center(
                                      child: Text(
                                        'Ngày này chưa có ảnh / bữa ăn',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 28),
                                itemCount: _meals.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final meal = _meals[i];
                                  return _DayMealTile(
                                    title: _periodLabel(
                                      meal['period']?.toString() ?? '',
                                    ),
                                    meal: meal,
                                    imageUrl: meal['hasImage'] == true &&
                                            meal['id'] != null
                                        ? AdminApi.mealImageUri(
                                            widget.userId,
                                            meal['id'] as String,
                                          )
                                        : null,
                                    onTap: () => _openMeal(meal),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  String _bool(dynamic v) => v == true ? '✓' : '✗';

  int _countTrue(dynamic list) {
    if (list is! List) return 0;
    return list.where((e) => e == true).length;
  }
}

class _DayMealTile extends StatelessWidget {
  const _DayMealTile({
    required this.title,
    required this.meal,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final Map<String, dynamic> meal;
  final Uri? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final token = AuthService.instance.token;
    final foods = ((meal['foodItems'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final preview = foods.isEmpty
        ? ((meal['description'] as String?)?.trim().isNotEmpty == true
            ? meal['description'] as String
            : 'Chưa có món nhận diện')
        : foods.join(' · ');

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null && token != null)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl.toString(),
                          fit: BoxFit.cover,
                          headers: {'Authorization': 'Bearer $token'},
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.border.withValues(alpha: 0.35),
                            alignment: Alignment.center,
                            child: const Text('Không tải được ảnh'),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.zoom_in_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Xem chi tiết',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.35),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Text(
                    'Không có ảnh upload',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (meal['marksCompleted'] == true)
                          Text(
                            'Đã ghi nhận',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (foods.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: foods
                            .take(6)
                            .map(
                              (f) => Chip(
                                label: Text(f, style: const TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.22),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
