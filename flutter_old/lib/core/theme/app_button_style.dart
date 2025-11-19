import '../../constants/imports.dart';

class AppButtonStyle {
  ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.backgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.textGrey, width: 0.1, style: BorderStyle.solid),
    ),
    elevation: 0,
  );

  ButtonStyle secondary = ElevatedButton.styleFrom(
    backgroundColor: Colors.green[50],
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.textGrey, width: 0.1, style: BorderStyle.solid),
    ),
    elevation: 0,
  );
}
