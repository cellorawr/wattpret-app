import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import '../api_service.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'profile_extras.dart';
import 'profile_wall.dart';
import 'story_screen.dart';

void openProfile(BuildContext context, String name) {
  final clean = name.startsWith('@') ? name.substring(1) : name;
  Navigator.of(context, rootNavigator: true)
      .push(MaterialPageRoute(builder: (_) => OtherProfileScreen(clean)));
}

int _h(String t) {
  var h = 7;
  for (final c in t.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

/// Profil penulis lain (Ikuti, Karya, Daftar Bacaan, Pengikut, Bio / Percakapan).
class OtherProfileScreen extends StatefulWidget {
  final String name;
  const OtherProfileScreen(this.name, {super.key});
  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  int _tab = 0;

  /// Data asli dari server (null bila profil ini hanya profil contoh).
  Map<String, dynamic>? _info;
  List<Profile>? _fol;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final d = await Api.profile(name);
      List<Profile>? f;
      try {
        f = [for (final j in await Api.followingOf(name)) AppState.profileFromJson(j)];
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _info = d;
        _fol = f;
      });
    } catch (_) {
      // bukan pengguna di server: tetap tampil sebagai profil contoh
    }
  }

  /// Ikuti / berhenti mengikuti, lalu segarkan jumlah pengikut dari server.
  Future<void> _toggleFollow() async {
    AppState.toggleFollow(name);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) _loadInfo();
  }

  final _scroll = ScrollController();
  final _worksKey = GlobalKey();
  final _listsKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double get _topPad => MediaQuery.of(context).padding.top;

  /// Tinggi header saat sudah mengecil (app bar + Bio/Percakapan).
  double get _minHeader => _topPad + 86;

  /// "KARYA" ditekan -> scroll otomatis ke bagian karya.
  Future<void> _goWorks() async {
    if (_tab != 0) {
      setState(() => _tab = 0);
      await WidgetsBinding.instance.endOfFrame;
    }
    final ctx = _worksKey.currentContext;
    if (ctx == null || !_scroll.hasClients) return;
    final ro = ctx.findRenderObject();
    if (ro == null) return;
    final off = RenderAbstractViewport.of(ro).getOffsetToReveal(ro, 0.0).offset -
        _minHeader;
    _scroll.animateTo(off.clamp(0.0, _scroll.position.maxScrollExtent).toDouble(),
        duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
  }

  /// "DAFTAR BACAAN" ditekan -> scroll otomatis ke bagian bawah (daftar bacaan).
  Future<void> _goLists() async {
    if (_tab != 0) {
      setState(() => _tab = 0);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!_scroll.hasClients) return;
    await _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    if (_scroll.hasClients &&
        _scroll.offset < _scroll.position.maxScrollExtent - 1) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _openFollowers(int tab) => Navigator.of(context, rootNavigator: true)
      .push(MaterialPageRoute(
          builder: (_) => FollowersScreen(initialTab: tab, name: name)));

  String get name => widget.name;

  List<Story> get _works {
    final mine = allStories.where((x) => x.author == name).toList();
    if (mine.isNotEmpty) return mine;
    final h = _h(name);
    return [
      for (var i = 0; i < 3; i++)
        () {
          final t = allStories[(h + i * 7) % allStories.length];
          return Story(t.title, name, t.views, t.parts, t.tags, t.color,
              t.textColor);
        }()
    ];
  }

  String get _followers {
    final i = _info;
    if (i != null) return fmtCount(int.tryParse('${i['followers_count']}') ?? 0);
    if (name == 'AmbassadorsID') return '80,6Rb';
    final h = _h(name);
    return '${(h % 280) + 12}Rb';
  }

  static const Color _gray = Color(0xFFA5A5A5);

  Widget _sectionHead(String title, String sub, {VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 4),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _gray, fontSize: 16, height: 1.1)),
              ]),
            ),
            const Icon(Icons.chevron_right, size: 30, color: Color(0xFFBDBDBD)),
          ]),
        ),
      );

  Widget _mini(IconData icon, String t) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: _gray),
        const SizedBox(width: 5),
        Text(t, style: const TextStyle(color: _gray, fontSize: 13.5)),
      ]);

  Widget _statsRow(Story s) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _mini(Icons.remove_red_eye, s.views),
          const SizedBox(width: 12),
          _mini(Icons.star, votesOf(s)),
          const SizedBox(width: 12),
          _mini(Icons.format_list_bulleted, '${s.parts}'),
        ]),
      );

  Widget _workCard(Story s) => GestureDetector(
        onTap: () => openStory(context, s),
        child: Container(
          width: 134,
          margin: const EdgeInsets.only(right: 11),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BookCover(s, w: 134, h: 209),
            const SizedBox(height: 6.5),
            Text(s.title.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 18.5),
            _statsRow(s),
          ]),
        ),
      );

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF3E3E3E)),
            borderRadius: BorderRadius.circular(20)),
        child: Text(t,
            style: const TextStyle(fontSize: 14, color: Color(0xFFD0D0D0))),
      );

  /// Kartu satu cerita di dalam daftar bacaan (sampul kiri, info kanan).
  Widget _listStoryCard(Story s) => GestureDetector(
        onTap: () => openStory(context, s),
        child: Padding(
          padding: const EdgeInsets.only(left: 11),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BookCover(s, w: 117, h: 181),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title.replaceAll('\n', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 6),
                      _statsRow(s),
                      const SizedBox(height: 8),
                      Text(_blurbFor(s).toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, height: 1.2, color: Color(0xFFBDBDBD))),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final t in s.tags.take(3)) _pill(t),
                      ]),
                      if (s.tags.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('+${s.tags.length - 3} lagi',
                              style: const TextStyle(fontSize: 14, color: C.grey)),
                        ),
                    ]),
              ),
            ),
          ]),
        ),
      );

  Widget _bio() {
    final works = _works;
    final h = _h(name);
    const places = ['di hati hero ft', 'Indonesia', 'Jawa Timur', 'Bumi bagian Asia'];
    final fol = _fol ?? otherFollowing(name);
    final listName = "$name's Reading List";
    void openList() => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
            builder: (_) => OtherReadingListScreen(name, listName, works.first)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 14, 0),
        child: Row(children: [
          const Icon(Icons.location_on, size: 17, color: _gray),
          const SizedBox(width: 6),
          Text(places[h % places.length],
              style: const TextStyle(fontSize: 15, color: _gray)),
        ]),
      ),
      const SizedBox(height: 9),
      Padding(
        padding: const EdgeInsets.only(left: 11),
        child: Text('Bergabung ${(h % 9) + 1} tahun lalu',
            style: const TextStyle(fontSize: 15, color: _gray)),
      ),
      const SizedBox(height: 26),
      KeyedSubtree(
        key: _worksKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHead('Dikerjakan oleh $name', '${works.length} Cerita Terpublikasi',
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                      builder: (_) => AuthorWorksScreen(name, works)))),
          const SizedBox(height: 17),
          SizedBox(
            height: 284,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 11),
              children: [for (final s in works) _workCard(s)],
            ),
          ),
        ]),
      ),
      const SizedBox(height: 22),
      _sectionHead('Mengikuti',
          '${_info != null ? '${_info!['following_count'] ?? fol.length}' : '${(h % 900) + 20}'} Profil',
          onTap: () => _openFollowers(1)),
      const SizedBox(height: 18),
      SizedBox(
        height: 130,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 12),
          children: [
            for (final p in fol)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => openProfile(context, p.name),
                child: Container(
                  width: 98,
                  margin: const EdgeInsets.only(right: 4),
                  child: Column(children: [
                    LetterAvatar(p.name, size: 67),
                    const SizedBox(height: 7.5),
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('${p.followers} Pengikut',
                        style: const TextStyle(color: _gray, fontSize: 13)),
                  ]),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Container(
        key: _listsKey,
        width: double.infinity,
        color: const Color(0xFF1E1E1E),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: const Text('DAFTAR BACAAN',
            style: TextStyle(fontSize: 13.5, letterSpacing: 0.3)),
      ),
      const SizedBox(height: 22),
      InkWell(
        onTap: openList,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(listName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 4),
                const Text('Daftar Bacaan • 1 cerita',
                    style: TextStyle(color: _gray, fontSize: 16, height: 1.1)),
              ]),
            ),
            const Icon(Icons.chevron_right, size: 30, color: Color(0xFFBDBDBD)),
          ]),
        ),
      ),
      const SizedBox(height: 17),
      _listStoryCard(works.first),
      const SizedBox(height: 60),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: AppState.followed,
        builder: (context, fol, _) {
          return CustomScrollView(controller: _scroll, slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _ProfileHeader(
                topPad: _topPad,
                name: name,
                following: fol.contains(name),
                works: '${_works.length}',
                lists: _info != null ? '${_info!['reading_lists_count'] ?? 1}' : '1',
                followers: _followers,
                tab: _tab,
                onTab: (i) => setState(() => _tab = i),
                onBack: () => Navigator.pop(context),
                onMore: () => showIosSheet(
                    context, ['Laporkan profil', 'Blokir'], (v) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('"$v" belum tersedia di versi demo')));
                }),
                onFollow: _toggleFollow,
                onWorks: _goWorks,
                onLists: _goLists,
                onFollowers: () => _openFollowers(0),
              ),
            ),
            SliverToBoxAdapter(child: _tab == 0
                ? _bio()
                : ProfileWall(
                    key: ValueKey('wall-$name'),
                    username: name,
                    mine: name == AppState.username)),
          ]);
        },
      ),
    );
  }
}

// ===========================================================================
// Header profil orang lain: latar perak, avatar, tombol Ikuti, statistik,
// Bio / Percakapan. Saat digulir mengecil menjadi app bar bernama + tab.
// ===========================================================================
class _ProfileHeader extends SliverPersistentHeaderDelegate {
  final double topPad;
  final String name, works, lists, followers;
  final bool following;
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onBack, onMore, onFollow, onWorks, onLists, onFollowers;
  _ProfileHeader({
    required this.topPad,
    required this.name,
    required this.following,
    required this.works,
    required this.lists,
    required this.followers,
    required this.tab,
    required this.onTab,
    required this.onBack,
    required this.onMore,
    required this.onFollow,
    required this.onWorks,
    required this.onLists,
    required this.onFollowers,
  });

  @override
  double get maxExtent => topPad + 322;
  @override
  double get minExtent => topPad + 86;
  @override
  bool shouldRebuild(covariant _ProfileHeader old) => true;

  Widget _stat(String n, String l, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(children: [
            Text(n,
                style: const TextStyle(
                    fontSize: 19, height: 1.2, color: Color(0xFFF2F2F2))),
            const SizedBox(height: 0.5),
            Text(l,
                style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.2,
                    color: Color(0xFFF2F2F2),
                    letterSpacing: 0.3)),
          ]),
        ),
      );

  Widget _followBtn() => GestureDetector(
        onTap: onFollow,
        child: Container(
          height: 33,
          padding: EdgeInsets.symmetric(horizontal: following ? 13 : 15),
          decoration: BoxDecoration(
              color: following ? const Color(0xFFA8A1E2) : Colors.transparent,
              border: following ? null : Border.all(color: Colors.white, width: 1.5),
              borderRadius: BorderRadius.circular(5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(following ? Icons.how_to_reg_outlined : Icons.person_add_alt_1,
                size: 20, color: Colors.white),
            const SizedBox(width: 9),
            Text(following ? 'Mengikuti' : 'Ikuti',
                style: TextStyle(
                    fontSize: 15.5,
                    height: 1.1,
                    fontWeight: following ? FontWeight.w600 : FontWeight.w700,
                    color: following ? const Color(0xFFF7F5FF) : Colors.white)),
          ]),
        ),
      );

  Widget _segment() => Container(
        height: 33,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: const Color(0x2E000000),
            borderRadius: BorderRadius.circular(6)),
        child: Row(children: [
          for (var i = 0; i < 2; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTab(i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: tab == i ? Colors.white : Colors.transparent,
                      boxShadow: tab == i
                          ? const [
                              BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1))
                            ]
                          : null,
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(i == 0 ? 'Bio' : 'Percakapan',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tab == i
                              ? const Color(0xFFA8A8A8)
                              : Colors.white)),
                ),
              ),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    final range = maxExtent - minExtent;
    final p = (shrink / range).clamp(0.0, 1.0).toDouble();
    final fade = (1 - p * 1.8).clamp(0.0, 1.0).toDouble();
    final titleFade = ((p - 0.65) / 0.35).clamp(0.0, 1.0).toDouble();
    final t = topPad;
    return Stack(clipBehavior: Clip.hardEdge, children: [
      Positioned.fill(child: CustomPaint(painter: _SilverPainter())),
      // isi yang memudar saat digulir
      Positioned.fill(
        child: IgnorePointer(
          ignoring: fade < 0.5,
          child: Opacity(
            opacity: fade,
            child: Stack(children: [
              Positioned(
                  top: t + 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5)),
                      child: LetterAvatar(name, size: 112),
                    ),
                  )),
              Positioned(
                  top: t + 126,
                  left: 12,
                  right: 12,
                  child: Text(name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 26, height: 1.0, fontWeight: FontWeight.w300))),
              Positioned(
                  top: t + 156,
                  left: 0,
                  right: 0,
                  child: Text('@$name',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, height: 1.0, color: Color(0xFFF0F0F0)))),
              Positioned(
                  top: t + 183,
                  left: 0,
                  right: 0,
                  child: Center(child: _followBtn())),
              Positioned(
                top: t + 228,
                left: 11,
                right: 11,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _stat(works, 'KARYA', onWorks),
                  _stat(lists, 'DAFTAR BACAAN', onLists),
                  _stat(followers, 'PENGIKUT', onFollowers),
                ]),
              ),
            ]),
          ),
        ),
      ),
      // judul app bar saat mengecil
      Positioned(
          top: t,
          left: 56,
          right: 56,
          height: 38,
          child: Opacity(
            opacity: titleFade,
            child: Center(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          )),
      // panah kembali & titik tiga
      Positioned(
          top: t,
          left: 8,
          width: 44,
          height: 38,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: const Icon(Icons.arrow_back, size: 24))),
      Positioned(
          top: t,
          right: 14,
          width: 44,
          height: 38,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onMore,
              child: const Icon(Icons.more_horiz, size: 26))),
      Positioned(left: 13, right: 13, bottom: 11, child: _segment()),
    ]);
  }
}

/// Latar perak bermotif riak air (pengganti foto sampul).
class _SilverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFCDCDCF), Color(0xFFAAAAAC), Color(0xFFB9B9BB)])
              .createShader(Offset.zero & size));
    final w = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    for (var i = 0; i < 16; i++) {
      final y = size.height * (i / 15.0);
      final path = Path()..moveTo(-20, y);
      for (double x = -20; x <= size.width + 20; x += 20) {
        path.lineTo(
            x, y + math.sin(x / 38 + i * 1.7) * 9 + math.cos(x / 61 + i) * 6);
      }
      canvas.drawPath(
          path,
          w
            ..strokeWidth = 7 + (i % 4) * 5
            ..color = (i.isEven ? Colors.white : Colors.black)
                .withOpacity(i.isEven ? 0.20 : 0.07));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ===========================================================================
// Halaman daftar bacaan milik orang lain (judul, pemilik, jumlah cerita, Suka).
// ===========================================================================
class OtherReadingListScreen extends StatefulWidget {
  final String owner, title;
  final Story story;
  const OtherReadingListScreen(this.owner, this.title, this.story, {super.key});
  @override
  State<OtherReadingListScreen> createState() => _OtherReadingListScreenState();
}

class _OtherReadingListScreenState extends State<OtherReadingListScreen> {
  bool get _liked => AppState.isListLiked(widget.owner, widget.title);

  void _toggleLike() {
    AppState.toggleListLike(widget.owner, widget.title, () => [widget.story]);
    setState(() {});
  }

  Widget _mini(IconData icon, String t) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: const Color(0xFFA5A5A5)),
        const SizedBox(width: 5),
        Text(t, style: const TextStyle(color: Color(0xFFA5A5A5), fontSize: 14)),
      ]);

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF3E3E3E)),
            borderRadius: BorderRadius.circular(20)),
        child: Text(t,
            style: const TextStyle(fontSize: 14, color: Color(0xFFD0D0D0))),
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
        centerTitle: false,
        leadingWidth: 56,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: const Padding(
                padding: EdgeInsets.only(left: 22, right: 10),
                child: Icon(Icons.arrow_back, size: 23)),
          ),
        ),
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Tautan daftar disalin'))),
            child: const Padding(
                padding: EdgeInsets.only(right: 22, left: 10),
                child: SendIcon(size: 24)),
          ),
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFF2E2E2E))),
      ),
      body: ListView(padding: EdgeInsets.zero, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 16, 15, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 6.5),
                  Row(children: [
                    LetterAvatar(widget.owner, size: 19),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(widget.owner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFA8A8A8))),
                    ),
                  ]),
                  const SizedBox(height: 20.5),
                  const Text('1 cerita', style: TextStyle(fontSize: 16)),
                ]),
              ),
              GestureDetector(
                onTap: _toggleLike,
                child: Column(children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                        color: Color(0xFF2E2E30), shape: BoxShape.circle),
                    child: Icon(_liked ? Icons.favorite : Icons.favorite_border,
                        size: 24, color: _liked ? C.red : Colors.white),
                  ),
                  const SizedBox(height: 5),
                  const Text('Suka',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                ]),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => openStory(context, s),
          child: Container(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF2E2E2E)))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              BookCover(s, w: 117, h: 183),
              const SizedBox(width: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title.replaceAll('\n', ' '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 20, color: Color(0xFFD0D0D0))),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _mini(Icons.remove_red_eye, s.views),
                            const SizedBox(width: 16),
                            _mini(Icons.star, votesOf(s)),
                            const SizedBox(width: 16),
                            _mini(Icons.format_list_bulleted, '${s.parts}'),
                          ]),
                        ),
                        const SizedBox(height: 3),
                        Text(_blurbFor(s).toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14.5,
                                height: 1.3,
                                color: Color(0xFFBDBDBD))),
                        const SizedBox(height: 10),
                        Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (final t in s.tags.take(3)) _pill(t),
                              if (s.tags.length > 3)
                                Text('+${s.tags.length - 3} lagi',
                                    style: const TextStyle(
                                        fontSize: 14, color: Color(0xFFBDBDBD))),
                            ]),
                      ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ===========================================================================
// "Dikerjakan oleh ..." milik penulis lain: daftar cerita dengan sampul besar,
// statistik, dan cuplikan sinopsis.
// ===========================================================================
/// Ringkasan singkat cerita (dipakai juga oleh daftar bacaan).
String storyBlurb(Story s) => _blurbFor(s);

String _blurbFor(Story s) {
  if (s.synopsis.isNotEmpty) return s.synopsis;
  final t = s.title.replaceAll('\n', ' ');
  final tag = s.tags.isEmpty ? 'cerita' : s.tags.first;
  const starts = [
    'Tidak ada yang menyangka bahwa pertemuan itu akan mengubah segalanya bagi',
    'Selama ini ia selalu berusaha baik-baik saja, namun sejak',
    'Ada satu rahasia yang selama ini disimpan rapat-rapat dalam kisah',
  ];
  return '${starts[_h(t) % starts.length]} "$t". Sebuah kisah $tag yang '
      'perlahan membawa para tokohnya pada pilihan yang sulit dan perasaan '
      'yang tidak bisa lagi disembunyikan.';
}

class AuthorWorksScreen extends StatelessWidget {
  final String author;
  final List<Story> works;
  const AuthorWorksScreen(this.author, this.works, {super.key});

  Widget _row(BuildContext context, Story s) {
    final title = s.title.replaceAll('\n', ' ');
    return InkWell(
      onTap: () => openStory(context, s),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: BookCover(s, w: 117, h: 183),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 14, 8),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Row(children: [
                      MiniStat(Icons.remove_red_eye_outlined, s.views),
                      const SizedBox(width: 14),
                      MiniStat(Icons.star, votesOf(s)),
                      const SizedBox(width: 14),
                      MiniStat(Icons.format_list_bulleted, '${s.parts}'),
                    ]),
                    const SizedBox(height: 10),
                    Text(_blurbFor(s),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, height: 1.3, color: Color(0xFFBDBDBD))),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
        centerTitle: false,
        titleSpacing: 4,
        leadingWidth: 56,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: const Padding(
                padding: EdgeInsets.only(left: 22, right: 10),
                child: Icon(Icons.arrow_back, size: 23)),
          ),
        ),
        title: Text('Dikerjakan oleh $author',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                    builder: (_) => AuthorWorksSearchScreen(works, _row))),
            child: const Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Icon(Icons.search, size: 27)),
          ),
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFF2E2E2E))),
      ),
      body: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: works.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFF2E2E2E)),
        itemBuilder: (c, i) => _row(c, works[i]),
      ),
    );
  }
}


// ===========================================================================
// Pencarian di "Dikerjakan oleh ...": kolom Telusuri + Batal + Judul/Tag/Profil.
// ===========================================================================
class AuthorWorksSearchScreen extends StatefulWidget {
  final List<Story> works;
  final Widget Function(BuildContext, Story) rowBuilder;
  const AuthorWorksSearchScreen(this.works, this.rowBuilder, {super.key});
  @override
  State<AuthorWorksSearchScreen> createState() => _AuthorWorksSearchState();
}

class _AuthorWorksSearchState extends State<AuthorWorksSearchScreen> {
  final _c = TextEditingController();
  int _mode = -1; // -1 = judul + tag, 0 judul, 1 tag, 2 profil

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  List<Story> get _results {
    final q = _c.text.trim().toLowerCase();
    if (q.isEmpty || _mode == 2) return const [];
    return widget.works.where((s) {
      final t = s.title.toLowerCase().contains(q);
      final g = s.tags.any((x) => x.toLowerCase().contains(q));
      return _mode == 0 ? t : _mode == 1 ? g : (t || g);
    }).toList();
  }

  Widget _chip(String t, int i) {
    final on = _mode == i;
    return GestureDetector(
      onTap: () => setState(() => _mode = on ? -1 : i),
      child: Container(
        height: 28,
        margin: const EdgeInsets.only(right: 9.5),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: on ? const Color(0xFF3A3A3C) : const Color(0xFF1D1D1F),
            borderRadius: BorderRadius.circular(4)),
        child: Text(t,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final res = _results;
    final typed = _c.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: EdgeInsets.only(top: mq.padding.top + 5),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Container(
                height: 37.5,
                margin: const EdgeInsets.only(left: 15),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF3A3A3C)),
                    borderRadius: BorderRadius.circular(5)),
                child: Row(children: [
                  const Icon(Icons.search, size: 21, color: Color(0xFFB0B0B2)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _c,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      cursorColor: const Color(0xFF4A5BE8),
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Telusuri',
                        hintStyle:
                            TextStyle(fontSize: 16, color: Color(0xFF9A9A9C)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 15, 8),
                child: Text('Batal',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
          const SizedBox(height: 35),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 28.5),
              child: Row(children: [_chip('Judul', 0), _chip('Tag', 1), _chip('Profil', 2)]),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: typed && res.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Align(
                        alignment: Alignment.topCenter,
                        child: Text('Tidak ada hasil',
                            style: TextStyle(color: C.grey, fontSize: 16))),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: res.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFF262626)),
                    itemBuilder: (ctx, i) => widget.rowBuilder(ctx, res[i]),
                  ),
          ),
        ]),
      ),
    );
  }
}
