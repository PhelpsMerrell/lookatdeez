enum VideoPlatform {
  youtube,
  instagram,
  tiktok,
  vimeo,
  twitch,
  twitter,
  direct,
  unsupported,
}

class ParsedVideo {
  final VideoPlatform platform;
  final String videoId;
  final String originalUrl;
  final String embedUrl;
  final Map<String, String> metadata;

  ParsedVideo({
    required this.platform,
    required this.videoId,
    required this.originalUrl,
    required this.embedUrl,
    this.metadata = const {},
  });
}

class VideoUrlParser {
  static ParsedVideo parseUrl(String url) {
    try {
      final uri = Uri.parse(url.trim());
      final domain = uri.host.toLowerCase();
      final path = uri.path;
      final query = uri.queryParameters;

      // YouTube Detection
      if (_isYoutube(domain)) {
        return _parseYoutube(uri, url);
      }

      // Instagram Detection
      if (_isInstagram(domain)) {
        return _parseInstagram(uri, url);
      }

      // TikTok Detection
      if (_isTiktok(domain)) {
        return _parseTiktok(uri, url);
      }

      // Vimeo Detection
      if (_isVimeo(domain)) {
        return _parseVimeo(uri, url);
      }

      // Twitch Detection
      if (_isTwitch(domain)) {
        return _parseTwitch(uri, url);
      }

      // Twitter Detection
      if (_isTwitter(domain)) {
        return _parseTwitter(uri, url);
      }

      // Direct Video File Detection
      if (_isDirectVideo(path)) {
        return _parseDirectVideo(uri, url);
      }

      // Fallback to unsupported
      return ParsedVideo(
        platform: VideoPlatform.unsupported,
        videoId: '',
        originalUrl: url,
        embedUrl: '',
        metadata: {'error': 'Unsupported platform'},
      );
    } catch (e) {
      return ParsedVideo(
        platform: VideoPlatform.unsupported,
        videoId: '',
        originalUrl: url,
        embedUrl: '',
        metadata: {'error': 'Invalid URL: $e'},
      );
    }
  }

  // Platform Detection Methods
  static bool _isYoutube(String domain) {
    return domain.contains('youtube.') ||
           domain.contains('youtu.be') ||
           domain.contains('m.youtube.');
  }

  static bool _isInstagram(String domain) {
    return domain.contains('instagram.') ||
           domain.contains('instagr.am');
  }

  static bool _isTiktok(String domain) {
    return domain.contains('tiktok.') ||
           domain.contains('vm.tiktok.');
  }

  static bool _isVimeo(String domain) {
    return domain.contains('vimeo.');
  }

  static bool _isTwitch(String domain) {
    return domain.contains('twitch.tv') ||
           domain.contains('clips.twitch.tv');
  }

  static bool _isTwitter(String domain) {
    return domain.contains('twitter.') ||
           domain.contains('x.com') ||
           domain.contains('t.co');
  }

  static bool _isDirectVideo(String path) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'];
    return videoExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  // Platform-Specific Parsers
  static ParsedVideo _parseYoutube(Uri uri, String originalUrl) {
    String? videoId;

    if (uri.host.contains('youtu.be')) {
      // Short URL: https://youtu.be/VIDEO_ID
      videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    } else {
      // Regular URL: https://youtube.com/watch?v=VIDEO_ID
      videoId = uri.queryParameters['v'];
    }

    if (videoId == null || videoId.isEmpty) {
      return ParsedVideo(
        platform: VideoPlatform.unsupported,
        videoId: '',
        originalUrl: originalUrl,
        embedUrl: '',
        metadata: {'error': 'Could not extract YouTube video ID'},
      );
    }

    return ParsedVideo(
      platform: VideoPlatform.youtube,
      videoId: videoId,
      originalUrl: originalUrl,
      embedUrl: 'https://www.youtube.com/embed/$videoId',
      metadata: {
        'autoplay': '0',
        'controls': '1',
        'rel': '0',
      },
    );
  }

  static ParsedVideo _parseInstagram(Uri uri, String originalUrl) {
    // Instagram: https://instagram.com/p/POST_ID/ or /reel/POST_ID/
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length >= 2 && 
        (pathSegments[0] == 'p' || pathSegments[0] == 'reel')) {
      final postId = pathSegments[1];
      return ParsedVideo(
        platform: VideoPlatform.instagram,
        videoId: postId,
        originalUrl: originalUrl,
        embedUrl: 'https://www.instagram.com/p/$postId/embed/',
        metadata: {'type': pathSegments[0]},
      );
    }

    return ParsedVideo(
      platform: VideoPlatform.unsupported,
      videoId: '',
      originalUrl: originalUrl,
      embedUrl: '',
      metadata: {'error': 'Could not extract Instagram post ID'},
    );
  }

  static ParsedVideo _parseTiktok(Uri uri, String originalUrl) {
    // TikTok: https://tiktok.com/@username/video/VIDEO_ID
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length >= 3 && pathSegments[1] == 'video') {
      final videoId = pathSegments[2];
      return ParsedVideo(
        platform: VideoPlatform.tiktok,
        videoId: videoId,
        originalUrl: originalUrl,
        embedUrl: 'https://www.tiktok.com/embed/v2/$videoId',
        metadata: {},
      );
    }

    return ParsedVideo(
      platform: VideoPlatform.unsupported,
      videoId: '',
      originalUrl: originalUrl,
      embedUrl: '',
      metadata: {'error': 'Could not extract TikTok video ID'},
    );
  }

  static ParsedVideo _parseVimeo(Uri uri, String originalUrl) {
    // Vimeo: https://vimeo.com/VIDEO_ID
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.isNotEmpty) {
      final videoId = pathSegments[0];
      return ParsedVideo(
        platform: VideoPlatform.vimeo,
        videoId: videoId,
        originalUrl: originalUrl,
        embedUrl: 'https://player.vimeo.com/video/$videoId',
        metadata: {},
      );
    }

    return ParsedVideo(
      platform: VideoPlatform.unsupported,
      videoId: '',
      originalUrl: originalUrl,
      embedUrl: '',
      metadata: {'error': 'Could not extract Vimeo video ID'},
    );
  }

  static ParsedVideo _parseTwitch(Uri uri, String originalUrl) {
    // Twitch: https://twitch.tv/username or https://clips.twitch.tv/CLIP_ID
    final pathSegments = uri.pathSegments;
    
    if (uri.host.contains('clips.twitch.tv') && pathSegments.isNotEmpty) {
      final clipId = pathSegments[0];
      return ParsedVideo(
        platform: VideoPlatform.twitch,
        videoId: clipId,
        originalUrl: originalUrl,
        embedUrl: 'https://clips.twitch.tv/embed?clip=$clipId',
        metadata: {'type': 'clip'},
      );
    }

    return ParsedVideo(
      platform: VideoPlatform.unsupported,
      videoId: '',
      originalUrl: originalUrl,
      embedUrl: '',
      metadata: {'error': 'Only Twitch clips are supported for embedding'},
    );
  }

  static ParsedVideo _parseTwitter(Uri uri, String originalUrl) {
    return ParsedVideo(
      platform: VideoPlatform.twitter,
      videoId: '',
      originalUrl: originalUrl,
      embedUrl: '',
      metadata: {'note': 'Twitter videos require oEmbed or direct linking'},
    );
  }

  static ParsedVideo _parseDirectVideo(Uri uri, String originalUrl) {
    return ParsedVideo(
      platform: VideoPlatform.direct,
      videoId: '',
      originalUrl: originalUrl,
      embedUrl: originalUrl,
      metadata: {},
    );
  }

  // Helper method to get platform display name
  static String getPlatformName(VideoPlatform platform) {
    switch (platform) {
      case VideoPlatform.youtube:
        return 'YouTube';
      case VideoPlatform.instagram:
        return 'Instagram';
      case VideoPlatform.tiktok:
        return 'TikTok';
      case VideoPlatform.vimeo:
        return 'Vimeo';
      case VideoPlatform.twitch:
        return 'Twitch';
      case VideoPlatform.twitter:
        return 'Twitter';
      case VideoPlatform.direct:
        return 'Direct Video';
      case VideoPlatform.unsupported:
        return 'Unsupported';
    }
  }

  // Helper method to get platform icon
  static String getPlatformIcon(VideoPlatform platform) {
    switch (platform) {
      case VideoPlatform.youtube:
        return '📺';
      case VideoPlatform.instagram:
        return '📷';
      case VideoPlatform.tiktok:
        return '🎵';
      case VideoPlatform.vimeo:
        return '🎬';
      case VideoPlatform.twitch:
        return '🎮';
      case VideoPlatform.twitter:
        return '🐦';
      case VideoPlatform.direct:
        return '🎥';
      case VideoPlatform.unsupported:
        return '❓';
    }
  }
}
