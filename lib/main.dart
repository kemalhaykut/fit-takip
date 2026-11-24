import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding.dart';
import 'rest_timer.dart';
import 'shell.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const FitTakipApp());
}

class FitTakipApp extends StatelessWidget {
  const FitTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = pal;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: p.dark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: p.surface,
          systemNavigationBarIconBrightness: p.dark ? Brightness.light : Brightness.dark,
        ));
        return MaterialApp(
          title: 'Fit Takip',
          debugShowCheckedModeBanner: false,
          navigatorKey: navKey,
          theme: buildTheme(p),
          home: store.hasProfile ? const HomeShell() : const OnboardingPage(),
        );
      },
    );
  }
}
