import 'package:flutter/material.dart';
import 'story_picker.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'list_screen.dart';
import 'other_profile_screen.dart' show openProfile;
import 'profile_extras.dart';
import 'profile_wall.dart';
import 'works_screen.dart';
import 'edit_work_screen.dart';
import 'reward_screen.dart';
import 'settings_screen.dart';
import 'story_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;
  bool _open = true;
  static const double _cardW = 341, _coverW = 117, _coverH = 181;
  final _scroll = ScrollController();
  final _worksKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Angka statistik di header profil; bisa ditekan.
  Widget _stat(String n, String l, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: [
            Text(n, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(l,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFF6E6DB),
                    letterSpacing: 0.3)),
          ]),
        ),
      );

  /// "DAFTAR BACAAN" ditekan -> otomatis scroll ke bagian daftar bacaan (bawah).
  void _scrollToLists() {
    if (_tab != 0 || !_open) {
      setState(() {
        _tab = 0;
        _open = true;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scroll.hasClients) return;
      await _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
      // panjang daftar bisa bertambah setelah dibangun; pastikan sampai bawah
      if (_scroll.hasClients &&
          _scroll.offset < _scroll.position.maxScrollExtent - 1) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  /// "KARYA" ditekan -> otomatis scroll ke bagian karya ("Dikerjakan oleh ...").
  void _scrollToWorks() {
    if (_tab != 0) setState(() => _tab = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _worksKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          alignment: 0.0);
    });
  }

  void _openFollowers(int tab) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FollowersScreen(initialTab: tab)));

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  void _topUp() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RewardScreen(initialTab: 0)));

  Future<void> _editBio() async {
    final r = await Navigator.of(context, rootNavigator: true).push<String>(
        MaterialPageRoute(
            builder: (_) => BioEditScreen(initial: AppState.bio.value)));
    if (r != null) AppState.bio.value = r.trim();
  }

  void _pickStory(ReadingList l) => showStoryPicker(context, l);

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF3E3E3E)),
            borderRadius: BorderRadius.circular(20)),
        child: Text(t,
            style: const TextStyle(fontSize: 14, color: Color(0xFFD0D0D0))),
      );

  Widget _sectionHead(String title, String sub, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 8, 0),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: C.grey, fontSize: 16)),
              ]),
            ),
            const Icon(Icons.chevron_right, size: 30, color: C.grey),
          ]),
        ),
      );

  /// "Dikerjakan oleh ..." : karya terpublikasi + draf.
  Widget _worksSection(String u) {
    return ValueListenableBuilder<List<Work>>(
      valueListenable: AppState.works,
      builder: (ctx, list, _) {
        if (list.isEmpty) return const SizedBox.shrink();
        final pub = list.where((w) => w.published).length;
        final drafts = list.fold<int>(0, (a, w) => a + w.draftCount);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHead(
              'Dikerjakan oleh $u',
              '$pub Cerita Terpublikasi • $drafts draf (hanya dapat dilihat oleh kamu)',
              () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => WorksScreen(title: 'Dikerjakan oleh $u')))),
          const SizedBox(height: 14),
          SizedBox(
            height: _coverH,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12),
              children: [
                for (final w in list)
                  GestureDetector(
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                            builder: (_) => EditWorkScreen(work: w))),
                    child: Container(
                      width: _cardW,
                      margin: const EdgeInsets.only(right: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        BookCover(w.toStory(), w: _coverW, h: _coverH),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(w.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 21)),
                                const SizedBox(height: 4),
                                Text(w.synopsis,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 16, color: C.grey)),
                              ]),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ]);
      },
    );
  }

  /// "Mengikuti  15 Profil" + deretan avatar.
  Widget _followingSection() => ValueListenableBuilder<List<Profile>>(
      valueListenable: AppState.followingList,
      builder: (_, __, ___) => _followingBody());

  Widget _followingBody() {
    final f = AppState.following;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHead('Mengikuti', '${f.length} Profil', () => _openFollowers(1)),
      const SizedBox(height: 14),
      SizedBox(
        height: 132,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 12),
          children: [
            for (final p in f)
              GestureDetector(
               behavior: HitTestBehavior.opaque,
               onTap: () => openProfile(context, p.name),
               child: Container(
                width: 108,
                margin: const EdgeInsets.only(right: 4),
                child: Column(children: [
                  LetterAvatar(p.name, size: 72),
                  const SizedBox(height: 8),
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16)),
                  Text('${p.followers} Pengikut',
                      style: const TextStyle(color: C.grey, fontSize: 13)),
                ]),
              )),
          ],
        ),
      ),
      const SizedBox(height: 18),
    ]);
  }

  /// Kartu satu cerita di dalam daftar bacaan.
  Widget _storyCard(Story s) {
    final quote = s.synopsis.isNotEmpty ? '"${s.synopsis}"' : '';
    return GestureDetector(
      onTap: () => openStory(context, s),
      child: Container(
        width: _cardW,
        margin: const EdgeInsets.only(right: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BookCover(s, w: _coverW, h: _coverH),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.title.replaceAll('\n', ' '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  MiniStat(Icons.remove_red_eye, s.views),
                  const SizedBox(width: 10),
                  MiniStat(Icons.star, votesOf(s)),
                  const SizedBox(width: 10),
                  MiniStat(Icons.format_list_bulleted, '${s.parts}'),
                ]),
              ),
              if (quote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(quote,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: Color(0xFFBDBDBD))),
              ],
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
        ]),
      ),
    );
  }

  /// Halaman detail daftar bacaan (judul, jumlah cerita, Suka, daftar cerita).
  void _openList(ReadingList l) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => StoryListScreen(AppState.listName(l), l.stories,
              isPublic: l.isPublic, list: l, onAdd: () => _pickStory(l))));

  /// Bar DAFTAR BACAAN ditekan -> menu kecil "Edit daftar bacaan" muncul di
  /// bawah bar, di atas layar yang diredupkan (bagian tidak ikut menutup).
  void _listMenu(BuildContext rowCtx) {
    final box = rowCtx.findRenderObject() as RenderBox;
    final off = box.localToGlobal(Offset.zero);
    final rowH = box.size.height;
    final w = MediaQuery.of(context).size.width;
    showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (ctx, _, __) => Stack(children: [
        Positioned(
          left: w * 0.203,
          right: 10,
          top: off.dy + rowH + 10.5,
          child: Material(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(3),
            child: InkWell(
              borderRadius: BorderRadius.circular(3),
              onTap: () {
                Navigator.pop(ctx);
                showEditReadingLists(context);
              },
              child: const SizedBox(
                height: 47,
                child: Row(children: [
                  SizedBox(width: 13),
                  Icon(Icons.settings, size: 20, color: Color(0xFFE6E6E6)),
                  SizedBox(width: 13),
                  Text('Edit daftar bacaan',
                      style: TextStyle(
                          fontSize: 19,
                          color: Color(0xFFF2F2F2),
                          decoration: TextDecoration.none)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _readingListBlock(ReadingList l) {
    final name = AppState.listName(l);
    final stories = l.stories;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 4, 0),
          child: Row(children: [
            Expanded(
              child: Builder(builder: (rowCtx) => InkWell(
                onTap: () => _openList(l),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(l.isPublic ? Icons.public : Icons.lock_outline,
                        color: C.grey, size: 20),
                    const SizedBox(width: 8),
                    Text('Daftar Bacaan • ${stories.length} cerita',
                        style: const TextStyle(color: C.grey, fontSize: 16)),
                  ]),
                ]),
              )),
            ),
            InkWell(
              onTap: () => _openList(l),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Icon(Icons.chevron_right, size: 30, color: C.grey),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: _coverH,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12),
            children: [
              for (final s in stories) _storyCard(s),
              GestureDetector(
                onTap: () => _pickStory(l),
                child: CustomPaint(
                  painter: DashedRect(),
                  child: const SizedBox(
                      width: _coverW,
                      height: _coverH,
                      child: Icon(Icons.add,
                          size: 56, color: Color(0xFFE0D6D0))),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = AppState.username;
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([
          AppState.library,
          AppState.coins,
          AppState.bio,
          AppState.avatarBytes,
          AppState.coverBytes,
          AppState.works,
          AppState.readingLists
        ]),
        builder: (context, _) {
          final bio = AppState.bio.value;
          return ListView(controller: _scroll, padding: EdgeInsets.zero, children: [
            Container(
              decoration: BoxDecoration(
                  color: C.tan,
                  image: AppState.coverBytes.value == null
                      ? null
                      : DecorationImage(
                          image: MemoryImage(AppState.coverBytes.value!),
                          fit: BoxFit.cover)),
              child: SafeArea(
                bottom: false,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 14, 0),
                    child: Row(children: [
                      IconButton(
                          icon: const Icon(Icons.arrow_back, size: 28),
                          onPressed: () => Navigator.pop(context)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.settings, size: 28),
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()))),
                    ]),
                  ),
                  const Avatar(size: 96),
                  const SizedBox(height: 12),
                  Text(u,
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w300)),
                  Text('@$u',
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xFFF6E6DB))),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _topUp,
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.only(left: 2, right: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                              color: const Color(0xFFE5A800), width: 1)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                              color: Color(0xFFFFC72C), shape: BoxShape.circle),
                          child: const WLogo(size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 18),
                        Text('${AppState.coins.value}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 22),
                        Container(
                            width: 1, height: 46, color: const Color(0xFF3A3A3A)),
                        const SizedBox(width: 14),
                        const Icon(Icons.add, size: 28),
                        const SizedBox(width: 12),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _stat(
                        '${AppState.works.value.length}',
                        'KARYA',
                        _scrollToWorks),
                    _stat('${AppState.readingLists.value.length}',
                        'DAFTAR BACAAN', _scrollToLists),
                    ValueListenableBuilder<int>(
                      valueListenable: AppState.myFollowers,
                      builder: (_, n, __) =>
                          _stat(fmtCount(n), 'PENGIKUT', () => _openFollowers(0)),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Segmented(
                    labels: const ['Bio', 'Percakapan'],
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                    bg: const Color(0xFFA48878),
                    selBg: Colors.white,
                    selText: const Color(0xFF9A9A9A),
                    divider: Colors.transparent,
                    text: Colors.white,
                    height: 32,
                    fontSize: 15,
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
            if (_tab == 0) ...[
              GestureDetector(
                onTap: _editBio,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 72),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                          bio.isEmpty
                              ? 'Ketuk di sini untuk menambahkan deskripsi ....'
                              : bio,
                          style: TextStyle(
                              fontSize: 17,
                              color: bio.isEmpty
                                  ? const Color(0xFFAAAAAA)
                                  : Colors.white)),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text('Bergabung baru saja',
                            style: TextStyle(fontSize: 16, color: C.grey)),
                      ],
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              KeyedSubtree(key: _worksKey, child: _worksSection(u)),
              _followingSection(),
              Builder(builder: (barCtx) => InkWell(
                onTap: () => _listMenu(barCtx),
                child: Container(
                  color: const Color(0xFF1E1E1E),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Row(children: [
                    const Text('DAFTAR BACAAN',
                        style: TextStyle(fontSize: 15, letterSpacing: 0.3)),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_up, size: 26),
                  ]),
                ),
              )),
              if (_open)
                Container(
                  color: C.bg,
                  padding: const EdgeInsets.only(top: 4, bottom: 10),
                  child: Column(children: [
                    for (final l in AppState.readingLists.value)
                      _readingListBlock(l),
                  ]),
                ),
            ] else
              ProfileWall(
                  key: const ValueKey('wall-mine'),
                  username: AppState.username,
                  mine: true),
          ]);
        },
      ),
    );
  }
}


/// Layar penuh "Bio": kolom teks kosong + tombol Simpan (seperti aplikasi asli).
class BioEditScreen extends StatefulWidget {
  final String initial;
  const BioEditScreen({super.key, this.initial = ''});
  @override
  State<BioEditScreen> createState() => _BioEditScreenState();
}

class _BioEditScreenState extends State<BioEditScreen> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        toolbarHeight: 46,
        centerTitle: true,
        leadingWidth: 56,
        backgroundColor: const Color(0xFF121212),
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
        title: const Text('Bio',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context, _c.text),
            child: const Padding(
              padding: EdgeInsets.only(right: 24, left: 12),
              child: Center(
                child: Text('Simpan',
                    style: TextStyle(fontSize: 16.5, color: Colors.white)),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFF2E2E2E))),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(13, 6, 13, 0),
        child: TextField(
          controller: _c,
          autofocus: true,
          expands: true,
          maxLines: null,
          minLines: null,
          textAlignVertical: TextAlignVertical.top,
          cursorColor: const Color(0xFF4A5BE8),
          cursorHeight: 19,
          style: const TextStyle(fontSize: 17, height: 1.2),
          decoration: const InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.only(top: 6),
          ),
        ),
      ),
    );
  }
}
