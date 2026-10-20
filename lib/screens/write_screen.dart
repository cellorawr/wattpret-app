import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets.dart';
import 'info_screen.dart';
import 'new_story_screen.dart';
import 'profile_screen.dart';
import 'settings_pages.dart';
import 'works_screen.dart';
import 'edit_work_screen.dart';
import '../theme.dart';

class WriteScreen extends StatelessWidget {
  const WriteScreen({super.key});

  void _push(BuildContext c, Widget w) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  /// Baris menu: ikon di kiri 16, teks 40 di sebelahnya, garis pemisah
  /// mulai sejajar ikon (seperti aplikasi asli).
  Widget _item(BuildContext c, Widget icon, String t, VoidCallback onTap,
      {bool divider = true}) {
    return InkWell(
      onTap: onTap,
      child: Column(children: [
        SizedBox(
          height: 55,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              SizedBox(width: 24, child: Center(child: icon)),
              const SizedBox(width: 18),
              Text(t, style: const TextStyle(fontSize: 18)),
            ]),
          ),
        ),
        if (divider)
          const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Divider(height: 1, color: Color(0xFF2E2E2E))),
      ]),
    );
  }

  Widget _filled(IconData i) => Container(
        width: 22,
        height: 22,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(i, size: 14, color: Colors.black),
      );

  Widget _resume(BuildContext context, List<Work> works) {
    if (works.isEmpty) return const SizedBox.shrink();
    final w = works.first; // yang terakhir dikerjakan
    final n = w.draftCount;
    final pub = w.parts.where((p) => p.published).length;
    final badge = pub > 0 ? '$pub bab dipublikasikan' : '$n draf';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _push(context, EditWorkScreen(work: w)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2E2E2E)),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            BookCover(w.toStory(), w: 64, h: 100),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Lanjutkan menulis',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 6),
                Text(w.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(badge,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Row(children: [
              const Text('Tulis',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: () => _push(context, const ProfileScreen()),
                child: Row(children: [
                  Text('@${AppState.username}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(width: 10),
                  const Avatar(size: 34),
                ]),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFF2E2E2E)),
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: _list(context)),
              Positioned(left: 8, right: 8, bottom: 8, child: _addedBanner(context)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _addedBanner(BuildContext context) => const _AddedBanner();

  Widget _list(BuildContext context) {
    return ValueListenableBuilder<List<Work>>(
              valueListenable: AppState.works,
              builder: (ctx, works, _) => ListView(padding: EdgeInsets.zero, children: [
                Container(color: Colors.black, child: _resume(context, works)),
                Container(
                  color: Colors.black,
                  child: Column(children: [
                    _item(
                        context,
                        const _SeriIcon(),
                        'Seri',
                        () => _push(context, const SeriesScreen())),
                    _item(
                        context,
                        const _NewStoryIcon(),
                        'Buat cerita baru',
                        () => Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                                builder: (_) => const NewStoryScreen()))),
                    _item(
                        context,
                        _filled(Icons.menu_book),
                        'Sumber daya kepenulisan',
                        () => Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                                builder: (_) => const WritingResourcesScreen()))),
                    _item(
                        context,
                        _filled(Icons.star),
                        'Program & peluang',
                        () => Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                                builder: (_) => const ProgramsScreen())),
                        divider: false),
                  ]),
                ),
              ]),
            );
  }
}

/// Banner "Ditambahkan ke Karya - Ketuk untuk mengedit ceritamu" setelah publikasi.
class _AddedBanner extends StatefulWidget {
  const _AddedBanner();
  @override
  State<_AddedBanner> createState() => _AddedBannerState();
}

class _AddedBannerState extends State<_AddedBanner> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    AppState.justPublished.addListener(_changed);
    _changed();
  }

  void _changed() {
    _t?.cancel();
    if (AppState.justPublished.value != null) {
      _t = Timer(const Duration(seconds: 8), () {
        AppState.justPublished.value = null;
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    AppState.justPublished.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Work?>(
      valueListenable: AppState.justPublished,
      builder: (ctx, w, _) {
        if (w == null) return const SizedBox.shrink();
        // Pop up naik dari bawah.
        return TweenAnimationBuilder<double>(
          key: ValueKey(w),
          tween: Tween(begin: 1.0, end: 0.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          builder: (_, v, child) => Opacity(
              opacity: 1 - v,
              child: Transform.translate(offset: Offset(0, v * 90), child: child)),
          child: GestureDetector(
          onTap: () {
            AppState.justPublished.value = null;
            Navigator.of(ctx).push(
                MaterialPageRoute(builder: (_) => EditWorkScreen(work: w)));
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(4)),
            child: Row(children: [
              BookCover(w.toStory(), w: 32, h: 50),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ditambahkan ke Karya',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('Ketuk untuk mengedit ceritamu',
                      style: TextStyle(fontSize: 16)),
                ]),
              ),
              const Icon(Icons.chevron_right, size: 30),
            ]),
          ),
        ));
      },
    );
  }
}

/// Ikon "Seri": persegi panjang bulat + dua batang tipis (seperti aplikasi asli).
class _SeriIcon extends StatelessWidget {
  const _SeriIcon();
  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(24, 24), painter: _SeriPainter());
}

class _SeriPainter extends CustomPainter {
  const _SeriPainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(2, 3, 11, 18), const Radius.circular(2.5)),
        p);
    c.drawLine(const Offset(17, 5), const Offset(17, 19), p);
    c.drawLine(const Offset(21.5, 5), const Offset(21.5, 19), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Ikon "Buat cerita baru": kotak bersudut bulat dengan tanda + di pojok kanan atas.
class _NewStoryIcon extends StatelessWidget {
  const _NewStoryIcon();
  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(24, 24), painter: _NewStoryPainter());
}

class _NewStoryPainter extends CustomPainter {
  const _NewStoryPainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // Kotak dengan celah di pojok kanan atas.
    final path = Path()
      ..moveTo(12, 3.5)
      ..lineTo(5.5, 3.5)
      ..arcToPoint(const Offset(3.5, 5.5), radius: const Radius.circular(2), clockwise: false)
      ..lineTo(3.5, 18.5)
      ..arcToPoint(const Offset(5.5, 20.5), radius: const Radius.circular(2), clockwise: false)
      ..lineTo(18.5, 20.5)
      ..arcToPoint(const Offset(20.5, 18.5), radius: const Radius.circular(2), clockwise: false)
      ..lineTo(20.5, 12);
    c.drawPath(path, p);
    // Tanda +
    c.drawLine(const Offset(18, 2.5), const Offset(18, 9.5), p);
    c.drawLine(const Offset(14.5, 6), const Offset(21.5, 6), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
