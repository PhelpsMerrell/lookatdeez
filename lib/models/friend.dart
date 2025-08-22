class Friend {
  final String id;
  final String displayName;
  final String email;
  final DateTime friendsSince;

  Friend({
    required this.id,
    required this.displayName,
    required this.email,
    required this.friendsSince,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    // Handle different possible field names from the API (backend uses PascalCase)
    final id = json['Id'] ?? json['id'] ?? '';
    final displayName = json['DisplayName'] ?? json['displayName'] ?? '';
    final email = json['Email'] ?? json['email'] ?? '';
    final friendsSinceStr = json['FriendsSince'] ?? json['friendsSince'] ?? '';
    
    DateTime friendsSince;
    if (friendsSinceStr.isNotEmpty) {
      friendsSince = DateTime.tryParse(friendsSinceStr) ?? DateTime.now();
    } else {
      friendsSince = DateTime.now();
    }
    
    return Friend(
      id: id,
      displayName: displayName,
      email: email,
      friendsSince: friendsSince,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'friendsSince': friendsSince.toIso8601String(),
    };
  }
}

enum FriendRequestStatus { pending, accepted, declined }

class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUserDisplayName;
  final String toUserId;
  final String toUserDisplayName;
  final FriendRequestStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserDisplayName,
    required this.toUserId,
    required this.toUserDisplayName,
    required this.status,
    required this.requestedAt,
    this.respondedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['Id'] ?? json['id'] ?? '',
      fromUserId: json['FromUserId'] ?? json['fromUserId'] ?? '',
      fromUserDisplayName: json['FromUserDisplayName'] ?? json['fromUserDisplayName'] ?? '',
      toUserId: json['ToUserId'] ?? json['toUserId'] ?? '',
      toUserDisplayName: json['ToUserDisplayName'] ?? json['toUserDisplayName'] ?? '',
      status: _statusFromInt(json['Status'] ?? json['status'] ?? 0),
      requestedAt: DateTime.tryParse(json['RequestedAt'] ?? json['requestedAt'] ?? '') ?? DateTime.now(),
      respondedAt: (json['RespondedAt'] ?? json['respondedAt']) != null 
          ? DateTime.tryParse(json['RespondedAt'] ?? json['respondedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserDisplayName': fromUserDisplayName,
      'toUserId': toUserId,
      'toUserDisplayName': toUserDisplayName,
      'status': _statusToInt(status),
      'requestedAt': requestedAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  static FriendRequestStatus _statusFromInt(int status) {
    switch (status) {
      case 0: return FriendRequestStatus.pending;
      case 1: return FriendRequestStatus.accepted;
      case 2: return FriendRequestStatus.declined;
      default: return FriendRequestStatus.pending;
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

class FriendRequestsEnvelope {
  final List<FriendRequest> sent;
  final List<FriendRequest> received;

  FriendRequestsEnvelope({
    required this.sent,
    required this.received,
  });

  factory FriendRequestsEnvelope.fromJson(Map<String, dynamic> json) {
    // Handle Sent requests
    List<FriendRequest> sentRequests = [];
    final sentJson = json['Sent'] ?? json['sent'];
    if (sentJson != null && sentJson is List) {
      sentRequests = sentJson
          .map((item) => FriendRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Handle Received requests
    List<FriendRequest> receivedRequests = [];
    final receivedJson = json['Received'] ?? json['received'];
    if (receivedJson != null && receivedJson is List) {
      receivedRequests = receivedJson
          .map((item) => FriendRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return FriendRequestsEnvelope(
      sent: sentRequests,
      received: receivedRequests,
    );
  }
}

class User {
  final String id;
  final String displayName;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.displayName,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['Id'] ?? json['id'] ?? '',
      displayName: json['DisplayName'] ?? json['displayName'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      createdAt: DateTime.tryParse(json['CreatedAt'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
