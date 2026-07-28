import 'dart:math';

import 'package:flutter/material.dart';

/// Kho slogan khuyến khích duy trì thói quen (uống nước + ăn đủ bữa).
enum SloganTheme { water, meal }

class HabitSlogan {
  const HabitSlogan(this.text, this.theme);

  final String text;
  final SloganTheme theme;
}

const habitSlogans = <HabitSlogan>[
  // Nước
  HabitSlogan(
    'Kẻ mạnh thực thụ là người dám uống đủ 2 lít nước mà không sợ đi toilet 10 lần một ngày!',
    SloganTheme.water,
  ),
  HabitSlogan(
    'Đừng để viên sỏi thận là thứ duy nhất lấp lánh và cứng cáp trong cuộc đời bạn. Cầm ly nước lên!',
    SloganTheme.water,
  ),
  HabitSlogan(
    'Nước biển mặn rồi, đừng để nước tiểu của bạn cũng đậm đà như thế. Bơm nước vào người ngay!',
    SloganTheme.water,
  ),
  HabitSlogan(
    'Bạn có thể ế, có thể nghèo, nhưng tế bào của bạn tuyệt đối không được phép thiếu nước!',
    SloganTheme.water,
  ),
  HabitSlogan(
    'Bộ não chứa 80% là nước, không uống đủ nước thì đừng trách sao hôm nay tư duy toàn đi vào lòng đất.',
    SloganTheme.water,
  ),
  // Ăn
  HabitSlogan(
    'Bỏ bữa là hành vi trực tiếp chống phá lại công sức quang hợp của cây cối và nền nông nghiệp nước nhà. Đi ăn đi!',
    SloganTheme.meal,
  ),
  HabitSlogan(
    'Người thành công luôn có lối đi riêng, nhưng chắc chắn lối đó phải đi qua bàn ăn đúng 3 lần một ngày.',
    SloganTheme.meal,
  ),
  HabitSlogan(
    'Muốn làm giang hồ thì dạ dày tuyệt đối không được phép sôi ùng ục giữa lúc đang thị uy. Nạp năng lượng nhanh!',
    SloganTheme.meal,
  ),
  HabitSlogan(
    'Nhịn đói không làm bạn đẹp hơn, nó chỉ làm bạn dễ quạu và dễ buông lời khẩu nghiệp hơn thôi.',
    SloganTheme.meal,
  ),
  HabitSlogan(
    'Không ăn đủ 3 bữa thì lấy sức đâu mà gánh team, gánh deadline và gánh cả dòng đời? Ăn ngay cho nóng!',
    SloganTheme.meal,
  ),
];

final _rng = Random();

HabitSlogan pickRandomSlogan({SloganTheme? prefer}) {
  final pool = prefer == null
      ? habitSlogans
      : habitSlogans.where((s) => s.theme == prefer).toList();
  if (pool.isEmpty) return habitSlogans[_rng.nextInt(habitSlogans.length)];
  return pool[_rng.nextInt(pool.length)];
}

/// 4 khung khuyến khích / ngày — mỗi khung tối đa 1 thông báo.
class EncouragementWindow {
  const EncouragementWindow({
    required this.id,
    required this.title,
    required this.windowLabel,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.theme,
  });

  final String id;
  final String title;
  final String windowLabel;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final SloganTheme theme;

  bool contains(DateTime now) {
    final mins = now.hour * 60 + now.minute;
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    return mins >= start && mins <= end;
  }
}

/// Sáng theo giờ thức dậy; trưa / chiều / tối theo khung cố định.
List<EncouragementWindow> buildEncouragementWindows(TimeOfDay wake) {
  final wakeEndMins = (wake.hour * 60 + wake.minute + 30).clamp(0, 24 * 60 - 1);
  return [
    EncouragementWindow(
      id: 'encourage_morning',
      title: 'Buổi sáng · thức dậy',
      windowLabel:
          '${_pad(wake.hour)}:${_pad(wake.minute)} – ${_pad(wakeEndMins ~/ 60)}:${_pad(wakeEndMins % 60)}',
      startHour: wake.hour,
      startMinute: wake.minute,
      endHour: wakeEndMins ~/ 60,
      endMinute: wakeEndMins % 60,
      theme: SloganTheme.water,
    ),
    const EncouragementWindow(
      id: 'encourage_lunch',
      title: 'Buổi trưa',
      windowLabel: '11:00 – 11:30',
      startHour: 11,
      startMinute: 0,
      endHour: 11,
      endMinute: 30,
      theme: SloganTheme.meal,
    ),
    const EncouragementWindow(
      id: 'encourage_afternoon',
      title: 'Giữa buổi chiều',
      windowLabel: '15:00 – 15:30',
      startHour: 15,
      startMinute: 0,
      endHour: 15,
      endMinute: 30,
      theme: SloganTheme.water,
    ),
    const EncouragementWindow(
      id: 'encourage_evening',
      title: 'Buổi tối',
      windowLabel: '19:00 – 20:00',
      startHour: 19,
      startMinute: 0,
      endHour: 20,
      endMinute: 0,
      theme: SloganTheme.meal,
    ),
  ];
}

String _pad(int n) => n.toString().padLeft(2, '0');

