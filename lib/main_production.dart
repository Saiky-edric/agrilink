import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/theme_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Production version of main.dart without DevicePreview
/// Use this for production builds to avoid including DevicePreview in release
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await SupabaseService.initialize();
  final themeService = ThemeService();
  await themeService.initialize();
  
  runApp(AgrilinkApp(themeService: themeService));
}

class AgrilinkApp extends StatelessWidget {
  final ThemeService themeService;
  const AgrilinkApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp.router(
            title: 'Agrilink Digital Marketplace',
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