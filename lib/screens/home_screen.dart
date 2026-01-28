import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../controllers/audio_player_controller.dart';
import '../services/permission_service.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndLoad();
    });
  }

  Future<void> _checkAndLoad() async {
    final hasPermission = await _permissionService.hasPermissions();
    if (hasPermission && mounted) {
      context.read<AudioPlayerController>().onPermissionGranted();
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _permissionService.requestPermissions();
    if (granted && mounted) {
      context.read<AudioPlayerController>().onPermissionGranted();
    } else {
      // If denied permanently, open settings (optional, logic inside service?)
      // The UI button usually handles the "Try Again" flow.
      if (!await _permissionService.hasPermissions()) {
        // Optional: Show snackbar or dialog if needed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Permissions are required to play music.")));
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User came back to app, re-check permissions
      _checkAndLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AudioPlayerController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Library"),
        centerTitle: true,
      ),
      body: !controller.hasPermission
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 80, color: Colors.teal),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "We need storage permission to access your music.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _requestPermissions, // Use local method
                    icon: const Icon(Icons.security),
                    label: const Text("Grant Permission"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  TextButton(
                      onPressed: () => _permissionService.openSettings(),
                      child: const Text("Open Settings"))
                ],
              ),
            )
          : controller.songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_off, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        "No Music Found",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Try changing the duration filter in Settings",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<AudioPlayerController>()
                              .refreshLibrary();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Refresh Library"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: controller.songs.length,
                  itemBuilder: (context, index) {
                    SongModel song = controller.songs[index];
                    return ListTile(
                      title: Text(song.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle:
                          Text(song.artist ?? "Unknown Artist", maxLines: 1),
                      trailing: const Icon(Icons.play_arrow_rounded),
                      leading: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget:
                            const Icon(Icons.music_note, size: 32),
                      ),
                      onTap: () {
                        controller.playPlaylist(controller.songs, index);
                        // Navigate to Player Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PlayerScreen()),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
