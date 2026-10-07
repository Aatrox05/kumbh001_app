import 'package:dio/dio.dart';
import 'dio_client.dart';

class NetworkService {
  final DioClient _dioClient = DioClient();

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dioClient.dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dioClient.dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }
}
