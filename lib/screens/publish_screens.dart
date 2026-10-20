import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'story_pages.dart';

/// Dialog gaya iOS "Konfirmasi Publikasi" sebelum bab diterbitkan.
Future<bool?> showPublishConfirm(BuildContext context, int words) {
  final secs = (words / 4).round();
  final t = secs >= 60
      ? '${(secs / 60).round()} menit'
      : '${secs < 1 ? 1 : secs} detik';
  Widget btn(BuildContext ctx, String label, bool value, {bool bold = false}) =>
      InkWell(
        onTap: () => Navigator.pop(ctx, value),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: C.iosBlue,
                  fontSize: 18,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        ),
      );
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF2C2C2E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          child: Column(children: [
            const Text('Konfirmasi Publikasi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                'Bab cerita kamu membutuhkan $t untuk dibaca.\n\nSiap untuk menjadikan bab ceritamu ini terlihat oleh semua pembaca di Wattpret?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.3)),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFF48484A)),
        btn(ctx, 'Publikasikan Sekarang', true),
        const Divider(height: 1, color: Color(0xFF48484A)),
        btn(ctx, 'Lanjutkan Menulis', false, bold: true),
      ]),
    ),
  );
}

/// Menandai cerita & bab sebagai terbit lalu menampilkan layar "Selamat".
Future<void> finishPublish(BuildContext context, Work w, List<Part> parts) async {
  w.published = true;
  for (final p in parts) {
    p.published = true;
    p.touch();
  }
  AppState.saveWork(w);
  await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      fullscreenDialog: true, builder: (_) => PublishedScreen(work: w)));
}

/// Layar "Selamat - Kamu baru saja memublikasikan ..." setelah menerbitkan.
class PublishedScreen extends StatefulWidget {
  final Work work;
  const PublishedScreen({super.key, required this.work});
  @override
  State<PublishedScreen> createState() => _PublishedScreenState();
}

class _PublishedScreenState extends State<PublishedScreen> {
  Work get w => widget.work;
  static const _band = Color(0xFF202020);
  static const _grey = Color(0xFFB4B4B4);

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  /// "Selesai": kembali ke halaman Tulis, lalu muncul pop up
  /// "Ditambahkan ke Karya - Ketuk untuk mengedit ceritamu".
  void _done() {
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    AppState.tabRequest.value = 3; // tab Tulis
    AppState.justPublished.value = null;
    AppState.justPublished.value = w;
  }

  Future<void> _moreTags() async {
    final r = await Navigator.of(context, rootNavigator: true).push<List<String>>(
        MaterialPageRoute(builder: (_) => TagsPage(initial: w.tags)));
    if (r != null) {
      setState(() => w.tags = r);
      AppState.saveWork(w);
    }
  }

  Widget _section(Widget child) => Container(
        width: double.infinity,
        color: _band,
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
        child: child,
      );

  Widget _shareBtn(Widget icon, Color bg, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 88,
          height: 46,
          alignment: Alignment.center,
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
          child: icon,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final title = w.title.isEmpty ? 'Tanpa judul' : w.title;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(children: [
          // Lebar penuh supaya "Selamat" di tengah dan "Selesai" di kanan
          // (tanpa lebar, Stack menyusut dan kedua teks saling menumpuk).
          Container(
            height: 54,
            width: double.infinity,
            color: _band,
            child: Stack(alignment: Alignment.center, children: [
              const Text('Selamat',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: InkWell(
                  onTap: _done,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text('Selesai',
                          style: TextStyle(fontSize: 17, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              _section(Column(children: [
                const Text('Kamu baru saja memublikasikan',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, color: _grey)),
                const SizedBox(height: 18),
                BookCover(w.toStory(), w: 80, h: 127),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: Color(0xFFD0D0D0))),
              ])),
              const SizedBox(height: 10),
              _section(Column(children: [
                const Text('Cerita kamu dapat ditemukan di sini',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, color: _grey)),
                const SizedBox(height: 16),
                if (w.tags.isNotEmpty)
                  Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final t in w.tags)
                          Container(
                            color: const Color(0xFF2B2B2B),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Text('#$t',
                                style: const TextStyle(
                                    fontSize: 15, color: Color(0xFFE0734A))),
                          ),
                      ]),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _moreTags,
                  child: const Text('Tambahkan tag lagi',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ])),
              const SizedBox(height: 10),
              _section(Column(children: [
                const Text('Bagikan agar ditemukan orang',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, color: _grey)),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _shareBtn(
                      const Icon(Icons.facebook, size: 30, color: Colors.white),
                      const Color(0xFF3B5998),
                      () => _snack('Berbagi ke Facebook belum tersedia di versi demo')),
                  const SizedBox(width: 14),
                  _shareBtn(const Icon(Icons.link, size: 28, color: Colors.white),
                      const Color(0xFF3A3A3C), () => _snack('Tautan cerita disalin')),
                ]),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () => _snack('Tautan cerita disalin'),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.ios_share, size: 24),
                    SizedBox(width: 12),
                    Text('Aplikasi Lain',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }
}
