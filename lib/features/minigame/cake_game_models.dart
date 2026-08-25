import 'package:flutter/material.dart';

enum CakeGamePhase {
  waiting,
  bossReading,
  bossWarning,
  bossWatching,
  playerEliminated,
  gameOver,
}

class CakePlayer {
  final int id;
  final Color color;
  int score;
  bool eliminated;
  DateTime? lastInputAt;

  CakePlayer({
    required this.id,
    required this.color,
    this.score = 0,
    this.eliminated = false,
  });
}
