import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import '../app_state.dart';
import 'profile_extras.dart' show showEditReadingLists;
import 'story_screen.dart';
import 'other_profile_screen.dart' show storyBlurb;

class StoryRow extends StatelessWidget {
  final Story story;
  final int? rank;
  final Widget? trailing;
  const StoryRow(this.story, {super.key, this.rank, this.trailing});

  @override
  Widget build(BuildContext context) {
    final title = story.title.replaceAll('\n', ' ');
    return InkWell(
      onTap: () => openStory(context, story),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BookCover(story, w: 71, h: 112),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (rank != null) ...[
                      Text('$rank',
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ]),
              const SizedBox(height: 4),
              Text(story.author,
                  style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 16)),
              const SizedBox(height: 8),
              ViewsRow(story.views, parts: story.parts),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                for (final t in story.tags.take(3)) StatChip(t),
                if (story.tags.length > 3)
                  const Padding(
                    padding: EdgeInsets.only(top: 9),
                    child: Text('+ lebih banyak',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFFE0E0E0))),
                  ),
              ]),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

class StoryListScreen extends StatefulWidget {
  final String title;
  final List<Story> stories;

  /// null = daftar biasa (judul kecil di app bar); true/false = daftar bacaan
  /// (judul besar, jumlah cerita, dan ikon Publik / Pribadi).
  final bool? isPublic;

  /// Jika diisi, isi cerita dibaca langsung dari daftar ini sehingga ikut
  /// berubah saat cerita ditambah / dihapus.
  final ReadingList? list;

  /// Dipanggil oleh tombol "Pilih cerita untuk ditambahkan".
  final VoidCallback? onAdd;

  /// Pemilik daftar (null = pengguna sendiri).
  final String? owner;
  const StoryListScreen(this.title, this.stories,
      {super.key, this.isPublic, this.list, this.onAdd, this.owner});

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen> {
  String get _owner => widget.owner ?? AppState.username;
  String get _listTitle =>
      widget.list != null ? AppState.listName(widget.list!) : widget.title;
  bool get _liked => AppState.isListLiked(_owner, _listTitle);

  void _toggleLike() {
    AppState.toggleListLike(
        _owner, _listTitle, () => widget.list?.stories ?? widget.stories);
    setState(() {});
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _menu() async {
    final v = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.settings, size: 24),
            title: const Text('Edit daftar bacaan',
                style: TextStyle(fontSize: 19)),
            onTap: () => Navigator.pop(ctx, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.add, size: 26),
            title: const Text('Tambahkan cerita',
                style: TextStyle(fontSize: 19)),
            onTap: () => Navigator.pop(ctx, 'add'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (!mounted) return;
    if (v == 'edit') showEditReadingLists(context);
    if (v == 'add') widget.onAdd?.call();
  }

  /// Keadaan kosong: kartu ilustrasi, judul, penjelasan, dan tombol putih.
  Widget _empty() => Column(children: [
        const SizedBox(height: 100),
        Container(
          width: 181,
          height: 181,
          decoration: BoxDecoration(
              color: const Color(0xFF1D1D1F),
              borderRadius: BorderRadius.circular(10)),
          child: Stack(children: [
            Positioned(
                left: 60,
                top: 17,
                child: Container(
                    width: 61,
                    height: 94,
                    decoration: BoxDecoration(
                        color: const Color(0xFF2F2F31),
                        borderRadius: BorderRadius.circular(3)))),
            for (final t in const [119.0, 134.0])
              Positioned(
                  left: 15,
                  top: t,
                  child: Container(
                      width: 150,
                      height: 7,
                      decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2F),
                          borderRadius: BorderRadius.circular(4)))),
            Positioned(
                left: 15,
                top: 149,
                child: Container(
                    width: 132,
                    height: 15,
                    decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2F),
                        borderRadius: BorderRadius.circular(8)))),
            Positioned(
                left: 150,
                top: 149,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2)),
                  child: const Icon(Icons.add, size: 11, color: Colors.white),
                )),
          ]),
        ),
        const SizedBox(height: 10),
        const Text('Belum ada cerita yang ditambahkan',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 44),
          child: Text(
              'Cari tombol "+" untuk menambahkan cerita ke daftar bacaan kamu atau pilih cerita yang akan ditambahkan',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16.5, height: 1.34, color: Color(0xFFD5D5D5))),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onTap: widget.onAdd,
          child: Container(
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 34),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(23)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.add, color: Colors.black, size: 20),
              SizedBox(width: 9),
              Text('Pilih cerita untuk ditambahkan',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
        const SizedBox(height: 30),
      ]);

  Widget _body() {
    final isList = widget.isPublic != null;
    final stories = widget.list?.stories ?? widget.stories;
    final isPublic = widget.list?.isPublic ?? widget.isPublic;
    final title =
        widget.list != null ? AppState.listName(widget.list!) : widget.title;
    return ListView(padding: EdgeInsets.zero, children: [
      if (isList)
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 15),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 3),
                  Text('${stories.length} cerita',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, height: 1.2)),
                  const SizedBox(height: 21),
                  Row(children: [
                    Text(isPublic! ? 'Publik' : 'Pribadi',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8E8E90))),
                    const SizedBox(width: 5),
                    Icon(isPublic ? Icons.public : Icons.lock_outline,
                        size: 16, color: const Color(0xFF8E8E90)),
                  ]),
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
      if (isList) const SizedBox(height: 14),
      if (stories.isEmpty)
        (isList && widget.onAdd != null)
            ? _empty()
            : const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                    child: Text('Belum ada cerita',
                        style: TextStyle(color: C.grey))),
              )
      else if (isList)
        ...[
          for (final st in stories)
            WideStoryRow(st, showTags: true, showParts: true, synLines: 2)
        ]
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
          child: Column(children: [
            for (final st in stories)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: StoryRow(st)),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isList = widget.isPublic != null;
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
        titleSpacing: 0,
        title: isList
            ? null
            : Text(widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: isList
            ? [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _snack('Tautan daftar disalin'),
                  child: const Padding(
                      padding: EdgeInsets.all(8), child: SendIcon(size: 24)),
                ),
                const SizedBox(width: 18),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onAdd == null ? () {} : _menu,
                  child: const Padding(
                      padding: EdgeInsets.fromLTRB(4, 8, 22, 8),
                      child: Icon(Icons.more_vert, size: 24)),
                ),
              ]
            : null,
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFF2E2E2E))),
      ),
      body: widget.list != null
          ? ListenableBuilder(
              listenable:
                  Listenable.merge([AppState.readingLists, AppState.library]),
              builder: (_, __) => _body())
          : _body(),
    );
  }
}

/// Baris cerita lebar: sampul 117x183 rata kiri, info di kanan. Dipakai di
/// daftar bacaan dan pemilih cerita (baris terpilih: latar abu + tanda centang).
class WideStoryRow extends StatelessWidget {
  final Story story;
  final bool selected, showAuthor, showTags, showParts;
  final int synLines;
  final VoidCallback? onTap;
  const WideStoryRow(this.story,
      {super.key,
      this.selected = false,
      this.showAuthor = false,
      this.showTags = false,
      this.showParts = false,
      this.synLines = 3,
      this.onTap});

  static const _gray = Color(0xFFA5A5A5);

  Widget _mini(IconData icon, String t) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: _gray),
        const SizedBox(width: 5),
        Text(t, style: const TextStyle(color: _gray, fontSize: 14)),
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
    final s = story;
    return InkWell(
      onTap: onTap ?? () => openStory(context, s),
      child: Container(
        height: 183,
        decoration: BoxDecoration(
            color: selected ? const Color(0xFF2E2E2E) : null,
            border: const Border(bottom: BorderSide(color: Color(0xFF262626)))),
        child: Row(children: [
          selected
              ? SizedBox(
                  width: 117,
                  height: 183,
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                          color: Color(0xFF45C4A8), shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 19, color: Colors.white),
                    ),
                  ),
                )
              : BookCover(s, w: 117, h: 183),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title.replaceAll('\n', ' '),
                        maxLines: showAuthor ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 19, height: 1.2, color: Color(0xFFF0F0F0))),
                    if (showAuthor) ...[
                      const SizedBox(height: 4),
                      Text(s.author,
                          style: const TextStyle(fontSize: 15.5, color: _gray)),
                    ],
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        _mini(Icons.remove_red_eye, s.views),
                        const SizedBox(width: 16),
                        _mini(Icons.star, votesOf(s)),
                        if (showParts) ...[
                          const SizedBox(width: 16),
                          _mini(Icons.format_list_bulleted, '${s.parts}'),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text(storyBlurb(s),
                        maxLines: synLines,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14.5, height: 1.3, color: Color(0xFFBDBDBD))),
                    if (showTags) ...[
                      const SizedBox(height: 9),
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
                    ],
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}
