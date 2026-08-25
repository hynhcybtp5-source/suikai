import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'cake_game_models.dart';

class CakeGameController extends ChangeNotifier {
  static const gameDuration = Duration(seconds: 45);
  static const initialCake = 20;
  final Random _random;
  Timer? _clock;
  Timer? _phaseTimer;
  final Map<int, DateTime> _violations = {};
  late List<CakePlayer> players;
  CakeGamePhase phase = CakeGamePhase.waiting;
  int cakeRemaining = initialCake;
  Duration remaining = gameDuration;
  bool soundEnabled = true;
  int actionTick = 0;
  int? lastScoringPlayer;
  int? lastEliminatedPlayer;
  int? lastShotPlayer;
  DateTime? _lastEatAt;

  CakeGameController({Random? random}) : _random = random ?? Random() {
    restart();
  }

  bool get isRunning =>
      phase != CakeGamePhase.waiting && phase != CakeGamePhase.gameOver;
  List<CakePlayer> get ranking =>
      [...players]..sort((a, b) => b.score.compareTo(a.score));
  int get aliveCount => players.where((p) => !p.eliminated).length;
  String get bossMessage => switch (phase) {
    CakeGamePhase.waiting => 'พร้อมเริ่มเกม',
    CakeGamePhase.bossReading => 'ปลอดภัย: บอสกำลังอ่านข่าว',
    CakeGamePhase.bossWarning => 'ระวัง: บอสกำลังจะหันมา!',
    CakeGamePhase.bossWatching => 'อันตราย: บอสกำลังมอง!',
    CakeGamePhase.playerEliminated => 'บอสยิงคนที่ขยับ!',
    CakeGamePhase.gameOver => 'จบเกม!',
  };

  void restart() {
    _clock?.cancel();
    _phaseTimer?.cancel();
    _violations.clear();
    players = [
      CakePlayer(id: 1, color: Colors.blue),
      CakePlayer(id: 2, color: Colors.amber.shade700),
      CakePlayer(id: 3, color: Colors.green),
      CakePlayer(id: 4, color: Colors.pink),
    ];
    cakeRemaining = initialCake;
    remaining = gameDuration;
    _lastEatAt = null;
    actionTick = 0;
    lastScoringPlayer = null;
    lastEliminatedPlayer = null;
    lastShotPlayer = null;
    phase = CakeGamePhase.waiting;
    notifyListeners();
  }

  void start() {
    if (isRunning) return;
    remaining = gameDuration;
    cakeRemaining = initialCake;
    phase = CakeGamePhase.bossReading;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      remaining -= const Duration(seconds: 1);
      if (remaining <= Duration.zero) {
        _finish();
      } else {
        notifyListeners();
      }
    });
    notifyListeners();
    _scheduleReading();
  }

  void tapPlayer(int id, [DateTime? now]) {
    final player = players.firstWhere((p) => p.id == id);
    if (!isRunning || player.eliminated) return;
    final at = now ?? DateTime.now();
    player.lastInputAt = at;
    if (phase == CakeGamePhase.bossWatching ||
        phase == CakeGamePhase.bossWarning) {
      _violations[id] = at;
      notifyListeners();
      return;
    }
    if (phase != CakeGamePhase.bossReading || cakeRemaining == 0) return;
    if (_lastEatAt != null &&
        at.difference(_lastEatAt!) < const Duration(milliseconds: 180)) {
      return;
    }
    _lastEatAt = at;
    player.score++;
    cakeRemaining--;
    lastScoringPlayer = id;
    actionTick++;
    if (cakeRemaining == 0) {
      _finish();
    } else {
      notifyListeners();
    }
  }

  void _scheduleReading() {
    _phaseTimer?.cancel();
    _phaseTimer = Timer(Duration(seconds: 4 + _random.nextInt(7)), () {
      if (!isRunning) return;
      phase = CakeGamePhase.bossWarning;
      notifyListeners();
      _phaseTimer = Timer(
        Duration(milliseconds: 100 + _random.nextInt(151)),
        _watch,
      );
    });
  }

  void _watch() {
    if (!isRunning) return;
    phase = CakeGamePhase.bossWatching;
    _violations.clear();
    notifyListeners();
    _phaseTimer = Timer(
      Duration(milliseconds: 600 + _random.nextInt(401)),
      _resolveWatch,
    );
  }

  void _resolveWatch() {
    if (!isRunning) return;
    CakePlayer? caught;
    for (final entry in _violations.entries) {
      final candidate = players.firstWhere((p) => p.id == entry.key);
      if (caught == null || entry.value.isAfter(caught.lastInputAt!)) {
        caught = candidate;
      }
    }
    if (caught != null) {
      caught.eliminated = true;
      lastEliminatedPlayer = caught.id;
      lastShotPlayer = caught.id;
      actionTick++;
    }
    _violations.clear();
    if (aliveCount <= 1 || cakeRemaining == 0) {
      _finish();
      return;
    }
    phase = caught == null
        ? CakeGamePhase.bossReading
        : CakeGamePhase.playerEliminated;
    notifyListeners();
    _phaseTimer = Timer(const Duration(milliseconds: 850), () {
      if (isRunning) {
        phase = CakeGamePhase.bossReading;
        notifyListeners();
        _scheduleReading();
      }
    });
  }

  void _finish() {
    _clock?.cancel();
    _phaseTimer?.cancel();
    phase = CakeGamePhase.gameOver;
    notifyListeners();
  }

  void toggleSound() {
    soundEnabled = !soundEnabled;
    notifyListeners();
  }

  @visibleForTesting
  void enterWatchingForTest() {
    _phaseTimer?.cancel();
    phase = CakeGamePhase.bossWatching;
    _violations.clear();
    notifyListeners();
  }

  @visibleForTesting
  void resolveWatchingForTest() {
    _phaseTimer?.cancel();
    _resolveWatch();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _phaseTimer?.cancel();
    super.dispose();
  }
}
