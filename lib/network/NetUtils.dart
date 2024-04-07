import 'package:dio/dio.dart';

/// 网络请求
class NetUtils {
  static final Dio dio = Dio();

  static Future<dynamic> get(String apiUrl) async {
    try {
      Response response = await dio.get(apiUrl);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error during GET request: $e');
      return null;
    }
  }

  static Future<dynamic> post(String apiUrl, data) async {
    try {
      Response response = await dio.post(apiUrl, data: data);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to send POST request');
      }
    } catch (e) {
      print('Error during POST request: $e');
      return null;
    }
  }
}
