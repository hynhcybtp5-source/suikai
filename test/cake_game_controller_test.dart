import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/features/minigame/cake_game_controller.dart';
import 'package:suikai/features/minigame/cake_game_models.dart';

void main() {
  test('cake and score increase only while boss reads', () {
    final game = CakeGameController();
    game.start();
    game.tapPlayer(1, DateTime(2026));
    expect(game.players.first.score, 1);
    expect(game.cakeRemaining, 19);
    game.dispose();
  });
  test('eliminated player cannot score', () {
    final game = CakeGameController();
    game.start();
    game.players.first.eliminated = true;
    game.tapPlayer(1, DateTime(2026));
    expect(game.players.first.score, 0);
    game.dispose();
  });
  test('restart restores cake, players, and waiting state', () {
    final game = CakeGameController();
    game.start();
    game.tapPlayer(1, DateTime(2026));
    game.restart();
    expect(game.phase, CakeGamePhase.waiting);
    expect(game.cakeRemaining, 20);
    expect(game.players.every((p) => !p.eliminated), isTrue);
    game.dispose();
  });

  test('latest player moving while the boss watches is eliminated', () {
    final game = CakeGameController();
    game.start();
    game.enterWatchingForTest();
    game.tapPlayer(1, DateTime(2026, 1, 1, 0, 0, 1));
    game.tapPlayer(4, DateTime(2026, 1, 1, 0, 0, 2));
    game.resolveWatchingForTest();

    expect(game.players[0].eliminated, isFalse);
    expect(game.players[3].eliminated, isTrue);
    expect(game.lastEliminatedPlayer, 4);
    expect(game.phase, CakeGamePhase.playerEliminated);
    game.dispose();
  });

  test('watching without input returns to reading with no elimination', () {
    final game = CakeGameController();
    game.start();
    game.enterWatchingForTest();
    game.resolveWatchingForTest();

    expect(game.phase, CakeGamePhase.bossReading);
    expect(game.aliveCount, 4);
    game.dispose();
  });
}
