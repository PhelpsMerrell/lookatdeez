import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/video_item.dart';
import '../models/friend.dart';
import '../config/environment.dart';
import 'auth_service.dart';

class FriendRequestException implements Exception {
  final String message;
  FriendRequestException(this.message);
  
  @override
  String toString() => message;
}

class ApiService {
  static String get baseUrl => Environment.apiBaseUrl;
  
  static Future<Map<String, String>> get _headers async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // Use JWT Bearer token authentication
    final bearerToken = await AuthService.getBearerToken();
    if (bearerToken != null) {
      headers['Authorization'] = bearerToken;
    }
    
    return headers;
  }

  // Add user profile methods
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      print('Calling getUserProfile for userId: $userId');
      final headers = await _headers;
      print('Headers: $headers');
      
      final url = '$baseUrl/users/$userId/profile';
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else {
        throw Exception('Failed to load profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Profile API Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final userId = await AuthService.getDatabaseUserId();
    if (userId == null) {
      throw Exception('User ID not found. Please log in again.');
    }
    return getUserProfile(userId);
  }
  
  static Future<List<Playlist>> getPlaylists() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/playlists'),
        headers: headers,
      );
      
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

  static Future<Playlist> createPlaylist(String name) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/playlists'),
        headers: headers,
        body: json.encode({
          'title': name,
          'isPublic': false,
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Playlist.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else {
        throw Exception('Failed to create playlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Create error: $e');
      rethrow;
    }
  }

  static Future<void> deletePlaylist(String playlistId) async {
    try {
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('$baseUrl/playlists/$playlistId'),
        headers: headers,
      );
      
      if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode != 204) {
        throw Exception('Failed to delete playlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Delete error: $e');
      rethrow;
    }
  }

  static Future<VideoItem> addItemToPlaylist(String playlistId, String title, String url) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/playlists/$playlistId/items'),
        headers: headers,
        body: json.encode({
          'title': title,
          'url': url,
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return VideoItem.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else {
        throw Exception('Failed to add item: ${response.statusCode}');
      }
    } catch (e) {
      print('Add item error: $e');
      rethrow;
    }
  }

  static Future<void> removeItemFromPlaylist(String playlistId, String itemId) async {
    try {
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('$baseUrl/playlists/$playlistId/items/$itemId'),
        headers: headers,
      );
      
      if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode != 204) {
        throw Exception('Failed to remove item: ${response.statusCode}');
      }
    } catch (e) {
      print('Remove item error: $e');
      rethrow;
    }
  }

  static Future<void> reorderPlaylistItems(String playlistId, List<String> itemOrder) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('$baseUrl/playlists/$playlistId/items/order'),
        headers: headers,
        body: json.encode({
          'itemOrder': itemOrder,
        }),
      );
      
      if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode != 204) {
        throw Exception('Failed to reorder items: ${response.statusCode}');
      }
    } catch (e) {
      print('Reorder items error: $e');
      rethrow;
    }
  }

  // ==== FRIEND MANAGEMENT METHODS ====
  
  static Future<List<Friend>> getUserFriends(String userId) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/friends'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Friend.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else {
        throw Exception('Failed to load friends: ${response.statusCode}');
      }
    } catch (e) {
      print('Get friends error: $e');
      return [];
    }
  }

  static Future<List<Friend>> getCurrentUserFriends() async {
    final userId = await AuthService.getDatabaseUserId();
    if (userId == null) {
      throw Exception('User ID not found. Please log in again.');
    }
    return getUserFriends(userId);
  }

  static Future<FriendRequest> sendFriendRequest(String toUserId) async {
    try {
      final headers = await _headers;
      final response = await http.post(
        Uri.parse('$baseUrl/friend-requests'),
        headers: headers,
        body: json.encode({
          'toUserId': toUserId,
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return FriendRequest.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode == 400) {
        String errorMessage = 'Bad request';
        try {
          final errorBody = response.body;
          if (errorBody.isNotEmpty) {
            if (errorBody.startsWith('{')) {
              final errorJson = json.decode(errorBody);
              errorMessage = errorJson['error'] ?? errorBody;
            } else {
              errorMessage = errorBody;
            }
          }
        } catch (parseError) {
          errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error';
        }
        throw FriendRequestException(errorMessage);
      } else {
        throw Exception('Failed to send friend request: ${response.statusCode}');
      }
    } catch (e) {
      print('Send friend request error: $e');
      rethrow;
    }
  }

  static Future<FriendRequestsEnvelope> getFriendRequests() async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/friend-requests'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FriendRequestsEnvelope.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else {
        throw Exception('Failed to load friend requests: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Get friend requests error: $e');
      return FriendRequestsEnvelope(sent: [], received: []);
    }
  }

  static Future<FriendRequest> updateFriendRequest(String requestId, FriendRequestStatus status) async {
    try {
      final headers = await _headers;
      final response = await http.put(
        Uri.parse('$baseUrl/friend-requests/$requestId'),
        headers: headers,
        body: json.encode({
          'status': _statusToInt(status),
        }),
      );
      
      if (response.statusCode == 200) {
        return FriendRequest.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else {
        throw Exception('Failed to update friend request: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Update friend request error: $e');
      rethrow;
    }
  }

  static Future<void> removeFriend(String friendId) async {
    try {
      final headers = await _headers;
      final response = await http.delete(
        Uri.parse('$baseUrl/friends/$friendId'),
        headers: headers,
      );
      
      if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else if (response.statusCode != 204) {
        throw Exception('Failed to remove friend: ${response.statusCode}');
      }
    } catch (e) {
      print('Remove friend error: $e');
      rethrow;
    }
  }

  static Future<List<User>> searchUsers(String searchTerm) async {
    try {
      final headers = await _headers;
      final response = await http.get(
        Uri.parse('$baseUrl/users/search?q=${Uri.encodeQueryComponent(searchTerm)}'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else {
        throw Exception('Failed to search users: ${response.statusCode}');
      }
    } catch (e) {
      print('Search users error: $e');
      return [];
    }
  }

  static int _statusToInt(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending: return 0;
      case FriendRequestStatus.accepted: return 1;
      case FriendRequestStatus.declined: return 2;
    }
  }
}