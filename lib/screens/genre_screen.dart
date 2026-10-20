import 'package:flutter/material.dart';
import '../api_service.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'notification_screen.dart';

class GenreScreen extends StatefulWidget {
  const GenreScreen({super.key});
  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  static const genres = [
    'Romansa', 'Fiksi Remaja', 'Fiksi Penggemar', 'Fantasi', 'Acak',
    'Cerita Pendek', 'Fiksi Umum', 'Chicklit', 'Humor', 'Aksi', 'Misteri',
    'Thriller', 'Spiritual', 'Fiksi Sejarah', 'Nonfiksi', 'Fiksi Ilmiah',
    'Petualangan', 'Horor', 'Vampir', 'Manusia Serigala', 'Paranormal',
    'Puisi', 'Klasik'
  ];
  final Set<String> _sel = {};

  void _toggle(String g) {
    setState(() {
      if (_sel.contains(g)) {
        _sel.remove(g);
      } else if (_sel.length < 3) {
        _sel.add(g);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 18),
            const Text('Apa 3 genre\nbacaan favoritmu?',
                style: TextStyle(
                    fontSize: 31, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 10),
            const Text(
                'Pilih minimal 1 genre untuk memulai dengan rekomendasi yang dipersonalisasi.',
                style: TextStyle(color: C.grey, fontSize: 18)),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(spacing: 8, runSpacing: 12, children: [
                  for (final g in genres)
                    GestureDetector(
                      onTap: () => _toggle(g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: _sel.contains(g)
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(g,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _sel.contains(g)
                                    ? Colors.black
                                    : Colors.white)),
                      ),
                    ),
                ]),
              ),
            ),
            WhiteButton('Lanjutkan', onTap: () async {
              if (_sel.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Pilih minimal 1 genre')));
                return;
              }
              AppState.genres = _sel.toList();
              try {
                if (Api.isLoggedIn) await Api.updateProfile(genres: _sel.toList());
              } catch (_) {
                // genre gagal tersimpan di server: lanjut saja, bisa diubah nanti
              }
              if (!mounted) return;
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationScreen()));
            }),
          ]),
        ),
      ),
    );
  }
}
