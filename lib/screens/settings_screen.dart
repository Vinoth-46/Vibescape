import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/settings_controller.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/playlist_controller.dart';
import '../controllers/folder_controller.dart';
import '../widgets/glass_container.dart';
import '../services/cache_service.dart';
import '../services/folder_selection_service.dart';
import '../services/app_update_service.dart';
import 'report_issue_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CacheService _cacheService = CacheService();
  String _cacheSize = "Calculating...";
  String _appVersion = "...";
  bool _checkingUpdate = false;
  AppRelease? _availableUpdate;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final version = await AppUpdateService.getCurrentVersion();
    if (mounted) setState(() => _appVersion = version);
  }

  Future<void> _checkForUpdate() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    final update = await AppUpdateService.checkForUpdate();
    if (mounted) {
      setState(() {
        _checkingUpdate = false;
        _availableUpdate = update;
      });
      if (update != null) {
        AppUpdateService.showUpdateDialog(context, update);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You're on the latest version! 🎉"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadCacheSize() async {
    final size = await _cacheService.getCacheSize();
    if (mounted) {
      setState(() {
        _cacheSize = _cacheService.formatCacheSize(size);
      });
    }
  }

  Future<void> _clearCache() async {
    await _cacheService.clearCache();
    await _loadCacheSize();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Audio cache cleared")),
      );
    }
  }

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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Futuristic Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          const Color(0xFF1A1C29),
                          const Color(0xFF0F1016),
                          const Color(0xFF001A33).withOpacity(0.5),
                        ]
                      : [
                          const Color(0xFFF2F6FA),
                          const Color(0xFFE8F0F8),
                          const Color(0xFFD1E3F6).withOpacity(0.5),
                        ],
                ),
              ),
            ),
          ),
          // Glow Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      title: const Text(
                        'Preferences',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            fontSize: 28),
                      ),
                      background: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      // PROFILE / CREATOR HEADER
                      _buildCreatorPremiumCard(context),
                      const SizedBox(height: 32),

                      // APPEARANCE
                      _buildSectionTitle("Appearance"),
                      _buildGlassGroup([
                        _buildSettingsTile(
                          context,
                          icon: Icons.brightness_auto_rounded,
                          title: "Dark Mode",
                          subtitle: "Switch app theme",
                          trailing: CupertinoSwitch(
                            activeColor: const Color(0xFF007AFF),
                            value: settings.themeMode == ThemeMode.dark,
                            onChanged: (_) => settings.toggleTheme(),
                          ),
                          onTap: settings.toggleTheme,
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // AUDIO & PLAYBACK (PRO)
                      _buildSectionTitle("Playback Engine"),
                      _buildGlassGroup([
                        _buildSettingsTile(
                          context,
                          icon: Icons.hd_rounded,
                          title: "Streaming Quality",
                          subtitle: settings.streamingQuality,
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          onTap: () => _showStreamingQualityPicker(context, settings),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.linear_scale_rounded,
                          title: "Gapless Playback",
                          subtitle: "Eliminate silence between tracks",
                          trailing: CupertinoSwitch(
                            activeColor: const Color(0xFF007AFF),
                            value: settings.gaplessPlayback,
                            onChanged: (_) => settings.toggleGaplessPlayback(),
                          ),
                          onTap: settings.toggleGaplessPlayback,
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.graphic_eq_rounded,
                          title: "Audio Normalization",
                          subtitle: "Equalize track volume",
                          trailing: CupertinoSwitch(
                            activeColor: const Color(0xFF007AFF),
                            value: settings.normalizeAudio,
                            onChanged: (_) => settings.toggleNormalizeAudio(),
                          ),
                          onTap: settings.toggleNormalizeAudio,
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // MUSIC LIBRARY
                      _buildSectionTitle("Local Library"),
                      _buildGlassGroup([
                        _buildSettingsTile(
                          context,
                          icon: Icons.folder_open_rounded,
                          title: "Sync Folders",
                          subtitle: "Select directories to scan",
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          onTap: () => _showFolderSelectionDialog(context, audioController),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.radar_rounded,
                          title: "Rescan Library",
                          subtitle: "Force deep scan for new music",
                          trailing: const Icon(Icons.autorenew_rounded, color: Color(0xFF007AFF)),
                          onTap: () async {
                            await audioController.refreshLibrary();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Library successfully indexed"),
                                    behavior: SnackBarBehavior.floating),
                              );
                            }
                          },
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.timer_outlined,
                          title: "Filter Short Clips",
                          subtitle: "Hide < ${_formatDuration(settings.minDuration)} tracks",
                          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          onTap: () => _showDurationPicker(context, settings, audioController),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // DATA MANAGEMENT
                      _buildSectionTitle("Data Management"),
                      _buildGlassGroup([
                        _buildSettingsTile(
                          context,
                          icon: Icons.cleaning_services_rounded,
                          title: "Clear Audio Cache",
                          subtitle: "Free up $_cacheSize of downloaded streams",
                          isDestructive: true,
                          onTap: () => _showConfirmationDialog(
                              context, "Clear Cache?", "This will remove all downloaded stream files.", _clearCache),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.heart_broken_rounded,
                          title: "Clear Favorites",
                          subtitle: "Erase favorite registry",
                          isDestructive: true,
                          onTap: () => _showConfirmationDialog(
                              context, "Clear Favorites?", "This action cannot be undone.", () {
                            favoritesController.clearFavorites();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Favorites cleared")));
                          }),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.layers_clear_rounded,
                          title: "Flush Playlists",
                          subtitle: "Delete all custom collections",
                          isDestructive: true,
                          onTap: () => _showConfirmationDialog(
                              context, "Flush Playlists?", "Wipe all your saved playlists permanently?", () {
                            playlistController.clearAllPlaylists();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Playlists purged")));
                          }),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // SUPPORT
                      _buildSectionTitle("System"),
                      _buildGlassGroup([
                        _buildSettingsTile(
                          context,
                          icon: Icons.bug_report_rounded,
                          title: "Diagnostic & Bug Report",
                          subtitle: "Help us improve",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
                          ),
                        ),
                        _buildDivider(),
                        _buildSettingsTile(
                          context,
                          icon: Icons.system_update_rounded,
                          title: "Check for Updates",
                          subtitle: "Current: v$_appVersion",
                          trailing: _checkingUpdate
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Color(0xFF007AFF)),
                                  ),
                                )
                              : _availableUpdate != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF007AFF), Color(0xFF00D4FF)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "v${_availableUpdate!.version}",
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF007AFF).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "CHECK",
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF007AFF)),
                                      ),
                                    ),
                          onTap: _checkForUpdate,
                        ),
                      ]),
                      const SizedBox(height: 48),

                      // FOOTER
                      _buildAppInfoCard(context),
                      const SizedBox(height: 40),
                      const Center(
                        child: Text(
                          "DESIGNED IN 2026\nFOR THE FUTURE OF MUSIC",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey,
                              letterSpacing: 2,
                              fontSize: 10,
                              height: 1.5,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 120), // Bottom padding for navbar
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassGroup(List<Widget> children) {
    return GlassContainer(
      blur: 25,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withOpacity(0.15),
      indent: 56,
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24), // Ensure corners don't clip ripple
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.redAccent.withOpacity(0.1)
                      : const Color(0xFF007AFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDestructive ? Colors.redAccent : const Color(0xFF007AFF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? Colors.redAccent : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorPremiumCard(BuildContext context) {
    return GlassContainer(
      blur: 30,
      opacity: 0.15,
      color: const Color(0xFF007AFF).withOpacity(0.05),
      border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.2), width: 1.5),
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF6B00FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Center(
                  child: Text("V",
                      style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Vinoth",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text("App Developer",
                        style: TextStyle(
                            color: const Color(0xFF007AFF).withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Pushing the boundaries of mobile design in 2026. Vibescape is a masterclass in aesthetics and performance.",
            style: TextStyle(color: Colors.grey, height: 1.6, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialPill(
                icon: Icons.alternate_email_rounded,
                label: "Email",
                onTap: () async => await launchUrl(Uri(
                  scheme: 'mailto',
                  path: 'vinothuser7@gmail.com',
                )),
              ),
              _buildSocialPill(
                icon: FontAwesomeIcons.github,
                label: "GitHub",
                onTap: () async => await launchUrl(
                    Uri.parse("https://github.com/Vinoth-46"),
                    mode: LaunchMode.externalApplication),
              ),
              _buildSocialPill(
                icon: FontAwesomeIcons.linkedinIn,
                label: "Connect",
                onTap: () async => await launchUrl(
                    Uri.parse("https://www.linkedin.com/in/vinoth465/"),
                    mode: LaunchMode.externalApplication),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialPill({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF007AFF)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return GlassContainer(
      blur: 20,
      opacity: 0.05,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF007AFF), size: 36),
          ),
          const SizedBox(height: 16),
          const Text("Vibescape Engine",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "Next-generation audio decoding & glassmorphism rendering technology. Built for the modern era of listening.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    int seconds = ms ~/ 1000;
    if (seconds >= 60) return "${seconds ~/ 60}m";
    return "${seconds}s";
  }

  void _showStreamingQualityPicker(BuildContext context, SettingsController settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text("Streaming Quality", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildQualityTile(ctx, settings, "Best (Wi-Fi only)", "Super high bitrate audio"),
              _buildQualityTile(ctx, settings, "High", "320kbps clear audio"),
              _buildQualityTile(ctx, settings, "Normal", "128kbps standard"),
              _buildQualityTile(ctx, settings, "Data Saver", "64kbps low bandwidth"),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
    );
  }

  Widget _buildQualityTile(BuildContext context, SettingsController settings, String title, String subtitle) {
    final isSelected = settings.streamingQuality == title;
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF007AFF)) : null,
      onTap: () {
        settings.setStreamingQuality(title);
        Navigator.pop(context);
      },
    );
  }

  void _showDurationPicker(BuildContext context, SettingsController settings,
      AudioPlayerController audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text("Filter Short Audios", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFilterTile(ctx, settings, audio, "30 Seconds", 30000),
              _buildFilterTile(ctx, settings, audio, "1 Minute", 60000),
              _buildFilterTile(ctx, settings, audio, "2 Minutes", 120000),
              _buildFilterTile(ctx, settings, audio, "3 Minutes", 180000),
              _buildFilterTile(ctx, settings, audio, "5 Minutes", 300000),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
    );
  }

  Widget _buildFilterTile(BuildContext context, SettingsController settings, AudioPlayerController audio, String title, int ms) {
    final isSelected = settings.minDuration == ms;
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF007AFF)) : null,
      onTap: () {
        settings.setMinDuration(ms);
        audio.refreshLibrary(minDuration: ms);
        Navigator.pop(context);
      }
    );
  }

  void _showConfirmationDialog(BuildContext context, String title,
      String content, VoidCallback onConfirm) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showFolderSelectionDialog(BuildContext context, AudioPlayerController audioController) {
    final folderController = FolderController();
    final folderSelectionService = FolderSelectionService();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Folders",
      pageBuilder: (ctx, anim1, anim2) {
        return _FolderSelectionDialog(
          folderController: folderController,
          folderSelectionService: folderSelectionService,
          onSave: () async {
            await audioController.refreshLibrary();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Library Resynced"), behavior: SnackBarBehavior.floating),
              );
            }
          },
        );
      }
    );
  }
}

/// Dialog for selecting which folders to include in music library
class _FolderSelectionDialog extends StatefulWidget {
  final FolderController folderController;
  final FolderSelectionService folderSelectionService;
  final VoidCallback onSave;

  const _FolderSelectionDialog({
    required this.folderController,
    required this.folderSelectionService,
    required this.onSave,
  });

  @override
  State<_FolderSelectionDialog> createState() => _FolderSelectionDialogState();
}

class _FolderSelectionDialogState extends State<_FolderSelectionDialog> {
  List<String> _allFolders = [];
  Set<String> _selectedFolders = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    await widget.folderController.fetchFolders();
    _allFolders = widget.folderController.folderPaths;
    final selected = await widget.folderSelectionService.getSelectedFolders();
    
    setState(() {
      _selectedFolders = selected.toSet();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassContainer(
            height: 500,
            borderRadius: BorderRadius.circular(32),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Sync Folders", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _selectedFolders.isEmpty
                      ? "Scanning global device storage"
                      : "${_selectedFolders.length} specific directories selected",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CupertinoActivityIndicator(radius: 16))
                      : _allFolders.isEmpty
                          ? const Center(
                              child: Text(
                                "No folders detected.\nGrant storage permission.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _allFolders.length,
                              itemBuilder: (ctx, index) {
                                final folderPath = _allFolders[index];
                                final folderName = widget.folderController.getFolderName(folderPath);
                                final isSelected = _selectedFolders.contains(folderPath);
                                final songCount = widget.folderController.getSongsInFolder(folderPath).length;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF007AFF).withOpacity(0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedFolders.add(folderPath);
                                        } else {
                                          _selectedFolders.remove(folderPath);
                                        }
                                      });
                                    },
                                    title: Text(folderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Text(
                                      folderPath,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                    secondary: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF007AFF).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "$songCount",
                                        style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    activeColor: const Color(0xFF007AFF),
                                    checkColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () async {
                        await widget.folderSelectionService.saveSelectedFolders(_selectedFolders.toList());
                        if (context.mounted) {
                          Navigator.pop(context);
                          widget.onSave();
                        }
                      },
                      child: const Text("Apply Details", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
