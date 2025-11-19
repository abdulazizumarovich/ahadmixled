import '../constants/imports.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

sealed class AppRoutes {
  AppRoutes._();
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      default:
        return null;
    }
  }
}
