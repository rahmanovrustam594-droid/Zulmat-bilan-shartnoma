// "Zulmat Shartnomasi" - soddalashtirilgan Flutter o'yini
// Faqat Flutter SDK kerak, qo'shimcha paket yo'q.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MenuScreen(),
    ));

// ---------------- 1. ASOSIY MENYU ----------------
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ZULMAT SHARTNOMASI',
                style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3)),
            const SizedBox(height: 8),
            const Text('Signal Minorasini qur va omon qol',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GameScreen())),
              child: const Text("O'yinni Boshlash"),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- MA'LUMOT SINFLARI ----------------
class Item {
  Offset pos;
  final String type; // 'wood', 'stone', 'ether'
  Item(this.pos, this.type);
}

class Mutant {
  Offset pos;
  Mutant(this.pos);
}

// ---------------- 2. O'YIN EKRANI ----------------
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  // Sozlamalar (xohlagancha o'zgartiring)
  static const double dayLen = 30; // kunduz davomiyligi (soniya)
  static const double nightLen = 25; // tun davomiyligi (soniya)
  static const int totalStages = 5; // minora bosqichlari
  static const int costWood = 8, costStone = 4, costEther = 3;

  final rnd = Random();
  late Ticker ticker;
  Duration last = Duration.zero;
  Size world = Size.zero;

  // Holat
  Offset player = Offset.zero, target = Offset.zero;
  bool isNight = false, started = false, over = false;
  String endTitle = '', endText = '';
  double timer = 0, spawnTimer = 0, hitCooldown = 0;
  double hp = 100;
  int wood = 0, stone = 0, ether = 0, stage = 0, day = 1;
  List<Item> items = [];
  List<Mutant> mutants = [];

  @override
  void initState() {
    super.initState();
    ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  Offset get base => Offset(world.width / 2, world.height / 2);

  Offset _randomPoint() {
    while (true) {
      final p = Offset(30 + rnd.nextDouble() * (world.width - 60),
          80 + rnd.nextDouble() * (world.height - 160));
      if ((p - base).distance > 70) return p; // bazadan uzoqroq
    }
  }

  void _startDay() {
    isNight = false;
    mutants.clear();
    items = [
      for (int i = 0; i < 8; i++) Item(_randomPoint(), 'wood'),
      for (int i = 0; i < 6; i++) Item(_randomPoint(), 'stone'),
    ];
  }

  void _startNight() {
    isNight = true;
    items = [for (int i = 0; i < 7; i++) Item(_randomPoint(), 'ether')];
  }

  void _tick(Duration now) {
    final dt = last == Duration.zero
        ? 0.0
        : (now - last).inMicroseconds / 1e6;
    last = now;
    if (world == Size.zero || over) return;

    if (!started) {
      started = true;
      player = target = base + const Offset(0, 50);
      _startDay();
    }
    _update(dt);
    setState(() {});
  }

  void _update(double dt) {
    // Kun / tun almashinuvi
    timer += dt;
    if (timer >= (isNight ? nightLen : dayLen)) {
      timer = 0;
      if (isNight) {
        day++;
        _startDay();
      } else {
        _startNight();
      }
    }

    // O'yinchi harakati
    final d = target - player;
    if (d.distance > 3) {
      player += d / d.distance * min(150 * dt, d.distance);
    }

    // Resurs yig'ish
    items.removeWhere((it) {
      if ((it.pos - player).distance < 26) {
        if (it.type == 'wood') wood += 2;
        if (it.type == 'stone') stone += 1;
        if (it.type == 'ether') ether += 1;
        return true;
      }
      return false;
    });

    // Tunda mutantlar
    if (isNight) {
      spawnTimer += dt;
      if (spawnTimer > 3) {
        spawnTimer = 0;
        final side = rnd.nextInt(2) == 0 ? 0.0 : world.width;
        mutants.add(Mutant(Offset(side, rnd.nextDouble() * world.height)));
      }
      hitCooldown -= dt;
      for (final m in mutants) {
        final v = player - m.pos;
        if (v.distance > 1) m.pos += v / v.distance * 55 * dt;
        if (v.distance < 22 && hitCooldown <= 0) {
          hp -= 12;
          hitCooldown = 1;
        }
      }
      if (hp <= 0) _finish(false);
    }
  }

  // Minorani bosqichma-bosqich qurish
  void _build() {
    if (wood >= costWood && stone >= costStone && ether >= costEther) {
      wood -= costWood;
      stone -= costStone;
      ether -= costEther;
      stage++;
      if (stage >= totalStages) _finish(true);
    }
  }

  void _finish(bool win) {
    over = true;
    endTitle = win ? '1-Yakun: Qutqaruv Aviasiyasi' : '2-Yakun: Zulmat Qurboni';
    endText = win
        ? 'Minora yondi! Vertolyot keldi va sizni olib ketdi.'
        : 'Baza vayron bo\'ldi, Soyali Labirintchi sizni olib ketdi.';
  }

  void _restart() {
    setState(() {
      started = false;
      over = false;
      isNight = false;
      timer = 0;
      hp = 100;
      wood = stone = ether = stage = 0;
      day = 1;
      items.clear();
      mutants.clear();
    });
  }

  // Ekranga bosish: mutantga tegsa uradi, aks holda yuradi
  void _onTap(Offset p) {
    final hit = mutants.where((m) => (m.pos - p).distance < 30).toList();
    if (hit.isNotEmpty) {
      mutants.remove(hit.first);
    } else {
      target = p;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canBuild =
        wood >= costWood && stone >= costStone && ether >= costEther;
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (context, c) {
        world = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          onTapDown: (d) => _onTap(d.localPosition),
          onPanUpdate: (d) => target = d.localPosition,
          child: Stack(children: [
            CustomPaint(size: world, painter: WorldPainter(this)),
            // HUD
            Positioned(
              top: 30,
              left: 12,
              child: Text(
                '${isNight ? "TUN" : "KUNDUZ"} $day   '
                '${((isNight ? nightLen : dayLen) - timer).ceil()}s\n'
                'HP: ${hp.round()}   Yog\'och: $wood   Tosh: $stone   '
                'Qora Eter: $ether\n'
                'Minora: $stage / $totalStages',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    decoration: TextDecoration.none),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: canBuild ? _build : null,
                  child: Text('Minorani qurish '
                      '($costWood yog\'och, $costStone tosh, $costEther eter)'),
                ),
              ),
            ),
            if (over)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(endTitle,
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 24,
                              decoration: TextDecoration.none)),
                      const SizedBox(height: 10),
                      Text(endText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              decoration: TextDecoration.none)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: _restart, child: const Text('Qayta boshlash')),
                    ],
                  ),
                ),
              ),
          ]),
        );
      }),
    );
  }
}

// ---------------- 3. CHIZISH (RENDER) ----------------
class WorldPainter extends CustomPainter {
  final _GameScreenState g;
  WorldPainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    if (!g.started) return;
    final rect = Offset.zero & size;

    // Fon
    canvas.drawRect(
        rect,
        Paint()
          ..color = g.isNight ? const Color(0xFF10151C) : const Color(0xFF3B7D3A));

    // Baza va minora
    canvas.drawCircle(g.base, 45,
        Paint()..color = Colors.brown.withValues(alpha: 0.5));
    final towerH = 20.0 + g.stage * 22;
    canvas.drawRect(
        Rect.fromCenter(
            center: g.base - Offset(0, towerH / 2), width: 16, height: towerH),
        Paint()..color = Colors.grey.shade400);
    if (g.stage > 0) {
      canvas.drawCircle(g.base - Offset(0, towerH), 6,
          Paint()..color = Colors.cyanAccent);
    }

    // Resurslar
    for (final it in g.items) {
      final color = it.type == 'wood'
          ? Colors.brown.shade600
          : it.type == 'stone'
              ? Colors.blueGrey
              : Colors.purpleAccent;
      if (it.type == 'ether') {
        canvas.drawCircle(it.pos, 12,
            Paint()..color = Colors.purpleAccent.withValues(alpha: 0.35));
      }
      canvas.drawCircle(it.pos, it.type == 'wood' ? 11 : 8, Paint()..color = color);
    }

    // Mutantlar
    for (final m in g.mutants) {
      canvas.drawCircle(m.pos, 13, Paint()..color = Colors.redAccent);
    }

    // O'yinchi
    canvas.drawCircle(g.player, 10, Paint()..color = Colors.amber);

    // Tungi qorong'ulik: faqat fonar atrofi ko'rinadi
    if (g.isNight) {
      canvas.saveLayer(rect, Paint());
      canvas.drawRect(rect, Paint()..color = Colors.black.withValues(alpha: 0.96));
      canvas.drawCircle(
          g.player,
          110,
          Paint()
            ..blendMode = BlendMode.clear
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant WorldPainter old) => true;
}
