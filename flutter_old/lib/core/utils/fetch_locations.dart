import '../../constants/imports.dart';

Future<List<dynamic>> fetchLocations() async {
  try {
    final response = await Dio().get('https://admin.gennis.uz/api/home_page/get_home_info');
    return response.data['locations'];
  } on DioException catch (error) {
    debugPrint('fetchLocations() $error');
    rethrow;
  }
}
