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
    return Friend(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      friendsSince: DateTime.tryParse(json['friendsSince'] ?? '') ?? DateTime.now(),
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
      id: json['id'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      fromUserDisplayName: json['fromUserDisplayName'] ?? '',
      toUserId: json['toUserId'] ?? '',
      toUserDisplayName: json['toUserDisplayName'] ?? '',
      status: _statusFromInt(json['status'] ?? 0),
      requestedAt: DateTime.tryParse(json['requestedAt'] ?? '') ?? DateTime.now(),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.tryParse(json['respondedAt']) 
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
    return FriendRequestsEnvelope(
      sent: (json['sent'] as List<dynamic>?)
          ?.map((item) => FriendRequest.fromJson(item))
          .toList() ?? [],
      received: (json['received'] as List<dynamic>?)
          ?.map((item) => FriendRequest.fromJson(item))
          .toList() ?? [],
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
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
