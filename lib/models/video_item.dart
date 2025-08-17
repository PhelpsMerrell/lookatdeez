class VideoItem {
  String id;
  String title;
  String url;

  VideoItem({
    required this.id,
    required this.title,
    required this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
    };
  }

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      url: json['url'] ?? '',
    );
  }
}