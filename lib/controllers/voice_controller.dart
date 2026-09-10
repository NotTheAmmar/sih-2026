import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/constants.dart';
import '../services/audio_service.dart';

enum VoiceState { idle, recording, stopped }

class VoiceController extends ChangeNotifier {
  final AudioService _audioService;

  VoiceController({required AudioService audioService})
      : _audioService = audioService;

  VoiceState _state = VoiceState.idle;
  String? _audioPath;
  int _secondsRemaining = AppConstants.maxRecordingSeconds;
  bool _isSilent = false;
  List<double> _amplitudeHistory = List.filled(30, 0.0);

  Timer? _countdownTimer;
  StreamSubscription<double>? _amplitudeSub;

  VoiceState get state => _state;
  String? get audioPath => _audioPath;
  int get secondsRemaining => _secondsRemaining;
  bool get isSilent => _isSilent;
  List<double> get amplitudeHistory => _amplitudeHistory;
  bool get hasRecording => _audioPath != null;

  Future<void> toggleRecording() async {
    if (_state == VoiceState.idle) {
      await _startRecording();
    } else if (_state == VoiceState.recording) {
      await _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    _state = VoiceState.recording;
    _secondsRemaining = AppConstants.maxRecordingSeconds;
    _isSilent = false;
    _audioPath = null;
    _amplitudeHistory = List.filled(30, 0.0);
    HapticFeedback.mediumImpact();
    notifyListeners();

    final amplitudeStream = await _audioService.startRecording();

    _amplitudeSub = amplitudeStream.listen((dbfs) {
      // Shift amplitude history left and add new value
      // Normalize dBFS (-60..0) to 0..1
      final normalized = ((dbfs + 60) / 60).clamp(0.0, 1.0);
      _amplitudeHistory = [..._amplitudeHistory.skip(1), normalized];

      // Silence detection
      _isSilent = dbfs < AppConstants.silenceAmplitudeThreshold;
      notifyListeners();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _secondsRemaining--;
      notifyListeners();
      if (_secondsRemaining <= 0) {
        await _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    _audioPath = await _audioService.stopRecording();
    _state = VoiceState.stopped;
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void reset() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _state = VoiceState.idle;
    _audioPath = null;
    _secondsRemaining = AppConstants.maxRecordingSeconds;
    _isSilent = false;
    _amplitudeHistory = List.filled(30, 0.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amplitudeSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
