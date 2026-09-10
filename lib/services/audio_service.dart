import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import '../config/constants.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  StreamSubscription<Amplitude>? _amplitudeSub;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  // ── Initialization ──────────────────────────────────────────────────────

  Future<void> initTts() async {
    await _tts.setLanguage('hi-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  // ── Recording ───────────────────────────────────────────────────────────

  /// Start recording. Returns amplitude stream (dBFS).
  Future<Stream<double>> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) throw Exception('Microphone permission denied');

    String? path;
    if (!kIsWeb) {
      final tempDir = await getTemporaryDirectory();
      path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }

    await _recorder.start(
      RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        sampleRate: AppConstants.audioSampleRate,
        numChannels: 1,
      ),
      path: path ?? '',
    );

    _isRecording = true;

    // Stream amplitude in dBFS every 80ms
    final controller = StreamController<double>.broadcast();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amp) {
      if (!controller.isClosed) controller.add(amp.current);
    });

    return controller.stream;
  }

  /// Stop recording. Returns path to the audio file.
  Future<String?> stopRecording() async {
    _isRecording = false;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    final path = await _recorder.stop();
    return path;
  }

  // ── Playback ─────────────────────────────────────────────────────────────

  Future<void> playFile(String path) async {
    final source = kIsWeb ? UrlSource(path) : DeviceFileSource(path);
    await _player.play(source);
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  // ── TTS Readback ─────────────────────────────────────────────────────────

  /// Read back catalog summary in Hindi via TTS.
  Future<void> speakCatalogSummary({
    required String? titleHi,
    required int? fairPrice,
    required String? category,
  }) async {
    await initTts();
    final text = _buildReadbackText(
      titleHi: titleHi,
      fairPrice: fairPrice,
      category: category,
    );
    await _tts.speak(text);
  }

  Future<void> stopTts() async {
    await _tts.stop();
  }

  /// Speak an error / warning prompt in Hindi
  Future<void> speakWarning(String hindiText) async {
    await initTts();
    await _tts.speak(hindiText);
  }

  // ── Disposal ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _amplitudeSub?.cancel();
    await _recorder.dispose();
    await _player.dispose();
    await _tts.stop();
  }

  // ── Private ──────────────────────────────────────────────────────────────

  String _buildReadbackText({
    required String? titleHi,
    required int? fairPrice,
    required String? category,
  }) {
    final parts = <String>[];
    if (category != null) parts.add('यह उत्पाद $category की श्रेणी में है।');
    if (titleHi != null) parts.add(titleHi);
    if (fairPrice != null) {
      parts.add('इसकी अनुशंसित बाज़ार कीमत $fairPrice रुपये है।');
    }
    parts.add('क्या आप इसे ONDC पर प्रकाशित करना चाहते हैं?');
    return parts.join(' ');
  }
}
