import 'package:flutter/material.dart';
import '../api_service.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'other_profile_screen.dart' show openProfile;
import 'profile_wall.dart';
import 'reading_list_sheets.dart';

// ===========================================================================
// Mengikuti (daftar profil yang diikuti)
// ===========================================================================
/// Dipertahankan agar kode lama tetap jalan: membuka tab "Mengikuti".
class FollowingScreen extends StatelessWidget {
  const FollowingScreen({super.key});
  @override
  Widget build(BuildContext context) => const FollowersScreen(initialTab: 1);
}

// ===========================================================================
// Pengikut / Mengikuti (satu halaman dengan dua tab, seperti aplikasi asli)
// ===========================================================================
// Contoh daftar profil untuk akun lain (dipilih berdasarkan nama akun).
const _followingPool = <(String, String)>[
  ('Mellyana21', '110Rb'),
  ('yudiiipratama', '12Rb'),
  ('RahmatShafrullah', '194'),
  ('edelwiss123', '121Rb'),
  ('mncnyr', '8Rb'),
  ('pjm11jjk', '31Rb'),
  ('readmorrow', '2,3Rb'),
  ('Citadinastia', '640'),
  ('itzrdwn_', '97Rb'),
  ('cantikazhr', '15Rb'),
];

const _followersPool = <(String, String)>[
  ('yummpolqa', '320'),
  ('mujilatul27', '1,2Rb'),
  ('IndrianiZuniati12', '45'),
  ('RiharaSenja', '9Rb'),
  ('hdhdhxh', '12'),
  ('mirnaninna8', '210'),
  ('AfriLianti624', '78'),
  ('sjdt_1718', '5'),
  ('lieliekebabkeju', '4,6Rb'),
  ('harunalovely16', '33Rb'),
];

List<Profile> _rotated(List<(String, String)> pool, String name) {
  var h = 7;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final start = name == 'saniyyahputrisaid' ? 0 : h % pool.length;
  return [
    for (var i = 0; i < pool.length; i++)
      Profile(pool[(start + i) % pool.length].$1,
          pool[(start + i) % pool.length].$2),
  ];
}

/// Daftar "Mengikuti" milik akun lain.
List<Profile> otherFollowing(String name) => _rotated(_followingPool, name);

/// Daftar "Pengikut" milik akun lain.
List<Profile> otherFollowers(String name) => _rotated(_followersPool, name);

class FollowersScreen extends StatefulWidget {
  final int initialTab; // 0 = Pengikut, 1 = Mengikuti

  /// null = akun sendiri.
  final String? name;
  const FollowersScreen({super.key, this.initialTab = 0, this.name});
  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  late int _tab = widget.initialTab;
  /// Daftar dari server (null = gagal / profil tidak ada di server).
  List<Profile>? _followersData, _followingData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final who = widget.name ?? AppState.username;
    List<Profile>? a, b;
    try {
      a = [for (final j in await Api.followersOf(who)) AppState.profileFromJson(j)];
    } catch (_) {}
    try {
      b = [for (final j in await Api.followingOf(who)) AppState.profileFromJson(j)];
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _followersData = a;
      _followingData = b;
      _loading = false;
    });
  }

  /// Satu baris profil: avatar 45, nama tebal, ikon di kanan.
  Widget _row(String name, Widget trailing) => Container(
        height: 66,
        decoration: const BoxDecoration(
            color: Color(0xFF151515),
            border: Border(bottom: BorderSide(color: Color(0xFF2C2C2E)))),
        child: InkWell(
          onTap: () => openProfile(context, name),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 9, 0),
            child: Row(children: [
              LetterAvatar(name, size: 45),
              const SizedBox(width: 15),
              Expanded(
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              trailing,
            ]),
          ),
        ),
      );

  Widget _empty(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 120),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        ),
      );

  /// Daftar profil; tombol di kanan = ikuti / berhenti mengikuti (data server).
  Widget _users(List<Profile> list) => ValueListenableBuilder<Set<String>>(
        valueListenable: AppState.followed,
        builder: (_, fol, __) => ListView(padding: EdgeInsets.zero, children: [
          for (final p in list)
            _row(
              p.name,
              p.name == AppState.username
                  ? const SizedBox(width: 39)
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        AppState.toggleFollow(p.name);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                            fol.contains(p.name)
                                ? Icons.how_to_reg_outlined
                                : Icons.person_add_alt_1_outlined,
                            size: 23,
                            color:
                                fol.contains(p.name) ? C.orange : Colors.white),
                      ),
                    ),
            ),
        ]),
      );

  Widget _tabBody() {
    final other = widget.name;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: C.orange));
    }
    final isFollowers = _tab == 0;
    var data = isFollowers ? _followersData : _followingData;
    if (data == null) {
      // Profil contoh (tidak ada di server): pakai daftar contoh.
      if (other != null) {
        data = isFollowers ? otherFollowers(other) : otherFollowing(other);
      } else if (!isFollowers) {
        data = AppState.following;
      } else {
        data = const [];
      }
    }
    if (data.isEmpty) {
      final who = other ?? AppState.username;
      return _empty(isFollowers
          ? '$who tidak\nmemiliki pengikut.'
          : '$who belum\nmengikuti siapa pun.');
    }
    return _users(data);
  }

  Widget _segment() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: const Color(0xFF1F1F21),
            border: Border.all(color: const Color(0xFF2B2B2D)),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          for (var i = 0; i < 2; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = i),
                child: Container(
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color:
                          _tab == i ? const Color(0xFF5B5D61) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(i == 0 ? 'Pengikut' : 'Mengikuti',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final other = widget.name;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
        centerTitle: true,
        leadingWidth: 56,
        backgroundColor: Colors.black,
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
        title: Text(other ?? AppState.username,
            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
        actions: [
          if (other == null)
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tautan undangan disalin'))),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Undang',
                    style: TextStyle(fontSize: 19, color: Colors.white)),
              ),
            ),
        ],
      ),
      body: Column(children: [
        const SizedBox(height: 5),
        _segment(),
        const SizedBox(height: 6),
        Expanded(
          child: _tabBody(),
        ),
      ]),
    );
  }
}

// ===========================================================================
// Edit daftar bacaan (urutkan dengan menggeser ke atas / bawah)
// ===========================================================================
Future<void> showEditReadingLists(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: const Color(0xFF1C1C1E),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.92,
      child: const _EditListsSheet(),
    ),
  );
}

class _EditListsSheet extends StatefulWidget {
  const _EditListsSheet();
  @override
  State<_EditListsSheet> createState() => _EditListsSheetState();
}

class _EditListsSheetState extends State<_EditListsSheet> {
  late List<ReadingList> _lists = [...AppState.readingLists.value];

  Widget _stackedCover(ReadingList l) {
    final s = l.stories;
    return SizedBox(
      width: 92,
      height: 125,
      child: Stack(children: [
        Positioned(
            left: 12,
            top: 0,
            child: Container(
                width: 80,
                height: 125,
                decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(3)))),
        Positioned(
            left: 6,
            top: 0,
            child: Container(
                width: 80,
                height: 125,
                decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(3)))),
        Positioned(
          left: 0,
          top: 0,
          child: s.isEmpty
              ? Container(
                  width: 80,
                  height: 125,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(3)),
                  child: const WLogo(size: 30, color: Color(0xFF151515)))
              : BookCover(s.first, w: 80, h: 125),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 48,
        child: Stack(alignment: Alignment.center, children: [
          const Text('Edit daftar bacaan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: () {
                  AppState.readingLists.value = _lists;
                  Navigator.pop(context);
                },
                child: const Text('Selesai',
                    style: TextStyle(color: Colors.white, fontSize: 16))),
          ),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFF3A3A3C)),
      Expanded(
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: _lists.length,
          onReorder: (a, b) => setState(() {
            if (b > a) b -= 1;
            _lists.insert(b, _lists.removeAt(a));
          }),
          itemBuilder: (_, i) {
            final l = _lists[i];
            return Container(
              key: ObjectKey(l),
              padding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
              decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Color(0xFF2E2E30)))),
              child: SizedBox(
                height: 125 + 1,
                child: Row(children: [
                  _stackedCover(l),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppState.listName(l),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 18, color: Color(0xFFBDBDBD))),
                          const SizedBox(height: 6),
                          Row(children: [
                            Text('${l.stories.length} cerita',
                                style: const TextStyle(
                                    color: C.grey, fontSize: 15)),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: C.grey)),
                            const SizedBox(width: 6),
                            Icon(l.isPublic ? Icons.public : Icons.lock_outline,
                                size: 18, color: C.grey),
                          ]),
                        ]),
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                      child: Icon(Icons.drag_handle, color: Color(0xFF8A8A8C)),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

/// "Buat daftar baru" (lembar bawah: judul + privasi).
Future<void> createReadingList(BuildContext context) =>
    showCreateListSheet(context);

// ===========================================================================
// Percakapan di profil
// ===========================================================================
List<InlineSpan> _linkify(String text, TextStyle base) {
  final re = RegExp(r'https?://\S+');
  final spans = <InlineSpan>[];
  var i = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > i) spans.add(TextSpan(text: text.substring(i, m.start)));
    spans.add(TextSpan(
        text: m.group(0), style: base.copyWith(color: const Color(0xFFFF6122))));
    i = m.end;
  }
  if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
  return spans;
}

/// Tab Percakapan di profil sendiri. Sekarang memakai [ProfileWall] yang
/// tersambung ke server; kelas ini dipertahankan agar kode lama tetap jalan.
class ConversationTab extends StatelessWidget {
  const ConversationTab({super.key});

  @override
  Widget build(BuildContext context) =>
      ProfileWall(username: AppState.username, mine: true);
}

/// Halaman menulis status / membalas, lalu "Posting".
class ComposeMessageScreen extends StatefulWidget {
  final Message? replyTo;
  const ComposeMessageScreen({super.key, this.replyTo});
  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final can = _c.text.trim().isNotEmpty;
    final reply = widget.replyTo != null;
    return Scaffold(
      appBar: wAppBar(
        context,
        title: reply ? 'Balas' : 'Posting Pesan',
        leading: Icons.close,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: can ? () => Navigator.pop(context, _c.text.trim()) : null,
                child: Container(
                  height: 30,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                      color: can ? Colors.white : const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(16)),
                  child: Text(reply ? 'Kirim' : 'Posting',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: can ? Colors.black : const Color(0xFF8A8A8A))),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: Column(children: [
          if (reply)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('${widget.replyTo!.author}: ${widget.replyTo!.text}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: C.grey, fontSize: 15)),
            ),
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Avatar(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _c,
                  autofocus: true,
                  maxLines: null,
                  maxLength: 1000,
                  onChanged: (_) => setState(() {}),
                  cursorColor: C.iosBlue,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: reply ? 'Tulis balasan...' : 'Masukkan status kamu...',
                    hintStyle:
                        const TextStyle(color: Color(0xFF6E6E6E), fontSize: 18),
                    counterStyle: const TextStyle(color: C.grey),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 10),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
