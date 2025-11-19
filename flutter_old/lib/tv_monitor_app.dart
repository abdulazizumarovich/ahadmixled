import 'constants/imports.dart';

class TvMonitorApp extends StatelessWidget {
  const TvMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tv-monitor',
      // locale: box.read('language') != null
      //     ? Locale(box.read('language') == 'ru' ? 'ru' : 'uz')
      //     : const Locale('uz', 'UZ'),
      // fallbackLocale: const Locale('uz', 'UZ'),
      // localizationsDelegates: [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      themeMode: ThemeMode.light,
      // supportedLocales: const [Locale('uz', 'UZ'), Locale('ru', 'RU')],
      initialRoute: Routes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      navigatorKey: rootNavigatorKey,
    );
  }
}
