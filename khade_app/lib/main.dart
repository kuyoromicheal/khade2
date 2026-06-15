import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'router/app_router.dart';
import 'services/khade_repository.dart';
import 'services/khade_scope.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        title: 'Khade',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: createRouter(),
      ),
    );
  }
}
