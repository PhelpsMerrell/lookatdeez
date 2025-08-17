import 'video_item.dart';

class Playlist {
  final String id;
  String name;
  List<VideoItem> videos;

  Playlist({
    required this.id,
    required this.name,
    this.videos = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'videos': videos.map((v) => v.toJson()).toList(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      name: json['title'] ?? '', // API returns 'title'
      videos: (json['items'] as List<dynamic>?) // API returns 'items'
          ?.map((v) => VideoItem.fromJson(v))
          .toList() ?? [],
    );
  }
}