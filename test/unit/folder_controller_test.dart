import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:vibescape/controllers/folder_controller.dart';
import 'package:vibescape/services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'folder_controller_test.mocks.dart';

@GenerateMocks([OnAudioQuery, PermissionService])
void main() {
  late MockOnAudioQuery mockAudioQuery;
  late MockPermissionService mockPermissionService;
  late FolderController folderController;

  setUp(() async {
    // Ensure binding is initialized for SharedPreferences
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    mockAudioQuery = MockOnAudioQuery();
    mockPermissionService = MockPermissionService();

    // Default stub to avoid MissingStubError during instantiation
    when(mockAudioQuery.querySongs(
      sortType: anyNamed('sortType'),
      orderType: anyNamed('orderType'),
      uriType: anyNamed('uriType'),
      ignoreCase: anyNamed('ignoreCase'),
      path: anyNamed('path'),
    )).thenAnswer((_) async => []);

    // Default stub for permissions
    when(mockPermissionService.hasPermissions()).thenAnswer((_) async => true);
  });

  test('fetchFolders groups songs by folder', () async {
    // Setup mock data
    final songs = [
      SongModel({
        "_id": 1,
        "_data": "/storage/emulated/0/Music/Song1.mp3",
        "title": "Song 1",
        "artist": "Artist 1",
        "duration": 100000,
      }),
      SongModel({
        "_id": 2,
        "_data": "/storage/emulated/0/Music/Song2.mp3",
        "title": "Song 2",
        "artist": "Artist 1",
        "duration": 200000,
      }),
      SongModel({
        "_id": 3,
        "_data": "/storage/emulated/0/Downloads/Song3.mp3",
        "title": "Song 3",
        "artist": "Artist 2",
        "duration": 150000,
      }),
    ];

    when(mockAudioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
      path: null,
    )).thenAnswer((_) async => songs);

    folderController = FolderController(
      audioQuery: mockAudioQuery,
      permissionService: mockPermissionService,
    );

    // Simulate permission granted to trigger fetchFolders
    await folderController.onPermissionGranted();

    expect(folderController.folderPaths.length, 2);
    expect(folderController.folderPaths, contains("/storage/emulated/0/Music"));
    expect(folderController.folderPaths, contains("/storage/emulated/0/Downloads"));

    expect(folderController.getSongsInFolder("/storage/emulated/0/Music").length, 2);
    expect(folderController.getSongsInFolder("/storage/emulated/0/Downloads").length, 1);
  });

  test('getFolderName extracts name correctly (Unix)', () async {
    folderController = FolderController(
      audioQuery: mockAudioQuery,
      permissionService: mockPermissionService,
    );
    expect(folderController.getFolderName("/storage/emulated/0/Music"), "Music");
  });
}
