import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cake_game_models.dart';

const _ink = Color(0xE814100E);

class CakeRoomBackdrop extends StatelessWidget {
  const CakeRoomBackdrop({super.key});
  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(child: CustomPaint(painter: _RoomPainter()));
}

class BossStatusBar extends StatelessWidget {
  const BossStatusBar({super.key, required this.phase, required this.message});
  final CakeGamePhase phase;
  final String message;
  @override
  Widget build(BuildContext context) {
    final isReading = phase == CakeGamePhase.bossReading;
    final isWarning = phase == CakeGamePhase.bossWarning;
    final isWatching = phase == CakeGamePhase.bossWatching;
    final statusColor = isReading
        ? const Color(0xFF79D64A)
        : isWarning
        ? const Color(0xFFFFD05B)
        : isWatching
        ? const Color(0xFFFF614D)
        : const Color(0xFFBBAA9A);
    final statusIcon = isReading
        ? Icons.menu_book_rounded
        : isWarning
        ? Icons.warning_amber_rounded
        : isWatching
        ? Icons.visibility_rounded
        : Icons.info_outline_rounded;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isWatching
            ? const Color(0xEE501914)
            : isWarning
            ? const Color(0xEE5D4912)
            : _ink,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: statusColor),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 30),
          const SizedBox(width: 10),
          SizedBox(
            width: 210,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 750),
                  tween: Tween(begin: .12, end: isWatching ? 1 : .78),
                  builder: (context, value, child) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 9,
                      backgroundColor: Colors.black54,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameStatusPanel extends StatelessWidget {
  const GameStatusPanel({
    super.key,
    required this.seconds,
    required this.cake,
    required this.alive,
  });
  final int seconds;
  final int cake;
  final int alive;
  @override
  Widget build(BuildContext context) => Container(
    width: 148,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _ink,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0x665E4634)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusLine(
          icon: Icons.timer_outlined,
          label: 'เวลา',
          value: '00:${seconds.toString().padLeft(2, '0')}',
        ),
        const Divider(color: Color(0x665E4634)),
        _StatusLine(
          icon: Icons.cake_rounded,
          label: 'เค้กที่เหลือ',
          value: '$cake / 20',
        ),
        const Divider(color: Color(0x665E4634)),
        _StatusLine(
          icon: Icons.groups_rounded,
          label: 'ผู้เล่น',
          value: '$alive / 4',
        ),
      ],
    ),
  );
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFFFFCD62), size: 24),
      const SizedBox(width: 7),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFFCFC2B6), fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class CakeTable extends StatelessWidget {
  const CakeTable({
    super.key,
    required this.cakeRemaining,
    required this.pulse,
  });
  final int cakeRemaining;
  final bool pulse;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 2.12,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              colors: [Color(0xFFC88743), Color(0xFF75401E), Color(0xFF32190E)],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE3A75C), width: 5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
        ),
        AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: pulse ? 1.1 : 1,
          child: _CakeVisual(cakeRemaining: cakeRemaining),
        ),
      ],
    ),
  );
}

class _CakeVisual extends StatelessWidget {
  const _CakeVisual({required this.cakeRemaining});
  final int cakeRemaining;
  @override
  Widget build(BuildContext context) {
    final count = math.max(0, (cakeRemaining / 2).ceil());
    return SizedBox(
      width: 150,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 136,
            height: 78,
            margin: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8D59A),
                  Color(0xFFE89555),
                  Color(0xFFF6D2A2),
                  Color(0xFFD67B42),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: const Color(0xFF8C452B), width: 3),
            ),
          ),
          Positioned(
            top: 17,
            child: Container(
              width: 136,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DE),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: const Color(0xFFAF6339), width: 3),
              ),
            ),
          ),
          ...List.generate(count, (i) {
            final angle = i * math.pi * 2 / math.max(count, 1);
            return Positioned(
              left: 66 + math.cos(angle) * 48,
              top: 30 + math.sin(angle) * 17,
              child: const Icon(
                Icons.local_florist_rounded,
                color: Color(0xFFE9423D),
                size: 21,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class BossCharacter extends StatelessWidget {
  const BossCharacter({super.key, required this.phase});
  final CakeGamePhase phase;
  @override
  Widget build(BuildContext context) {
    final watching =
        phase == CakeGamePhase.bossWatching ||
        phase == CakeGamePhase.bossWarning;
    final reading =
        phase == CakeGamePhase.bossReading || phase == CakeGamePhase.waiting;
    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      scale: phase == CakeGamePhase.bossWarning ? 1.08 : 1,
      child: SizedBox(
        width: 125,
        height: 150,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 15,
              child: Container(
                width: 85,
                height: 95,
                decoration: BoxDecoration(
                  color: const Color(0xFFB87950),
                  borderRadius: BorderRadius.circular(46),
                  border: Border.all(color: const Color(0xFF26140F), width: 4),
                ),
              ),
            ),
            Positioned(
              top: 7,
              child: Container(
                width: 88,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF201612),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(43)),
                ),
              ),
            ),
            if (watching) ...[
              const Positioned(top: 52, left: 31, child: _Eye()),
              const Positioned(top: 52, right: 31, child: _Eye()),
              const Positioned(
                top: 76,
                child: Icon(
                  Icons.remove_rounded,
                  color: Color(0xFF26140F),
                  size: 30,
                ),
              ),
            ],
            Positioned(
              bottom: 0,
              child: Container(
                width: 108,
                height: 59,
                decoration: BoxDecoration(
                  color: const Color(0xFF33221C),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              bottom: reading ? 17 : -48,
              child: Container(
                width: 120,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DFCE),
                  border: Border.all(color: const Color(0xFF493A2D), width: 3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ข่าว',
                  style: TextStyle(
                    color: Color(0xFF33251E),
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye();
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.circle, color: Color(0xFF17100D), size: 16);
}

class ChibiPlayer extends StatelessWidget {
  const ChibiPlayer({
    super.key,
    required this.player,
    required this.isEating,
    required this.isCaught,
  });
  final CakePlayer player;
  final bool isEating;
  final bool isCaught;
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: const Duration(milliseconds: 220),
    opacity: player.eliminated ? .3 : 1,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (isCaught) const Positioned.fill(child: _TargetEffect()),
        AnimatedSlide(
          duration: const Duration(milliseconds: 180),
          offset: isEating ? const Offset(0, -.14) : Offset.zero,
          child: SizedBox(
            width: 88,
            height: 96,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 4,
                  child: Container(
                    width: 54,
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD0A4),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF2B1912),
                        width: 3,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Container(
                    width: 56,
                    height: 27,
                    decoration: BoxDecoration(
                      color: const Color(0xFF392820),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 68,
                    height: 49,
                    decoration: BoxDecoration(
                      color: player.color,
                      border: Border.all(
                        color: const Color(0xFF26140F),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                if (!player.eliminated)
                  Positioned(
                    right: isEating ? -1 : 5,
                    top: 53,
                    child: Transform.rotate(
                      angle: isEating ? -.7 : 0,
                      child: const Icon(
                        Icons.back_hand_rounded,
                        size: 28,
                        color: Color(0xFFFFD0A4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (player.eliminated)
          const Positioned(
            bottom: 18,
            child: Icon(
              Icons.block_rounded,
              color: Color(0xFFFF574C),
              size: 46,
            ),
          ),
      ],
    ),
  );
}

class _TargetEffect extends StatelessWidget {
  const _TargetEffect();
  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFFFFE26B), width: 4),
        ),
        boxShadow: [
          BoxShadow(color: Color(0xCCFF3D2E), blurRadius: 18, spreadRadius: 5),
        ],
      ),
    ),
  );
}

class ShotIndicator extends StatelessWidget {
  const ShotIndicator({super.key, required this.playerId});

  final int playerId;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    duration: const Duration(milliseconds: 520),
    tween: Tween(begin: .25, end: 1),
    builder: (context, value, child) => Transform.scale(
      scale: value,
      child: Opacity(
        opacity: 1.25 - value,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xEE47130F),
            border: Border.all(color: const Color(0xFFFFCF59), width: 2),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0xCCFF3D2E), blurRadius: 13),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              '💥 ยิง P$playerId!',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PlayerScore extends StatelessWidget {
  const PlayerScore({super.key, required this.player});
  final CakePlayer player;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _ink,
      border: Border.all(color: player.color, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'P${player.id}',
            style: TextStyle(
              color: player.color,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          Text(
            player.eliminated ? 'ออกแล้ว' : 'คะแนน ${player.score}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class CakeTapButton extends StatelessWidget {
  const CakeTapButton({
    super.key,
    required this.player,
    required this.onTap,
    this.compact = false,
  });
  final CakePlayer player;
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: player.eliminated ? .32 : 1,
    child: IgnorePointer(
      ignoring: player.eliminated,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onTap(),
        child: Container(
          width: compact ? 72 : 96,
          height: compact ? 72 : 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(player.color, Colors.white, .24)!,
                player.color,
              ],
            ),
            border: Border.all(color: const Color(0xFF20140E), width: 4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                player.eliminated
                    ? Icons.block_rounded
                    : Icons.back_hand_rounded,
                color: Colors.white,
                size: compact ? 27 : 35,
              ),
              Text(
                player.eliminated ? 'ออก' : 'แตะ!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF24130D), Color(0xFF100D0F)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    final floor = Paint()..color = const Color(0x55281209);
    for (var i = 0; i < 9; i++) {
      final y = size.height * (.59 + i * .07);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 25),
        floor..strokeWidth = 2,
      );
    }
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [const Color(0x55FFBE66), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .14, size.height * .24),
              radius: 130,
            ),
          );
    canvas.drawCircle(Offset(size.width * .14, size.height * .24), 150, glow);
    canvas.drawCircle(Offset(size.width * .86, size.height * .24), 150, glow);
    final window = Paint()..color = const Color(0x99304261);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * .27),
          width: size.width * .30,
          height: size.height * .28,
        ),
        const Radius.circular(18),
      ),
      window,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) => false;
}
