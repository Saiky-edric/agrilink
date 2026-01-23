import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import 'package:device_preview/device_preview.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/badge_service.dart';
import 'core/config/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock screen orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Test logging system on startup
  print('🚀 AGRILINK APP STARTING - Main function called');
  EnvironmentConfig.testLogging();
  
  // Initialize services
  await SupabaseService.initialize();
  final themeService = ThemeService();
  await themeService.initialize();
  
  EnvironmentConfig.log('App initialization completed successfully');
  
  runApp(AgrilinkApp(themeService: themeService));
}

class AgrilinkApp extends StatefulWidget {
  final ThemeService themeService;
  const AgrilinkApp({super.key, required this.themeService});

  @override
  State<AgrilinkApp> createState() => _AgrilinkAppState();
}

class _AgrilinkAppState extends State<AgrilinkApp> {
  BadgeService? _badgeService;

  @override
  void initState() {
    super.initState();
    // Initialize badge service once in initState to avoid race conditions
    _badgeService = BadgeService();
    _badgeService!.initializeBadges();
    _badgeService!.startListening();
  }

  @override
  void dispose() {
    // Clean up badge service when app is disposed
    _badgeService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeService),
        ChangeNotifierProvider.value(value: _badgeService!),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp.router(
            title: 'Agrilink',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
