import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_constants.dart';
import 'package:meo_traker/core/theme/app_theme.dart';
import 'package:meo_traker/core/utils/auth_navigation.dart';
import 'package:meo_traker/core/time/app_clock.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:meo_traker/data/services/local_notification_service.dart';
import 'package:meo_traker/data/services/meal_log_service.dart';
import 'package:meo_traker/data/services/meal_reminder_service.dart';
import 'package:meo_traker/data/services/meal_schedule_service.dart';
import 'package:meo_traker/data/services/progress_service.dart';
import 'package:meo_traker/data/services/theme_settings_service.dart';
import 'package:meo_traker/data/services/weather_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppClock.instance.sync();
  await WeatherService.instance.fetch();
  await AuthService.instance.loadSession();
  await ThemeSettingsService.instance.load();
  await MealScheduleService.instance.load();
  await MealLogService.instance.load();
  await ProgressService.instance.load();
  MealScheduleService.instance.onMealCompletionChanged =
      ProgressService.instance.syncMealsFromSchedule;
  await LocalNotificationService.instance.init();
  runApp(const MeoTrakerApp());
}

class MeoTrakerApp extends StatefulWidget {
  const MeoTrakerApp({super.key});

  @override
  State<MeoTrakerApp> createState() => _MeoTrakerAppState();
}

class _MeoTrakerAppState extends State<MeoTrakerApp> {
  @override
  void initState() {
    super.initState();
    ThemeSettingsService.instance.addListener(_onTheme);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MealReminderService.instance.start(key: appNavigatorKey);
    });
  }

  @override
  void dispose() {
    ThemeSettingsService.instance.removeListener(_onTheme);
    MealReminderService.instance.stop();
    super.dispose();
  }

  void _onTheme() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeSettingsService.instance.isDark;
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: AppConstants.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: destinationForUser(AuthService.instance.currentUser),
      debugShowCheckedModeBanner: false,
    );
  }
}
