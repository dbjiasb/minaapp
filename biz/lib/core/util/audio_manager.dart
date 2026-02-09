import 'package:biz/base/crypt/other.dart';
import 'package:biz/base/crypt/copywriting.dart';
import 'package:biz/base/crypt/security.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:biz/core/util/file_upload.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../shared/toast/toast.dart';

// Audio recording configuration constants
const RecordConfig config = RecordConfig(
  encoder: AudioEncoder.aacLc, // Audio codec
  bitRate: 64000, // Bitrate (64 kbps)
  sampleRate: 44100, // Sample rate (44.1 kHz)
);

class AudioManager {
  // Singleton instance
  static final AudioManager instance = AudioManager._internal()..getTemp();

  factory AudioManager() => instance;

  AudioManager._internal(); // Private constructor

  // Audio file path
  String audioPath = '';

  // Recording state
  bool working = false;

  // Audio recording components
  AudioRecorder? recorder;
  DateTime? beginTime; // Recording start time
  int? recordLength; // Recording duration in milliseconds
  Timer? _recordingTimer; // Timer for max recording duration

  // Maximum recording duration (60 seconds)
  int maxDurationMs = 60000;

  // Temporary file configuration
  final tmpDir = Other.security__chat_audio_;
  final tmpName = Other.security_audio_record_m4a;

  /// Initializes temporary directory and audio file path
  Future getTemp() async {
    // Get system temp directory
    final tempDir = await getTemporaryDirectory();

    // Create recording subdirectory
    final dirPath = path.join(tempDir.path, Security.security_record);
    final outputDir = Directory(dirPath);
    await outputDir.create(recursive: true);

    // Set full audio file path
    final outputPath = path.join(dirPath, Other.security_audio_record_m4a);
    audioPath = outputPath;

    // Delete existing file if present
    try {
      await File(outputPath).delete();
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode != 2) {
        // Ignore "file not found" errors
        // Handle other file system errors if needed
      }
    }
  }

  /// Starts audio recording
  Future begin() async {
    if (audioPath.isEmpty) await getTemp();

    working = true;
    beginTime = DateTime.now();
    recorder = AudioRecorder();

    // Check and request recording permission
    if (await recorder?.hasPermission() == true) {
      // Start recording with predefined config
      await recorder?.start(path: audioPath, config);

      // Set timer for automatic stop after max duration
      _recordingTimer = Timer(
        Duration(milliseconds: maxDurationMs),
        () => finish(), // Auto-finish when timer expires
      );
    } else {
      // Reset state if permission denied
      working = false;
      beginTime = null;
      recorder = null;
    }
  }

  /// Stops recording and uploads audio file
  Future<(String url, int duration)?> finish() async {
    _recordingTimer?.cancel(); // Cancel auto-stop timer

    if (!working) return null; // Exit if not recording

    // Verify recorded file exists
    File src = File(audioPath);
    if (!src.existsSync()) {
      Toast.show(Copywriting.security_failed_to_record_audio__please_try_again);
      return null;
    }

    working = false;

    // Calculate recording duration   ms
    recordLength = DateTime.now().millisecondsSinceEpoch - (beginTime ?? DateTime.now()).millisecondsSinceEpoch;

    await recorder?.stop(); // Stop recording

    // Read and upload audio file
    Uint8List data = await src.readAsBytes();
    String dataUrl = await FilePushService.instance.upload(data, FileType.im, ext: Security.security_m4a) ?? '';

    beginTime = null; // Reset start time
    recorder = null; // Reset recorder

    return (dataUrl, recordLength!);
  }

  /// Cancels current recording
  Future<void> cancel() async {
    if (working) {
      working = false;
      beginTime = null;
      _recordingTimer?.cancel(); // Cancel timer
      await recorder?.stop(); // Stop recording
      recorder = null;
    }
  }
}
