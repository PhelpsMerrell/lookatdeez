import 'package:http/http.dart' as http;
import 'dart:convert';
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
    
    final bearerToken = await AuthService.getBearerToken();
    if (bearerToken != null) {
      headers['Authorization'] = bearerToken;
    }
    
    return headers;
  }

  // ==== USER PROFILE ====

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/profile'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    } else {
      throw Exception('Failed to load profile: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final userId = await AuthService.getMicrosoftUserId();
    if (userId == null) {
      throw Exception('User ID not found. Please log in again.');
    }
    return getUserProfile(userId);
  }

  // ==== PLAYLISTS ====
  
  static Future<List<Playlist>> getPlaylists() async {
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
  }

  static Future<Playlist> createPlaylist(String name) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/playlists'),
      headers: headers,
      body: json.encode({'title': name, 'isPublic': false}),
    );
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Playlist.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    } else {
      throw Exception('Failed to create playlist: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> deletePlaylist(String playlistId) async {
    final headers = await _headers;
    final response = await http.delete(
      Uri.parse('$baseUrl/playlists/$playlistId'),
      headers: headers,
    );
    
    if (response.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    } else if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete playlist: ${response.statusCode}');
    }
  }

  static Future<VideoItem> addItemToPlaylist(String playlistId, String title, String url) async {
    if (playlistId.isEmpty) {
      throw Exception('Playlist ID is empty!');
    }
    
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/playlists/$playlistId/items'),
      headers: headers,
      body: json.encode({'title': title, 'url': url}),
    );
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return VideoItem.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    } else {
      throw Exception('Failed to add item: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> removeItemFromPlaylist(String playlistId, String itemId) async {
    final headers = await _headers;
    final response = await http.delete(
      Uri.parse('$baseUrl/playlists/$playlistId/items/$itemId'),
      headers: headers,
    );
    
    if (response.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    } else if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to remove item: ${response.statusCode}');
    }
  }

  static Future<void> reorderPlaylistItems(String playlistId, List<String> itemOrder) async {
    final headers = await _headers;
    final response = await http.put(
      Uri.parse('$baseUrl/playlists/$playlistId/items/order'),
      headers: headers,
      body: json.encode({'itemOrder': itemOrder}),
    );
    
    if (response.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    } else if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to reorder items: ${response.statusCode}');
    }
  }

  // ==== FRIEND MANAGEMENT ====
  
  static Future<List<Friend>> getUserFriends(String userId) async {
    try {
      print('=== Getting friends for user: $userId ===');
      final headers = await _headers;
      final url = '$baseUrl/users/$userId/friends';
      print('Friends API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('Friends response status: ${response.statusCode}');
      print('Friends response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Parsed friends data: $data');
        print('Number of friends: ${data.length}');
        
        final friends = data.map((json) {
          print('Parsing friend JSON: $json');
          return Friend.fromJson(json);
        }).toList();
        
        print('Successfully parsed ${friends.length} friends');
        return friends;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required. Please log in again.');
      } else {
        throw Exception('Failed to load friends: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Get friends error: $e');
      print('Stack trace: $stackTrace');
      // Don't silently return empty list - rethrow the error so we can see it
      rethrow;
    }
  }

  static Future<List<Friend>> getCurrentUserFriends() async {
    final userId = await AuthService.getMicrosoftUserId();
    if (userId == null) {
      throw Exception('User ID not found. Please log in again.');
    }
    return getUserFriends(userId);
  }

  static Future<FriendRequest> sendFriendRequest(String toUserId) async {
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/friend-requests'),
      headers: headers,
      body: json.encode({'toUserId': toUserId}),
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
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? response.body : 'Unknown error';
      }
      throw FriendRequestException(errorMessage);
    } else {
      throw Exception('Failed to send friend request: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<FriendRequestsEnvelope> getFriendRequests() async {
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
  }

  static Future<FriendRequest> updateFriendRequest(String requestId, FriendRequestStatus status) async {
    final headers = await _headers;
    final response = await http.put(
      Uri.parse('$baseUrl/friend-requests/$requestId'),
      headers: headers,
      body: json.encode({'status': _statusToInt(status)}),
    );
    
    if (response.statusCode == 200) {
      return FriendRequest.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    } else {
      throw Exception('Failed to update friend request: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> removeFriend(String friendId) async {
    final headers = await _headers;
    final response = await http.delete(
      Uri.parse('$baseUrl/friends/$friendId'),
      headers: headers,
    );
    
    if (response.statusCode == 401) {
      throw Exception('Authentication required. Please log in again.');
    } else if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to remove friend: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<User>> searchUsers(String searchTerm) async {
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
      throw Exception('Failed to search users: ${response.statusCode} - ${response.body}');
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
