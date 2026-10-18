import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/device/device_info_service.dart';
import 'core/navigation/navigation_service.dart';
import 'providers/auth_provider.dart';
import 'providers/device_security_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/correction_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system navigation bar & status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Core Networking & Device Detection
  ApiClient().init();
  await DeviceInfoService().init();

  runApp(const IaimuAttendanceApp());
}

class IaimuAttendanceApp extends StatelessWidget {
  const IaimuAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeviceSecurityProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => CorrectionProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => SmartNotificationProvider()),
      ],
      child: MaterialApp(
        title: 'IAIMU Presensi Mobile',
        navigatorKey: NavigationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/main': (_) => const MainNavigationScreen(),
        },
      ),
    );
  }
}
