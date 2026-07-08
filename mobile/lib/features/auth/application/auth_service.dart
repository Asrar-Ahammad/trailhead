import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final Dio _dio;

  // Use machine's local IP since testing on a physical device
  static const String baseUrl = 'https://trailhead-seven.vercel.app/api/auth';
  static const String tokenKey = 'jwt_token';

  AuthService() : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        await saveToken(response.data['token']);
        return true;
      }
      return false;
    } on DioException catch (e) {
      print('Register DioError: \${e.message} \${e.response?.data}');
      return false;
    } catch (e) {
      print('Register Error: \$e');
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final response = await _dio.post('/register', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        await saveToken(response.data['token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
