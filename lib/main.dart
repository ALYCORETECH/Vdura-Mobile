import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:sales_management/core/services/location/location_tracking_service.dart';
import 'package:sales_management/core/theme/theme.dart';
import 'package:sales_management/core/widgets/connectivity_gate.dart';
import 'package:sales_management/features/auth/screens/auth_check_screen.dart';
import 'package:sales_management/features/auth/screens/authentication_screen.dart';

import 'package:sales_management/core/utils/file_logger.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await FileLogger().init();
  FileLogger().i("App Started - Initializing LocationTrackingService");
  await LocationTrackingService.initialize();
  runApp(const VanguardeApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class VanguardeApp extends StatefulWidget {
  const VanguardeApp({super.key});
  @override
  State<VanguardeApp> createState() => _VanguardeAppState();
}

class _VanguardeAppState extends State<VanguardeApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Vanguarde',
      theme: VanguardeTheme.light,
      darkTheme: VanguardeTheme.dark,
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return BotToastInit()(
          context,
          ConnectivityGate(
            navigatorKey: navigatorKey,
            child: child!,
          ),
        );
      },
      navigatorObservers: [BotToastNavigatorObserver()],

      home: AuthCheckScreen(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),

    );
  }
}