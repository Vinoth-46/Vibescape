import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_service/audio_service.dart';
import 'controllers/audio_player_controller.dart';
import 'services/audio_handler.dart';
import 'screens/main_screen.dart';

import 'controllers/settings_controller.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/playlist_controller.dart';
import 'controllers/folder_controller.dart';
import 'globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only use DevicePreview in debug mode on desktop/web for testing
  // Completely bypass it on mobile devices to avoid crashes
  if (kDebugMode && !kIsWeb) {
    runApp(
      DevicePreview(
        enabled: false, // Disabled to prevent crashes on real devices
        builder: (context) => const MyApp(),
      ),
    );
  } else {
    runApp(const MyApp());
  }
}

// Check if running on web
const bool kIsWeb = identical(0, 0.0);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AudioHandler? _audioHandler;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAudioService();
  }

  Future<void> _initAudioService() async {
    try {
      final handler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId:
              'com.example.offline_music_player.channel.audio',
          androidNotificationChannelName: 'Music Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'drawable/ic_notification',
        ),
      );
      if (mounted) {
        setState(() {
          _audioHandler = handler;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("MyApp: AudioService.init failed: $e");
      if (mounted) {
        setState(() {
          _isInitialized = true; // Still mark as initialized so UI proceeds
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 80, color: Colors.teal.shade300),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.teal),
                const SizedBox(height: 16),
                Text(
                  "Loading Music Player...",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioPlayerController>(
          create: (context) => _audioHandler != null
              ? AudioPlayerController(_audioHandler!)
              : AudioPlayerController.dummy(),
        ),
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => FavoritesController()),
        ChangeNotifierProvider(create: (_) => PlaylistController()),
        ChangeNotifierProvider(create: (_) => FolderController()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, child) {
          return MaterialApp(
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            locale: DevicePreview.locale(context),
            builder: DevicePreview.appBuilder,
            title: 'ISAI',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: Colors.white,
              textTheme:
                  GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.dark,
                primary: Colors.teal,
                surface: Colors.black,
              ),
              scaffoldBackgroundColor: Colors.black,
              textTheme:
                  GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
            ),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
