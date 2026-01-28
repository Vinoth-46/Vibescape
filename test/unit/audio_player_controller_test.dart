import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:offline_music_player/controllers/audio_player_controller.dart';
import 'audio_player_controller_test.mocks.dart';

@GenerateMocks([OnAudioQuery, AudioHandler])
void main() {
  late MockOnAudioQuery mockAudioQuery;
  late MockAudioHandler mockAudioHandler;
  late AudioPlayerController controller;

  setUp(() {
    mockAudioQuery = MockOnAudioQuery();
    mockAudioHandler = MockAudioHandler();
    SharedPreferences.setMockInitialValues({});

    // Stub stream getters for AudioHandler using BehaviorSubject which implements ValueStream
    final mediaItemSubject = BehaviorSubject<MediaItem?>.seeded(null);
    final playbackStateSubject = BehaviorSubject<PlaybackState>.seeded(PlaybackState());
    final queueSubject = BehaviorSubject<List<MediaItem>>.seeded([]);

    when(mockAudioHandler.mediaItem).thenAnswer((_) => mediaItemSubject);
    when(mockAudioHandler.playbackState).thenAnswer((_) => playbackStateSubject);
    when(mockAudioHandler.queue).thenAnswer((_) => queueSubject);
  });

  test('fetchSongs filters songs by duration', () async {
    final songs = [
      SongModel({
        "_id": 1,
        "_data": "/music/short.mp3",
        "title": "Short Song",
        "duration": 10000, // 10s
      }),
      SongModel({
        "_id": 2,
        "_data": "/music/long.mp3",
        "title": "Long Song",
        "duration": 60000, // 60s
      }),
    ];

    when(mockAudioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
      path: null,
    )).thenAnswer((_) async => songs);

    controller = AudioPlayerController(mockAudioHandler, audioQuery: mockAudioQuery);

    // Simulate permission granted
    await controller.onPermissionGranted();

    expect(controller.songs.length, 1);
    expect(controller.songs.first.title, "Long Song");
  });
}
