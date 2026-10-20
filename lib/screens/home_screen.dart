import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'list_screen.dart';
import 'profile_screen.dart';
import 'reward_screen.dart';
import 'settings_pages.dart' show PremiumScreen;
import 'story_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openList(BuildContext c, String title, List<Story> list) =>
      Navigator.push(
          c, MaterialPageRoute(builder: (_) => StoryListScreen(title, list)));

  void _premium(BuildContext c) => Navigator.of(c, rootNavigator: true)
      .push(MaterialPageRoute(builder: (_) => const PremiumScreen()));

  void _gift(BuildContext c) => Navigator.push(
      c, MaterialPageRoute(builder: (_) => const RewardScreen()));

  Widget _title(BuildContext c, String t, List<Story> list,
          {String? sub, bool chevron = false}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 8, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(sub,
                  style: const TextStyle(
                      color: Color(0xFFBDBDBD), fontSize: 17)),
            ),
          InkWell(
            onTap: chevron ? () => _openList(c, t, list) : null,
            child: Row(children: [
              Expanded(
                child: Text(t,
                    style: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.w800)),
              ),
              if (chevron) const Icon(Icons.chevron_right, size: 30),
            ]),
          ),
        ]),
      );

  Widget _featuredRow(BuildContext c, List<Story> list,
          {bool badge = false}) =>
      SizedBox(
        height: 262,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            final s = list[i];
            return GestureDetector(
              onTap: () => openStory(c, s),
              child: SizedBox(
                width: 93,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  badge && i < 3 ? CoverWithBadge(s) : BookCover(s),
                  const SizedBox(height: 12),
                  StatChip(s.tags.first),
                  const SizedBox(height: 10),
                  ViewsRow(s.views),
                ]),
              ),
            );
          },
        ),
      );

  /// "Direkomendasikan untukmu": satu sampul besar + kotak 2x2 + sampul besar.
  Widget _collageRow(BuildContext c, List<Story> l) {
    Widget big(Story s) => GestureDetector(
        onTap: () => openStory(c, s), child: BookCover(s, w: 144, h: 236));
    Widget small(Story s) => GestureDetector(
        onTap: () => openStory(c, s), child: BookCover(s, w: 74, h: 114));
    return SizedBox(
      height: 236,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          big(l[0]),
          const SizedBox(width: 10),
          Column(children: [
            Row(children: [small(l[1]), const SizedBox(width: 10), small(l[2])]),
            const SizedBox(height: 8),
            Row(children: [small(l[3]), const SizedBox(width: 10), small(l[4])]),
          ]),
          const SizedBox(width: 10),
          big(l[5]),
        ],
      ),
    );
  }

  Widget _coverRow(BuildContext c, List<Story> list) => SizedBox(
        height: 145,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) => GestureDetector(
              onTap: () => openStory(c, list[i]), child: BookCover(list[i])),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ServerStories.version,
      builder: (context, _, __) {
    final srv = ServerStories.loaded;
    final featuredL = srv ? ServerStories.top(4) : featured;
    final finalistsL =
        srv && storiesFor('Romansa').length >= 4
            ? storiesFor('Romansa').take(4).toList()
            : finalists;
    final teen = storiesFor('Fiksi Remaja');
    final fans = storiesFor('Fiksi Penggemar');
    var recs = [...storiesFor('Fantasi'), ...storiesFor('Misteri')];
    if (recs.length < 6) recs = [...recs, ...allStories].take(6).toList();
    final next = [...storiesFor('Aksi'), ...storiesFor('Thriller')];
    final like = [...storiesFor('Humor'), ...storiesFor('Horor')];
    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: 20), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
          child: Row(children: [
            const WLogo(size: 38),
            const Spacer(),
            GestureDetector(
              onTap: () => _premium(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFF2B2D3F),
                    borderRadius: BorderRadius.circular(22)),
                child: Row(children: const [
                  Icon(Icons.bolt, color: Color(0xFF8C8CFF), size: 20),
                  SizedBox(width: 4),
                  Text('Coba\nPremium',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.2)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _gift(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    color: Color(0xFFFFC72C), shape: BoxShape.circle),
                child:
                    const Icon(Icons.card_giftcard, color: Color(0xFF2B2B2B)),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: const Avatar(size: 38),
            ),
          ]),
        ),
        GestureDetector(
          onTap: () =>
              _openList(context, 'Finalis Romansa Non-Dewasa', finalistsL),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            height: 170,
            decoration: BoxDecoration(
                color: const Color(0xFFC70F4F),
                borderRadius: BorderRadius.circular(6)),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              Positioned(
                right: -20,
                bottom: -10,
                child: Container(
                  width: 190,
                  height: 150,
                  decoration: const BoxDecoration(
                      color: Color(0xFF3A2A25),
                      borderRadius:
                          BorderRadius.only(topLeft: Radius.circular(90))),
                  child: const Icon(Icons.person,
                      size: 110, color: Color(0xFFD9A98A)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SIAP DIBUAT',
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              height: 1.05)),
                      const Text('BERBUNGA-BUNGA',
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFF0A8),
                              height: 1.05)),
                      const SizedBox(height: 6),
                      const Text('Lihat para finalis Romansa\nNon-Dewasa tahun ini',
                          style: TextStyle(fontSize: 15, height: 1.25)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1.5),
                            borderRadius: BorderRadius.circular(30)),
                        child: const Text('CEK DAFTAR PENDEK',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                fontSize: 13)),
                      ),
                    ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 28),
        _title(context, 'Cerita pilihan untuk kamu', featuredL),
        _featuredRow(context, featuredL, badge: true),
        const SizedBox(height: 8),
        _title(context, 'Siap dibuat berbunga-bunga', finalistsL,
            sub: 'Lihat para finalis Romansa Non-Dewasa tahun ini'),
        _coverRow(context, finalistsL),
        const SizedBox(height: 28),
        _title(context, 'Karena kamu menyukai fiksiremaja', teen,
            chevron: true),
        _featuredRow(context, teen),
        const SizedBox(height: 8),
        _title(context, 'Direkomendasikan untukmu', recs),
        _collageRow(context, recs),
        const SizedBox(height: 28),
        _title(context, 'POV: Musim Y/N kamu', fans,
            sub: 'Cerita K-pop x Pembaca'),
        _featuredRow(context, fans),
        const SizedBox(height: 8),
        _title(context, 'Bacaanmu selanjutnya', next),
        _featuredRow(context, next),
        const SizedBox(height: 8),
        _title(context, 'Kami pikir kamu akan menyukainya', like),
        _featuredRow(context, like),
      ]),
    );
      },
    );
  }
}
