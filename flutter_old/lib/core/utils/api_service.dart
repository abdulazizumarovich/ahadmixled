// import '../../constants/imports.dart';

// class ApiService {
//   ApiService();

//   Future<dynamic> makeGetRequest(
//     String endpoint, {
//     Map<String, dynamic>? queryParameters,
//     bool? fullResponse = false,
//   }) async {
//     try {
//       final response = await dio.get(
//         endpoint,
//         queryParameters: queryParameters,
//       );
//       return response.data;
//     } on DioException catch (e) {
//       if (e.response != null) {
//         debugPrint(
//           '=================\n${e.response!.statusCode}\n$endpoint\n${e.response!}\n=================',
//         );
//         throw fullResponse! ? e : e.response!.data['detail'];
//       } else {
//         throw 'Unknown error occurred';
//       }
//     }
//   }

//   Future<dynamic> makePostRequest(
//     String endpoint, {
//     Map<dynamic, dynamic>? data,
//     bool? fullResponse = false,
//   }) async {
//     try {
//       final response = await dio.post(endpoint, data: data);

//       return response.data;
//     } on DioException catch (e) {
//       if (e.response != null) {
//         debugPrint(
//           '=================\n${e.response!.statusCode}\n$endpoint\n${e.response!}\n=================',
//         );
//         throw fullResponse! ? e : e.response!.data['detail'];
//       } else {
//         throw 'Unknown error occurred';
//       }
//     }
//   }

//   Future<dynamic> makePatchRequest(
//     String endpoint, {
//     Map<dynamic, dynamic>? data,
//     bool? fullResponse = false,
//   }) async {
//     try {
//       final response = await dio.patch(endpoint, data: data);
//       return response.data;
//     } on DioException catch (e) {
//       if (e.response != null) {
//         debugPrint(
//           '=================\n${e.response!.statusCode}\n$endpoint\n${e.response!}\n=================',
//         );
//         throw fullResponse! ? e : e.response!.data['detail'];
//       } else {
//         throw 'Unknown error occurred';
//       }
//     }
//   }

//   Future<dynamic> makePutRequest(
//     String endpoint, {
//     Map<dynamic, dynamic>? data,
//     bool? fullResponse = false,
//   }) async {
//     try {
//       final response = await dio.put(endpoint, data: data);
//       return response.data;
//     } on DioException catch (e) {
//       if (e.response != null) {
//         debugPrint(
//           '=================\n${e.response!.statusCode}\n$endpoint\n${e.response!}\n=================',
//         );
//         throw fullResponse! ? e : e.response!.data['detail'];
//       } else {
//         throw 'Unknown error occurred';
//       }
//     }
//   }
// }
