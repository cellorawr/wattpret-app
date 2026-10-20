import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'list_screen.dart';

/// Halaman "Daftar bacaan yang disukai".
/// - Belum ada yang disukai: kolase kosong + dua kartu penjelasan.
/// - Ada yang disukai: ringkasan "N daftar • Tersembunyi dari profil kamu"
///   lalu daftar bacaan lengkap dengan kolase cover, pemilik, dan jumlah cerita.
class LikedListsScreen extends StatelessWidget {
  const LikedListsScreen({super.key});

  Widget _infoCard(IconData icon, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2E2E2E)),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icon, size: 26, color: const Color(0xFFBDBDBD)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 16.5, height: 1.35, color: Color(0xFFBDBDBD))),
          ),
        ]),
      );

  Widget _empty() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const WCollage(size: 113),
            const SizedBox(height: 26),
            const Text('Tidak ada daftar bacaan yang disukai',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 22),
            _infoCard(Icons.favorite_border,
                'Sukai daftar bacaan untuk mengunjunginya kembali di sini'),
            const SizedBox(height: 18),
            _infoCard(Icons.lock_outline,
                'Daftar bacaan yang kamu sukai bersifat pribadi dan tersembunyi dari profil kamu'),
          ]),
        ),
      );

  Widget _row(BuildContext context, LikedList l) {
    final stories = l.stories;
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StoryListScreen(l.name, stories,
                  isPublic: true, owner: l.owner))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          WCollage(size: 115, stories: stories),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 8),
              Row(children: [
                LetterAvatar(l.owner, size: 24),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(l.owner,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF9E9E9E))),
                ),
              ]),
              const SizedBox(height: 8),
              Text('${stories.length} cerita',
                  style: const TextStyle(fontSize: 16, color: C.grey)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _list(BuildContext context, List<LikedList> items) =>
      ListView(padding: const EdgeInsets.only(bottom: 20), children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${items.length} daftar',
                style: const TextStyle(fontSize: 17, color: C.grey)),
            const SizedBox(width: 10),
            Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: Color(0xFF555555), shape: BoxShape.circle)),
            const SizedBox(width: 10),
            const Icon(Icons.lock_outline, size: 20, color: C.grey),
            const SizedBox(width: 6),
            const Text('Tersembunyi dari profil kamu',
                style: TextStyle(fontSize: 17, color: C.grey)),
          ]),
        ),
        for (final l in items) _row(context, l),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: wAppBar(context, title: 'Daftar bacaan yang disukai'),
        body: ListenableBuilder(
          listenable:
              Listenable.merge([AppState.likedLists, AppState.readingLists]),
          builder: (_, __) {
            final items = AppState.likedLists.value;
            return items.isEmpty ? _empty() : _list(context, items);
          },
        ),
      );
}
