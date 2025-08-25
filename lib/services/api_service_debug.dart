import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/video_item.dart';
import '../config/environment.dart';
import 'auth_service.dart';

class ApiService {
  static String get baseUrl => Environment.apiBaseUrl;
  
  static Future<Map<String, String>> get _headers async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // Debug: Check if we have a token
    print('=== API SERVICE DEBUG ===');
    final bearerToken = await AuthService.getBearerToken();
    print('Bearer token exists: ${bearerToken != null}');
    
    if (bearerToken != null) {
      print('Token length: ${bearerToken.length}');
      print('Token preview: ${bearerToken.substring(0, 30)}...');
      headers['Authorization'] = bearerToken;
    } else {
      print('ERROR: No bearer token available!');
      
      // Debug token retrieval
      final accessToken = await AuthService.getAccessToken();
      print('Access token exists: ${accessToken != null}');
      
      if (accessToken != null) {
        print('Access token length: ${accessToken.length}');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final tokenFromStorage = prefs.getString('ms_access_token');
      print('Token in storage: ${tokenFromStorage != null}');
    }
    
    return headers;
  }

  static Future<List<Playlist>> getPlaylists() async {
    try {
      print('=== GET PLAYLISTS DEBUG ===');
      print('API Base URL: $baseUrl');
      
      final headers = await _headers;
      print('Request headers: $headers');
      
      final fullUrl = '$baseUrl/playlists';
      print('Full URL: $fullUrl');
      
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> owned = data['owned'] ?? [];
        final List<dynamic> shared = data['shared'] ?? [];
        
        final allPlaylists = [...owned, ...shared];
        
        // Remove duplicates by ID
        final uniquePlaylists = <String, Map<String, dynamic>>{};
        for (var playlist in allPlaylists) {
          uniquePlaylists[playlist['id']] = playlist;
        }
        
        return uniquePlaylists.values.map((json) => Playlist.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else {
        throw Exception('Failed to load playlists: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }
  
  // Add the rest of your methods here...
}