import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  late final Dio _dio;
  String? _authToken;

  DioClient({String? baseUrl}) {
    // Default to localhost for desktop/web, or 10.0.2.2 for Android emulator
    final defaultUrl = (defaultTargetPlatform == TargetPlatform.android && !kIsWeb)
        ? 'http://10.0.2.2:3000/api/v1'
        : 'http://localhost:3000/api/v1';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? defaultUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        responseType: ResponseType.json,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          debugPrint('[DioClient Error] ${error.requestOptions.uri}: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Dio get dio => _dio;

  // 0. Delta Sync API
  Future<Response> getSyncChanges({int sinceVersion = 0, String? etag}) async {
    final headers = <String, dynamic>{};
    if (etag != null && etag.isNotEmpty) {
      headers['If-None-Match'] = etag;
    }
    return _dio.get(
      '/sync',
      queryParameters: {'since': sinceVersion},
      options: Options(headers: headers),
    );
  }

  // 1. Auth APIs
  Future<Response> login(String username, String password) async {
    return _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
  }

  Future<Response> getMe() async {
    return _dio.get('/auth/me');
  }

  // 2. Places API
  Future<Response> getPlaces({String? category, String? query}) async {
    final queryParams = <String, dynamic>{};
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    if (query != null && query.isNotEmpty) {
      queryParams['query'] = query;
    }
    return _dio.get('/places', queryParameters: queryParams);
  }

  // 3. Events API
  Future<Response> getEvents({String? category}) async {
    final queryParams = <String, dynamic>{};
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    return _dio.get('/events', queryParameters: queryParams);
  }

  // 4. Announcements API
  Future<Response> getAnnouncements() async {
    return _dio.get('/announcements');
  }

  // 5. Emergency Facilities API
  Future<Response> getEmergencyFacilities({String? type}) async {
    final queryParams = <String, dynamic>{};
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }
    return _dio.get('/emergency/facilities', queryParameters: queryParams);
  }

  // 6. SOS API
  Future<Response> postSOS(Map<String, dynamic> data) async {
    return _dio.post('/sos', data: data);
  }

  Future<Response> getSOSStatus(int id) async {
    return _dio.get('/sos/$id');
  }

  Future<Response> getSOSList({String? status, String? emergencyType}) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (emergencyType != null && emergencyType.isNotEmpty) queryParams['emergency_type'] = emergencyType;
    return _dio.get('/sos', queryParameters: queryParams);
  }

  Future<Response> updateSOSStatus(int id, String status, {String? remarks}) async {
    return _dio.patch('/sos/$id/status', data: {
      'status': status,
      if (remarks != null) 'remarks': remarks,
    });
  }

  // 7. Lost & Found API
  Future<Response> postLostFound(Map<String, dynamic> data) async {
    return _dio.post('/lost-found', data: data);
  }

  Future<Response> getLostFoundReports({String? type, String? query}) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type;
    if (query != null) queryParams['query'] = query;
    return _dio.get('/lost-found', queryParameters: queryParams);
  }

  // 8. AI Query API
  Future<Response> postAIQuery(String prompt) async {
    return _dio.post('/ai/query', data: {'prompt': prompt});
  }

  Future<Response> postAIPlan(Map<String, dynamic> details) async {
    return _dio.post('/ai/plan', data: details);
  }

  Future<Response> postAISos(String prompt) async {
    return _dio.post('/ai/sos', data: {'prompt': prompt});
  }

  // 9. Device Tokens Push API
  Future<Response> postDeviceToken(Map<String, dynamic> data) async {
    return _dio.post('/device-tokens', data: data);
  }
}
