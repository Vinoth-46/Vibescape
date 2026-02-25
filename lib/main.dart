import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controllers/audio_player_controller.dart';
import 'services/audio_handler.dart';
import 'screens/main_screen.dart';

import 'controllers/settings_controller.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/playlist_controller.dart';
import 'controllers/folder_controller.dart';
import 'controllers/party_controller.dart';
import 'controllers/stream_controller.dart' as stream;
import 'globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
          backgroundColor: const Color(0xFFF5F7FA), // Soft white background
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 80, color: const Color(0xFF007AFF)), // Premium Blue
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Color(0xFF007AFF)),
                const SizedBox(height: 16),
                Text(
                  "Loading Vibescape...",
                  style: TextStyle(color: Colors.black54, fontSize: 16),
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
        ChangeNotifierProxyProvider<AudioPlayerController, PartyController>(
          create: (context) => PartyController(Provider.of<AudioPlayerController>(context, listen: false)),
          update: (context, audioPlayer, previous) => previous ?? PartyController(audioPlayer),
        ),
        ChangeNotifierProvider(create: (_) => stream.StreamController()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, child) {
          return MaterialApp(
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            locale: DevicePreview.locale(context),
            builder: DevicePreview.appBuilder,
            title: 'Vibescape',
            debugShowCheckedModeBanner: false,
            // Enforce single theme (Light White/Blue) for premium look as requested
            themeMode: settings.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF007AFF), // Apple-like primary blue
                primary: const Color(0xFF007AFF),
                surface: const Color(0xFFFFFFFF),
                background: const Color(0xFFF2F4F8), // Soft premium background
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF2F4F8),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.black87),
                titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
                bodyColor: Colors.black87,
                displayColor: Colors.black87,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF007AFF),
                primary: const Color(0xFF007AFF),
                surface: const Color(0xFF1A1C29),
                background: const Color(0xFF0F1016),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF0F1016),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
            ),
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
