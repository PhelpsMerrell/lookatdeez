import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoTermsDialog extends StatelessWidget {
  const VideoTermsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const VideoTermsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Video Content Notice'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This app provides a convenient way to view videos from various platforms. Please note:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            
            _buildTermsSection(
              '📺 Content Sources',
              'Videos are played directly from their original platforms (YouTube, Instagram, TikTok, Vimeo, etc.) using official embedding methods.',
            ),
            
            _buildTermsSection(
              '🔒 No Content Storage',
              'We do not download, store, or redistribute any video content. All videos remain on their original platforms.',
            ),
            
            _buildTermsSection(
              '⚖️ Platform Terms Apply',
              'All content is subject to the terms of service of the original platform. We respect platform branding, ads, and access controls.',
            ),
            
            _buildTermsSection(
              '🔗 Fallback Links',
              'If a video cannot be embedded, we provide a direct link to view it on the original platform.',
            ),
            
            _buildTermsSection(
              '👤 User Responsibility',
              'Users are responsible for ensuring they have permission to share video URLs and comply with platform-specific terms.',
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Text(
                '💡 This app functions similarly to how web browsers display embedded content - providing a better viewing experience for content you already have permission to access.',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Understood'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showPlatformPolicies(context);
          },
          child: const Text('View Platform Policies'),
        ),
      ],
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  static void _showPlatformPolicies(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PlatformPoliciesDialog(),
    );
  }
}

class PlatformPoliciesDialog extends StatelessWidget {
  const PlatformPoliciesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Platform Policies'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick links to platform terms of service:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            
            _buildPolicyLink(
              '📺 YouTube',
              'Terms of Service',
              'https://www.youtube.com/t/terms',
            ),
            
            _buildPolicyLink(
              '📷 Instagram',
              'Terms of Use',
              'https://help.instagram.com/581066165581870/',
            ),
            
            _buildPolicyLink(
              '🎵 TikTok',
              'Terms of Service',
              'https://www.tiktok.com/legal/terms-of-service',
            ),
            
            _buildPolicyLink(
              '🎬 Vimeo',
              'Terms of Service',
              'https://vimeo.com/terms',
            ),
            
            _buildPolicyLink(
              '🎮 Twitch',
              'Terms of Service',
              'https://www.twitch.tv/p/legal/terms-of-service/',
            ),
            
            _buildPolicyLink(
              '🐦 Twitter/X',
              'Terms of Service',
              'https://twitter.com/tos',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildPolicyLink(String platform, String title, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Text(platform, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// Quick access widget for embedding in other screens
class VideoTermsButton extends StatelessWidget {
  const VideoTermsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => VideoTermsDialog.show(context),
      icon: const Icon(Icons.info_outline, size: 16),
      label: const Text('Video Terms', style: TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey[600],
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
