import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_mode.dart';
import 'router/app_router.dart';
import 'services/khade_repository.dart';
import 'services/khade_scope.dart';
import 'services/supabase_realtime_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.mode = KhadeAppMode.customer;
  await SupabaseRealtimeService.initialize();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const KhadeApp());
}

class KhadeApp extends StatelessWidget {
  const KhadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KhadeScope(
      repo: KhadeRepository.instance,
      child: MaterialApp.router(
        title: AppConfig.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: createRouter(),
      ),
    );
  }
}
