import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../router/app_router.dart';
import 'auth_scope.dart';
import 'sse_scope.dart';

class PrimeApp extends StatelessWidget {
  const PrimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SseScope(
      child: AuthScope(
        child: MaterialApp.router(
          title: 'Prime Academy',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.primeLight,
          darkTheme: AppTheme.primeDark,
          themeMode: ThemeMode.dark,
          routerConfig: appRouter,
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
