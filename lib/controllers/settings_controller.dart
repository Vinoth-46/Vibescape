import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_player_controller.dart';

class SettingsController extends ChangeNotifier {
  static const String _keyTheme = 'theme_mode';
  static const String _keyMinDuration = 'min_duration';
  static const String _keyStreamingQuality = 'streaming_quality';
  static const String _keyGaplessPlayback = 'gapless_playback';
  static const String _keyNormalizeAudio = 'normalize_audio';

  ThemeMode _themeMode = ThemeMode.system;
  int _minDuration = 120000; // Default 2 minutes (in ms)
  String _streamingQuality = 'High';
  bool _gaplessPlayback = true;
  bool _normalizeAudio = false;

  ThemeMode get themeMode => _themeMode;
  int get minDuration => _minDuration;
  String get streamingQuality => _streamingQuality;
  bool get gaplessPlayback => _gaplessPlayback;
  bool get normalizeAudio => _normalizeAudio;

  SettingsController() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeIndex = prefs.getInt(_keyTheme);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // Load Min Duration
    _minDuration = prefs.getInt(_keyMinDuration) ?? 120000;
    
    // Load Premium Settings
    _streamingQuality = prefs.getString(_keyStreamingQuality) ?? 'High';
    _gaplessPlayback = prefs.getBool(_keyGaplessPlayback) ?? true;
    _normalizeAudio = prefs.getBool(_keyNormalizeAudio) ?? false;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, mode.index);
    notifyListeners();
  }

  Future<void> setMinDuration(int ms) async {
    _minDuration = ms;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMinDuration, ms);
    notifyListeners();
  }

  Future<void> setStreamingQuality(String quality) async {
    _streamingQuality = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStreamingQuality, quality);
    notifyListeners();
  }

  Future<void> toggleGaplessPlayback() async {
    _gaplessPlayback = !_gaplessPlayback;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGaplessPlayback, _gaplessPlayback);
    notifyListeners();
  }

  Future<void> toggleNormalizeAudio() async {
    _normalizeAudio = !_normalizeAudio;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNormalizeAudio, _normalizeAudio);
    notifyListeners();
  }

  // Helper to trigger refresh via context
  Future<void> refreshLibrary(BuildContext context) async {
    final controller =
        Provider.of<AudioPlayerController>(context, listen: false);
    await controller.refreshLibrary(
        minDuration: _minDuration); // Pass minDuration in ms
  }

  // Toggle between generic themes for the switch
  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
