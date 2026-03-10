// Archivo: lib/features/auth/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:gym_app/core/network/api_constants.dart'; 

class AuthService {
  
  Future<String> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      // 200 OK
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData.containsKey('token')) {
          return responseData['token'];
        } else {
          throw Exception('The server responded, but did not provide a token.');
        }
      } 
      // 401 Unauthorized or 403 Forbidden
      else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Invalid username or password.');
      } 
      // 500+ Internal Server Error
      else if (response.statusCode >= 500) {
        throw Exception('Internal server error. Please try again later.');
      } 
      // Any other HTTP error
      else {
        throw Exception('Unexpected error: ${response.statusCode}');
      }

    } on SocketException {
      // No internet or server down
      throw Exception('No connection to the server. Please check your internet connection or ensure the backend is running.');
    } on TimeoutException {
      // Request took longer than 10 seconds
      throw Exception('The connection timed out. Please check your network and try again.');
    } catch (e) {
      // Any other unexpected error
      throw Exception('An unexpected error occurred: $e');
    }
  }
}