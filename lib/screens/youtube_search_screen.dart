import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

/// Ambil ID video (11 karakter) dari tautan YouTube. null jika bukan tautan video.
String? youtubeId(String raw) {
  final m = RegExp(
          r'(?:youtu\.be/|youtube\.com/(?:watch\?(?:[^#\s]*&)?v=|shorts/|embed/|live/)|youtube-nocookie\.com/embed/)([A-Za-z0-9_-]{11})')
      .firstMatch(raw.trim());
  return m?.group(1);
}

/// Membuka halaman "Telusuri YouTube" (dari ikon video di editor bab).
/// Mengembalikan tautan video yang dipilih / ditempel, atau null jika dibatalkan.
Future<String?> openYoutubeSearch(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<String>(
      PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black54,
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) => const YoutubeSearchScreen(),
          transitionsBuilder: (_, a, __, child) => SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
              child: child)));
}

class YoutubeSearchScreen extends StatefulWidget {
  const YoutubeSearchScreen({super.key});
  @override
  State<YoutubeSearchScreen> createState() => _YoutubeSearchScreenState();
}

class _YoutubeSearchScreenState extends State<YoutubeSearchScreen> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Menempel tautan video langsung memilih video itu.
  void _changed(String t) {
    if (youtubeId(t) != null) Navigator.pop(context, t.trim());
  }

  Future<void> _search(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    if (youtubeId(q) != null) {
      Navigator.pop(context, q);
      return;
    }
    final uri = Uri.https(
        'www.youtube.com', '/results', {'search_query': q});
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Salin tautan videonya, lalu tempel di kolom pencarian'
            : 'Tidak bisa membuka YouTube')));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(top: top + 12),
      child: Material(
        color: const Color(0xFF121212),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFF3A3A3C))),
                  child: Row(children: [
                    const Icon(Icons.search, size: 26, color: Color(0xFFBDBDBD)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _c,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        keyboardType: TextInputType.url,
                        style: const TextStyle(fontSize: 18),
                        cursorColor: C.iosBlue,
                        onChanged: _changed,
                        onSubmitted: _search,
                        decoration: const InputDecoration(
                          hintText: 'Telusuri YouTube',
                          hintStyle:
                              TextStyle(color: Color(0xFF8E8E93), fontSize: 18),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('Batal',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  _YoutubeLogo(),
                  SizedBox(height: 6),
                  Text('Search YouTube or paste a url link',
                      style:
                          TextStyle(fontSize: 17, color: Color(0xFFBDBDBD))),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Logo YouTube sederhana (kotak merah + segitiga putih + tulisan).
class _YoutubeLogo extends StatelessWidget {
  const _YoutubeLogo();
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56,
          height: 40,
          decoration: BoxDecoration(
              color: const Color(0xFFFF0000),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 6),
        const Text('YouTube',
            style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
                color: Colors.white)),
      ]);
}

/// Kartu video YouTube yang disisipkan di dalam bab (thumbnail + tombol play).
class YoutubeCard extends StatelessWidget {
  final String url;
  final VoidCallback? onRemove;
  const YoutubeCard(this.url, {super.key, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final id = youtubeId(url);
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url.startsWith('http') ? url : 'https://$url'),
          mode: LaunchMode.externalApplication),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(fit: StackFit.expand, children: [
            Container(color: const Color(0xFF1E1E1E)),
            if (id != null)
              Image.network('https://img.youtube.com/vi/$id/hqdefault.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            Center(
              child: Container(
                width: 64,
                height: 44,
                decoration: BoxDecoration(
                    color: const Color(0xFFFF0000),
                    borderRadius: BorderRadius.circular(12)),
                child:
                    const Icon(Icons.play_arrow, color: Colors.white, size: 34),
              ),
            ),
            if (onRemove != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                        color: Color(0xCC000000), shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 20, color: Colors.white),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
