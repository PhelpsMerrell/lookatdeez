import 'package:flutter/material.dart';
import '../services/video_url_parser.dart';

class VideoDebugWidget extends StatelessWidget {
  final String url;
  final ParsedVideo parsedVideo;
  
  const VideoDebugWidget({
    super.key,
    required this.url,
    required this.parsedVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange, size: 16),
              SizedBox(width: 4),
              Text(
                'DEBUG INFO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDebugRow('Original URL', url),
          _buildDebugRow('Platform', VideoUrlParser.getPlatformName(parsedVideo.platform)),
          _buildDebugRow('Video ID', parsedVideo.videoId),
          _buildDebugRow('Embed URL', parsedVideo.embedUrl),
          if (parsedVideo.metadata.isNotEmpty)
            _buildDebugRow('Metadata', parsedVideo.metadata.toString()),
        ],
      ),
    );
  }
  
  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: Colors.orange,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
