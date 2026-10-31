import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_management/core/services/location/location_tracking_service.dart';
import 'package:sales_management/core/theme/theme.dart';
import 'package:sales_management/core/services/theme/theme_service.dart';
import 'package:sales_management/core/widgets/connectivity_gate.dart';
import 'package:sales_management/features/auth/screens/auth_check_screen.dart';
import 'package:sales_management/core/utils/file_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FileLogger().init();
  FileLogger().i("App Started - Initializing LocationTrackingService");
  await LocationTrackingService.initialize();
  
  final themeService = ThemeService();
  await themeService.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: themeService,
      child: const VanguardeApp(),
    ),
  );
}

final navigatorKey = GlobalKey<NavigatorState>();

class VanguardeApp extends StatelessWidget {
  const VanguardeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Vanguarde',
          theme: VanguardeTheme.getTheme(themeService.themeStyle, Brightness.light),
          darkTheme: VanguardeTheme.getTheme(themeService.themeStyle, Brightness.dark),
          themeMode: themeService.themeMode,
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
          home: const AuthCheckScreen(),
        );
      },
    );
  }
}