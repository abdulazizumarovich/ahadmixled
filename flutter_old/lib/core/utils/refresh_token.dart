// import '../../constants/imports.dart';

// Future<void> refreshToken() async {
//   try {
//     final response = await dio.post(
//       '/refresh',
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${box.read('refresh')}',
//         },
//       ),
//     );
//     await box.write('token', response.data['data']['access_token']);
//     await box.write('refresh', response.data['data']['refresh_token']);
//     await box.write('profile', response.data['data']['info']);
//     await init();
//   } catch (e) {
//     Get.offAllNamed(Routes.player);
//     rethrow;
//   }
// }
