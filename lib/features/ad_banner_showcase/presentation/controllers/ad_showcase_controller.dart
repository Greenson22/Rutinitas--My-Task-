import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdShowcaseController extends ChangeNotifier {
  static const String prefKeyInterval = 'ad_showcase_refresh_interval_seconds';
  static const int defaultIntervalSeconds = 60;
  static const int minIntervalSeconds = 30;
  static const int maxIntervalSeconds = 300;

  int _refreshKey = 0;
  int _intervalSeconds = defaultIntervalSeconds;
  int _secondsUntilNextRefresh = defaultIntervalSeconds;

  Timer? _countdownTimer;
  bool _isDisposed = false;

  AdShowcaseController({int? initialInterval}) {
    if (initialInterval != null) {
      _intervalSeconds = _clampInterval(initialInterval);
      _secondsUntilNextRefresh = _intervalSeconds;
    }
  }

  int get refreshKey => _refreshKey;
  int get intervalSeconds => _intervalSeconds;
  int get secondsUntilNextRefresh => _secondsUntilNextRefresh;

  static int _clampInterval(int seconds) {
    if (seconds < minIntervalSeconds) return minIntervalSeconds;
    if (seconds > maxIntervalSeconds) return maxIntervalSeconds;
    return seconds;
  }

  /// Inisialisasi controller: baca nilai dari SharedPreferences lalu jalankan timer.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedInterval = prefs.getInt(prefKeyInterval);
    if (savedInterval != null) {
      _intervalSeconds = _clampInterval(savedInterval);
    } else {
      _intervalSeconds = defaultIntervalSeconds;
    }
    _secondsUntilNextRefresh = _intervalSeconds;
    _startTimers();
    notifyListeners();
  }

  /// Memulai countdown timer tiap detik.
  void _startTimers() {
    _countdownTimer?.cancel();
    if (_isDisposed) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsUntilNextRefresh > 1) {
        _secondsUntilNextRefresh--;
        notifyListeners();
      } else {
        // Waktu refresh tiba
        _refreshKey++;
        _secondsUntilNextRefresh = _intervalSeconds;
        notifyListeners();
      }
    });
  }

  /// Mengatur interval baru, mengklem nilai 30-300, menyimpan ke SharedPreferences, dan mereset timer.
  Future<void> setInterval(int seconds) async {
    final clamped = _clampInterval(seconds);
    _intervalSeconds = clamped;
    _secondsUntilNextRefresh = clamped;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefKeyInterval, clamped);

    _startTimers();
    notifyListeners();
  }

  /// Memicu refresh segera tanpa menunggu timer, menaikkan refreshKey, dan mereset countdown.
  void triggerManualRefresh() {
    _refreshKey++;
    _secondsUntilNextRefresh = _intervalSeconds;
    _startTimers();
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    super.dispose();
  }
}
