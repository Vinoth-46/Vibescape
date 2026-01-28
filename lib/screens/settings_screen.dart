import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/settings_controller.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/playlist_controller.dart';
import 'report_issue_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access providers
    final settings = Provider.of<SettingsController>(context);
    final audioController =
        Provider.of<AudioPlayerController>(context, listen: false);
    final favoritesController =
        Provider.of<FavoritesController>(context, listen: false);
    final playlistController =
        Provider.of<PlaylistController>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, "Appearance"),
          _buildSettingsTile(
            context,
            icon: Icons.smartphone,
            title: "Theme",
            subtitle: _getThemeName(settings.themeMode),
            onTap: () {
              settings.toggleTheme();
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Music Library"),
          _buildSettingsTile(
            context,
            icon: Icons.folder_open,
            title: "Rescan Library",
            subtitle: "Scan for new music files",
            onTap: () async {
              await audioController.refreshLibrary();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Library rescanned")),
                );
              }
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.access_time,
            title: "Minimum Song Duration",
            subtitle: "Filter out short audio files",
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatDuration(settings.minDuration),
                    style: const TextStyle(color: Colors.teal)),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
            onTap: () =>
                _showDurationPicker(context, settings, audioController),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Library Management"),
          _buildSettingsTile(
            context,
            icon: Icons.favorite_border,
            title: "Clear Favorites",
            subtitle: "Remove all favorite songs",
            onTap: () {
              _showConfirmationDialog(context, "Clear Favorites?",
                  "This will remove all songs from your favorites.", () {
                favoritesController.clearFavorites();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Favorites cleared")),
                );
              });
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.playlist_remove,
            title: "Clear All Playlists",
            subtitle: "Delete all custom playlists",
            onTap: () {
              _showConfirmationDialog(context, "Delete Playlists?",
                  "This will delete all your custom playlists.", () {
                playlistController.clearAllPlaylists();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Playlists deleted")),
                );
              });
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Support & Feedback"),
          _buildSettingsTile(
            context,
            icon: Icons.bug_report,
            title: "Report an Issue",
            subtitle: "Found a bug? Report me to Fix it ! ",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "About App"),
          const SizedBox(height: 8),
          _buildAppInfoCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Creator"),
          const SizedBox(height: 8),
          _buildCreatorCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "App Information"),
          const SizedBox(height: 8),
          _buildInfoTile(context),
          const SizedBox(height: 40),
          const Center(
            child: Text(
              "Made with ❤️ by Vinoth",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    if (mode == ThemeMode.system) return "System Default";
    if (mode == ThemeMode.dark) return "Dark Mode";
    return "Light Mode";
  }

  String _formatDuration(int ms) {
    int seconds = ms ~/ 1000;
    if (seconds >= 60) {
      return "${seconds ~/ 60} min";
    }
    return "$seconds sec";
  }

  void _showDurationPicker(BuildContext context, SettingsController settings,
      AudioPlayerController audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                title: const Text("30 Seconds"),
                onTap: () {
                  _updateDuration(context, settings, audio, 30000);
                }),
            ListTile(
                title: const Text("1 Minute"),
                onTap: () {
                  _updateDuration(context, settings, audio, 60000);
                }),
            ListTile(
                title: const Text("2 Minutes"),
                onTap: () {
                  _updateDuration(context, settings, audio, 120000);
                }),
            ListTile(
                title: const Text("3 Minutes"),
                onTap: () {
                  _updateDuration(context, settings, audio, 180000);
                }),
            ListTile(
                title: const Text("5 Minutes"),
                onTap: () {
                  _updateDuration(context, settings, audio, 300000);
                }),
          ],
        );
      },
    );
  }

  void _updateDuration(BuildContext context, SettingsController settings,
      AudioPlayerController audio, int ms) {
    // Settings controller expects ms now
    settings.setMinDuration(ms);
    // Audio controller expects ms
    audio.refreshLibrary(minDuration: ms);
    Navigator.pop(context);
  }

  void _showConfirmationDialog(BuildContext context, String title,
      String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(ctx);
              },
              child:
                  const Text("Confirm", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.1), // Dynamic card bg
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.music_note, color: Colors.teal, size: 32),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Music Player",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Your Personal Music Experience",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "A beautiful, feature-rich music player designed for music lovers. Enjoy your local music library with intuitive controls, custom playlists, and a sleek interface that adapts to your style.",
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildFeatureCheck("Local music library access"),
          _buildFeatureCheck("Folder-based music organization"),
          _buildFeatureCheck("Custom playlist creation"),
          _buildFeatureCheck("Dynamic theme support"),
        ],
      ),
    );
  }

  Widget _buildFeatureCheck(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.teal, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCreatorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.teal,
                child: Text("V",
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Vinoth",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const SizedBox(height: 4),
                    Text("App Developer",
                        style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Passionate Flutter developer creating high-quality mobile experiences. Connect with me for feedback or opportunities.",
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 20),
          _buildSocialIconsRow(context),
        ],
      ),
    );
  }

  Widget _buildSocialIconsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialIcon(
          context,
          icon: Icons.email,
          onTap: () async {
            final Uri emailLaunchUri = Uri(
              scheme: 'mailto',
              path: 'vinothuser7@gmail.com',
              query: 'subject=Music Player App Feedback',
            );
            await launchUrl(emailLaunchUri);
          },
        ),
        _buildSocialIcon(
          context,
          icon: FontAwesomeIcons.github, // Authentic GitHub
          onTap: () async {
            final Uri url = Uri.parse("https://github.com/Vinoth-46");
            await launchUrl(url, mode: LaunchMode.externalApplication);
          },
        ),
        _buildSocialIcon(
          context,
          icon: FontAwesomeIcons.linkedin, // Authentic LinkedIn
          onTap: () async {
            final Uri url = Uri.parse("https://www.linkedin.com/in/vinoth465/");
            await launchUrl(url, mode: LaunchMode.externalApplication);
          },
        ),
        _buildSocialIcon(
          context,
          icon: FontAwesomeIcons.instagram, // Authentic Instagram
          onTap: () async {
            final Uri url = Uri.parse("https://www.instagram.com/ft_vinoth");
            await launchUrl(url, mode: LaunchMode.externalApplication);
          },
        ),
      ],
    );
  }

  Widget _buildSocialIcon(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.teal.withOpacity(0.5)),
        ),
        child: Icon(icon, color: Colors.teal, size: 24),
      ),
    );
  }



  Widget _buildInfoTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.teal),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Version", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("1.0.0 (Production Ready)",
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
