import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cake_game_controller.dart';
import 'cake_game_models.dart';
import 'cake_game_widgets.dart';

class CakeGamePage extends StatefulWidget {
  const CakeGamePage({super.key});

  @override
  State<CakeGamePage> createState() => _CakeGamePageState();
}

class _CakeGamePageState extends State<CakeGamePage> {
  late final CakeGameController game;
  int _seenAction = 0;

  @override
  void initState() {
    super.initState();
    game = CakeGameController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: game,
    builder: (_, _) => Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const CakeRoomBackdrop(),
            if (game.phase == CakeGamePhase.gameOver) _gameOver() else _game(),
          ],
        ),
      ),
    ),
  );

  Widget _game() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxHeight < 510 || constraints.maxWidth < 760;
      final pad = compact ? 8.0 : 16.0;
      final eatingId = game.lastScoringPlayer;
      final caughtId = game.lastEliminatedPlayer;
      final pulse = _seenAction != game.actionTick && eatingId != null;
      _seenAction = game.actionTick;
      return Stack(
        children: [
          Positioned(
            top: pad,
            left: pad,
            child: GameStatusPanel(
              seconds: game.remaining.inSeconds,
              cake: game.cakeRemaining,
              alive: game.aliveCount,
            ),
          ),
          Positioned(
            top: pad,
            left: 0,
            right: 0,
            child: Center(
              child: BossStatusBar(
                phase: game.phase,
                message: game.bossMessage,
              ),
            ),
          ),
          Positioned(
            top: pad,
            right: pad,
            child: Row(
              children: [
                _cornerIcon(
                  game.soundEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  () => game.toggleSound(),
                ),
                const SizedBox(width: 8),
                _exitButton(),
              ],
            ),
          ),
          Positioned.fill(child: _scene(compact, eatingId, caughtId, pulse)),
          if (game.phase == CakeGamePhase.waiting) _startOverlay(),
          _controls(compact),
        ],
      );
    },
  );

  Widget _scene(bool compact, int? eatingId, int? caughtId, bool pulse) =>
      LayoutBuilder(
        builder: (_, box) {
          final tableWidth = box.maxWidth * (compact ? .55 : .60);
          final tableHeight = tableWidth / 2.12;
          final centerY = box.maxHeight * (compact ? .59 : .61);
          Widget player(int index, double left, double top) => Positioned(
            left: left,
            top: top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerScore(player: game.players[index]),
                const SizedBox(height: 2),
                ChibiPlayer(
                  player: game.players[index],
                  isEating:
                      eatingId == game.players[index].id &&
                      !game.players[index].eliminated,
                  isCaught:
                      caughtId == game.players[index].id &&
                      game.phase == CakeGamePhase.playerEliminated,
                ),
                if (eatingId == game.players[index].id &&
                    !game.players[index].eliminated)
                  const Text(
                    '+1',
                    style: TextStyle(
                      color: Color(0xFFFFE26B),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
              ],
            ),
          );
          return Stack(
            children: [
              Positioned(
                left: (box.maxWidth - tableWidth) / 2,
                top: centerY - tableHeight / 2,
                width: tableWidth,
                child: CakeTable(
                  cakeRemaining: game.cakeRemaining,
                  pulse: pulse,
                ),
              ),
              Positioned(
                top: box.maxHeight * .20,
                left: 0,
                right: 0,
                child: Center(child: BossCharacter(phase: game.phase)),
              ),
              if (game.phase == CakeGamePhase.playerEliminated &&
                  game.lastShotPlayer != null)
                Positioned(
                  top: box.maxHeight * .39,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ShotIndicator(playerId: game.lastShotPlayer!),
                  ),
                ),
              player(0, box.maxWidth * .22, box.maxHeight * .40),
              player(1, box.maxWidth * .67, box.maxHeight * .40),
              player(2, box.maxWidth * .29, box.maxHeight * .69),
              player(3, box.maxWidth * .61, box.maxHeight * .69),
            ],
          );
        },
      );

  Widget _controls(bool compact) => Stack(
    children: [
      Positioned(
        left: compact ? 8 : 22,
        top: compact ? 175 : 195,
        child: CakeTapButton(
          player: game.players[0],
          onTap: () => game.tapPlayer(1),
          compact: compact,
        ),
      ),
      Positioned(
        right: compact ? 8 : 22,
        top: compact ? 175 : 195,
        child: CakeTapButton(
          player: game.players[1],
          onTap: () => game.tapPlayer(2),
          compact: compact,
        ),
      ),
      Positioned(
        left: compact ? 8 : 42,
        bottom: compact ? 8 : 20,
        child: CakeTapButton(
          player: game.players[2],
          onTap: () => game.tapPlayer(3),
          compact: compact,
        ),
      ),
      Positioned(
        right: compact ? 8 : 42,
        bottom: compact ? 8 : 20,
        child: CakeTapButton(
          player: game.players[3],
          onTap: () => game.tapPlayer(4),
          compact: compact,
        ),
      ),
    ],
  );

  Widget _cornerIcon(IconData icon, VoidCallback onPressed) => Material(
    color: const Color(0xDD130F0D),
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
    ),
  );

  Widget _exitButton() => Material(
    color: const Color(0xFFC84130),
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => Navigator.pop(context),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'ออก',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _startOverlay() => Center(
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xE914100E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD262)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'แอบกินเค้ก',
            style: TextStyle(
              color: Color(0xFFFFD262),
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'รีบแตะตอนบอสไม่มอง!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 13),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF1B93E),
              foregroundColor: const Color(0xFF2E190A),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            ),
            onPressed: game.start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'เริ่มเกม',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _gameOver() => LayoutBuilder(
    builder: (context, constraints) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 370,
          maxHeight: constraints.maxHeight - 16,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: 370,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xF218100D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFD262), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 30),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFD262),
                  size: 48,
                ),
                const Text(
                  'จบเกม!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'ผู้ชนะ P${game.ranking.first.id}',
                  style: const TextStyle(
                    color: Color(0xFFFFD262),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ...game.ranking.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '${entry.key + 1}.',
                          style: const TextStyle(
                            color: Color(0xFFFFD262),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'P${entry.value.id}',
                          style: TextStyle(
                            color: entry.value.color,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${entry.value.score} คะแนน${entry.value.eliminated ? ' • ออกแล้ว' : ''}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: game.restart,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF1B93E),
                        foregroundColor: const Color(0xFF2E190A),
                      ),
                      child: const Text('เล่นอีกครั้ง'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('กลับ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
