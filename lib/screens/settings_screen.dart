import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/audio_service.dart';
import '../services/game_data.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/common.dart';
import 'webview_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _privacyUrl = 'https://yardflarerally.com/privacy-policy.html';
  static const _supportUrl = 'https://yardflarerally.com/support.html';

  @override
  Widget build(BuildContext context) {
    final data = GameData.instance;
    return Scaffold(
      body: AnimatedBackdrop(
        child: AnimatedBuilder(
          animation: data,
          builder: (context, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      RoundIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      const Text('Settings',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    children: [
                      _toggle('Music', Icons.music_note, data.music, (v) {
                        data.setMusic(v);
                        AudioService.instance.applyMusicSetting();
                      }),
                      _toggle('Sound Effects', Icons.volume_up, data.sound, data.setSound),
                      _toggle('Vibration', Icons.vibration, data.vibration, data.setVibration),
                      const SizedBox(height: 16),
                      const _SectionTitle('Controls'),
                      _controlInfo(),
                      const SizedBox(height: 16),
                      const _SectionTitle('More'),
                      _linkTile('Privacy Policy', Icons.privacy_tip, () {
                        _openWeb(context, 'Privacy Policy', _privacyUrl, forceWhite: true);
                      }),
                      _linkTile('Support', Icons.help_outline, () {
                        _openWeb(context, 'Support', _supportUrl);
                      }),
                      const SizedBox(height: 16),
                      _linkTile('Reset Progress', Icons.delete_forever, () {
                        _confirmReset(context, data);
                      }, danger: true),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text('Yardflare Rally  v1.0.0',
                            style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openWeb(BuildContext context, String title, String url, {bool forceWhite = false}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WebViewScreen(title: title, url: url, forceWhiteBackground: forceWhite),
    ));
  }

  Widget _toggle(String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          Switch(
            value: value,
            activeThumbColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _controlInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.25),
            ),
            child: const Icon(Icons.pan_tool_rounded, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Drag to Move',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Drag anywhere on the screen to steer your chicken.',
                    style: TextStyle(fontSize: 13, color: AppColors.textDim)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkTile(String label, IconData icon, VoidCallback onTap, {bool danger = false}) {
    final color = danger ? AppColors.danger : AppColors.textLight;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: danger ? AppColors.danger : AppColors.accent),
        title: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: onTap,
      ),
    );
  }

  void _confirmReset(BuildContext context, GameData data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Reset Progress?'),
        content: const Text(
          'This permanently deletes all levels, stars, coins, upgrades and skins. This cannot be undone.',
          style: TextStyle(color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await data.resetProgress();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title,
          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 15)),
    );
  }
}
