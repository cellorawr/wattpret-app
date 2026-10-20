import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'browse_screen.dart';
import 'library_screen.dart';
import 'write_screen.dart';
import 'updates_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  // Navigator tiap tab, supaya menekan navbar bisa mengembalikan tab itu
  // ke halaman utamanya (mis. dari Pengaturan kembali ke Beranda).
  final _navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  void _onTab(int i) {
    _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    setState(() => _index = i);
  }

  void _onTabRequest() {
    final i = AppState.tabRequest.value;
    if (i < 0) return;
    AppState.tabRequest.value = -1;
    _onTab(i);
  }

  @override
  void initState() {
    super.initState();
    AppState.tabRequest.addListener(_onTabRequest);
  }

  @override
  void dispose() {
    AppState.tabRequest.removeListener(_onTabRequest);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: [
        Navigator(
          key: _navKeys[0],
          onGenerateRoute: (_) =>
              MaterialPageRoute(
                  builder: (_) => const Scaffold(body: HomeScreen())),
        ),
        Navigator(
          key: _navKeys[1],
          onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => const Scaffold(body: BrowseScreen())),
        ),
        Navigator(
          key: _navKeys[2],
          onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => Scaffold(
                  body: LibraryScreen(
                      onFind: () => setState(() => _index = 1)))),
        ),
        Navigator(
          key: _navKeys[3],
          onGenerateRoute: (_) =>
              MaterialPageRoute(builder: (_) => const WriteScreen()),
        ),
        Navigator(
          key: _navKeys[4],
          onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => const Scaffold(body: UpdatesScreen())),
        ),
      ]),
      bottomNavigationBar:
          _NavBar(index: _index, onTap: _onTab),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavBar({required this.index, required this.onTap});

  Widget _icon(int i, Color c) =>
      CustomPaint(size: const Size(28, 28), painter: _NavIconPainter(i, c));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: C.bg,
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A)))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(children: [
            for (var i = 0; i < 5; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(clipBehavior: Clip.none, children: [
                          _icon(i, i == index ? C.orange : const Color(0xFFBDBDBD)),
                          if (i == 2)
                            Positioned(
                              top: -10,
                              right: -14,
                              child: ValueListenableBuilder<List<Story>>(
                                valueListenable: AppState.library,
                                builder: (_, lib, __) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B30),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text('${lib.length}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ),
                        ]),
                        const SizedBox(height: 7),
                        Container(
                          width: 28,
                          height: 3,
                          decoration: BoxDecoration(
                              color: i == index ? C.orange : Colors.transparent,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Ikon navigasi bawah (garis tipis, dibuat meniru ikon aplikasi asli):
/// 0 beranda, 1 pencarian, 2 perpustakaan, 3 pensil, 4 lonceng.
class _NavIconPainter extends CustomPainter {
  final int kind;
  final Color color;
  _NavIconPainter(this.kind, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Setiap ikon digambar pada kotak (w x h) lalu ditaruh di tengah kanvas.
    late double w, h;
    switch (kind) {
      case 0:
        w = 23.4; h = 24;
      case 1:
        w = 27.5; h = 25;
      case 2:
        w = 19; h = 21.5;
      case 3:
        w = 23; h = 23;
      default:
        w = 23.4; h = 25;
    }
    canvas.save();
    canvas.translate((size.width - w) / 2, (size.height - h) / 2);

    switch (kind) {
      case 0: // beranda: atap + dinding + pintu
        canvas.drawPath(
            Path()
              ..moveTo(0.9, 10.4)
              ..lineTo(11.7, 1.0)
              ..lineTo(22.5, 10.4),
            p);
        canvas.drawPath(
            Path()
              ..moveTo(3.6, 8.2)
              ..lineTo(3.6, 23.1)
              ..lineTo(19.8, 23.1)
              ..lineTo(19.8, 8.2),
            p);
        canvas.drawPath(
            Path()
              ..moveTo(8.0, 23.1)
              ..lineTo(8.0, 12.6)
              ..quadraticBezierTo(8.0, 11.2, 9.4, 11.2)
              ..lineTo(14.0, 11.2)
              ..quadraticBezierTo(15.4, 11.2, 15.4, 12.6)
              ..lineTo(15.4, 23.1),
            p);
        break;
      case 1: // pencarian: lensa + gagang + dua garis kecil di kiri bawah
        const c = Offset(16.0, 11.2);
        const r = 10.2;
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), 2.9, 5.35, false, p);
        canvas.drawLine(const Offset(23.3, 18.6), const Offset(26.7, 23.2), p);
        canvas.drawLine(const Offset(1.2, 18.4), const Offset(7.0, 18.4), p);
        canvas.drawLine(const Offset(0.8, 23.6), const Offset(13.0, 23.6), p);
        break;
      case 2: // perpustakaan: / | |
        canvas.drawLine(const Offset(0.8, 20.6), const Offset(4.9, 0.9), p);
        canvas.drawLine(const Offset(10.6, 0.9), const Offset(10.6, 20.6), p);
        canvas.drawLine(const Offset(17.8, 0.9), const Offset(17.8, 20.6), p);
        break;
      case 3: // pensil
        const s = Offset(1.0, 22.0);
        const e = Offset(21.6, 1.4);
        const d = Offset(0.7071, -0.7071);
        const n = Offset(0.7071, 0.7071);
        const hw = 3.3;
        final b1 = s + d * 6.0 + n * hw;
        final b2 = s + d * 6.0 - n * hw;
        final c1 = e + n * hw;
        final c2 = e - n * hw;
        canvas.drawPath(
            Path()
              ..moveTo(s.dx, s.dy)
              ..lineTo(b1.dx, b1.dy)
              ..lineTo(c1.dx, c1.dy)
              ..lineTo(c2.dx, c2.dy)
              ..lineTo(b2.dx, b2.dy)
              ..close(),
            p);
        final g1 = e - d * 3.6 + n * hw;
        final g2 = e - d * 3.6 - n * hw;
        canvas.drawLine(g1, g2, p);
        break;
      default: // lonceng
        canvas.drawPath(
            Path()
              ..moveTo(3.6, 18.6)
              ..cubicTo(4.6, 16.2, 4.8, 13.6, 4.8, 10.6)
              ..cubicTo(4.8, 5.4, 8.0, 1.2, 11.7, 1.2)
              ..cubicTo(15.4, 1.2, 18.6, 5.4, 18.6, 10.6)
              ..cubicTo(18.6, 13.6, 18.8, 16.2, 19.8, 18.6),
            p);
        canvas.drawLine(const Offset(0.9, 18.8), const Offset(22.5, 18.8), p);
        canvas.drawArc(const Rect.fromLTWH(9.3, 19.4, 4.8, 4.6), 0, 3.1416, false, p);
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter old) =>
      old.color != color || old.kind != kind;
}
