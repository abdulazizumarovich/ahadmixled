import '../../constants/imports.dart';

class AppTheme {
  ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.lightBlue,
    useMaterial3: false,
    scaffoldBackgroundColor: AppColors.backgroundColor,
    appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.lightBlue)),
  );
}
