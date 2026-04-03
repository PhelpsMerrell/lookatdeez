import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';
import '../widgets/video_terms_dialog.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.scaffoldGradient,
        child: SafeArea(
          child: Column(
            children: [
              // Nav bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white.withOpacity(0.8), size: 20),
                    ),
                    const Expanded(
                      child: Text(
                        'About',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App info
                      GlassCard(
                        radius: AppTheme.radiusMd,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.playlist_play, size: 28, color: Colors.cyan.withOpacity(0.9)),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('LookatDeez', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                    Text('Version 1.0.0', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Create and share video playlists from multiple platforms.',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Legal & Terms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7))),
                      const SizedBox(height: 12),
                      GlassCard(
                        radius: AppTheme.radiusMd,
                        child: Column(
                          children: [
                            _aboutTile(Icons.info_outline, 'Video Content Terms', () => VideoTermsDialog.show(context)),
                            Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                            _aboutTile(Icons.policy_outlined, 'Platform Policies', () {
                              showDialog(context: context, builder: (_) => const PlatformPoliciesDialog());
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Supported Platforms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7))),
                      const SizedBox(height: 12),
                      GlassCard(
                        radius: AppTheme.radiusMd,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _platformRow('YouTube', 'Full player support'),
                            _platformRow('Vimeo', 'Full player support'),
                            _platformRow('Direct Videos', 'MP4, MOV, WebM'),
                            Divider(height: 16, color: Colors.white.withOpacity(0.06)),
                            _platformRow('Instagram', 'Embed support'),
                            _platformRow('TikTok', 'Embed support'),
                            _platformRow('Twitch', 'Clips only'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 18),
      onTap: onTap,
    );
  }

  Widget _platformRow(String name, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
