class ExerciseStep {
  const ExerciseStep({
    required this.phase,
    required this.title,
    required this.assetPath,
    required this.seconds,
    this.isRest = false,
  });

  final String phase;
  final String title;
  final String assetPath;
  final int seconds;
  final bool isRest;
}

const _jumpingAsset = 'assets/images/TheDuc/batnhay.png';
const _kneeAsset = 'assets/images/TheDuc/dachanchamkhuytay.png';

/// Giáo án đúng 10 phút (600 giây).
///
/// Khởi động 4 phút + vận động chính 4 phút + giãn cơ 2 phút.
const kExerciseSteps = <ExerciseStep>[
  ExerciseStep(
    phase: 'KHỞI ĐỘNG',
    title: 'Xoay cổ',
    assetPath: 'assets/images/TheDuc/xoayco.png',
    seconds: 30,
  ),
  ExerciseStep(
    phase: 'KHỞI ĐỘNG',
    title: 'Xoay khớp vai',
    assetPath: 'assets/images/TheDuc/xoaykhopvai.png',
    seconds: 30,
  ),
  ExerciseStep(
    phase: 'KHỞI ĐỘNG',
    title: 'Xoay cánh tay',
    assetPath: 'assets/images/TheDuc/xoaycanhtay.png',
    seconds: 30,
  ),
  ExerciseStep(
    phase: 'KHỞI ĐỘNG',
    title: 'Xoay cổ tay, cổ chân',
    assetPath: 'assets/images/TheDuc/xoaycotaycochan.png',
    seconds: 60,
  ),
  ExerciseStep(
    phase: 'KHỞI ĐỘNG',
    title: 'Xoay hông',
    assetPath: 'assets/images/TheDuc/xoayhong.png',
    seconds: 45,
  ),
  ExerciseStep(
    phase: 'KHỞI ĐỘNG',
    title: 'Xoay gối',
    assetPath: 'assets/images/TheDuc/xoaygoi.png',
    seconds: 45,
  ),

  // Jumping Jacks: 2 hiệp × (45 giây tập + 15 giây nghỉ).
  ExerciseStep(
    phase: 'VẬN ĐỘNG CHÍNH',
    title: 'Jumping Jacks · 1/2',
    assetPath: _jumpingAsset,
    seconds: 45,
  ),
  ExerciseStep(
    phase: 'NGHỈ',
    title: 'Nghỉ',
    assetPath: _jumpingAsset,
    seconds: 15,
    isRest: true,
  ),
  ExerciseStep(
    phase: 'VẬN ĐỘNG CHÍNH',
    title: 'Jumping Jacks · 2/2',
    assetPath: _jumpingAsset,
    seconds: 45,
  ),
  ExerciseStep(
    phase: 'NGHỈ',
    title: 'Nghỉ',
    assetPath: _jumpingAsset,
    seconds: 15,
    isRest: true,
  ),
  // Gối chạm khuỷu: 2 hiệp × (45 giây tập + 15 giây nghỉ).
  ExerciseStep(
    phase: 'VẬN ĐỘNG CHÍNH',
    title: 'Gối chạm khuỷu · 1/2',
    assetPath: _kneeAsset,
    seconds: 45,
  ),
  ExerciseStep(
    phase: 'NGHỈ',
    title: 'Nghỉ',
    assetPath: _kneeAsset,
    seconds: 15,
    isRest: true,
  ),
  ExerciseStep(
    phase: 'VẬN ĐỘNG CHÍNH',
    title: 'Gối chạm khuỷu · 2/2',
    assetPath: _kneeAsset,
    seconds: 45,
  ),
  ExerciseStep(
    phase: 'NGHỈ',
    title: 'Nghỉ',
    assetPath: _kneeAsset,
    seconds: 15,
    isRest: true,
  ),
  ExerciseStep(
    phase: 'GIÃN CƠ',
    title: 'Gập người chạm mũi chân',
    assetPath: 'assets/images/TheDuc/gapnguoi.png',
    seconds: 120,
  ),
];

const kExerciseTotalSeconds = 10 * 60;
