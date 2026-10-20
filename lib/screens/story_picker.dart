import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import 'list_screen.dart' show WideStoryRow;

/// Pemilih cerita dari Perpustakaan untuk ditambahkan ke daftar bacaan
/// ("Batal  N Dipilih  Selesai" + kolom "Telusuri Perpustakaan").
Future<void> showStoryPicker(BuildContext context, ReadingList list) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black,
    builder: (_) => _StoryPicker(list),
  );
}

class _StoryPicker extends StatefulWidget {
  final ReadingList list;
  const _StoryPicker(this.list);
  @override
  State<_StoryPicker> createState() => _StoryPickerState();
}

class _StoryPickerState extends State<_StoryPicker> {
  final Set<String> _sel = {};
  String _q = '';

  List<Story> get _all {
    final lib = AppState.library.value;
    if (_q.trim().isEmpty) return lib;
    final q = _q.trim().toLowerCase();
    return lib
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.author.toLowerCase().contains(q))
        .toList();
  }

  void _done() {
    final l = widget.list;
    for (final s in AppState.library.value) {
      if (!_sel.contains(s.title)) continue;
      if (l.isLibrary) {
        if (!AppState.inLibrary(s)) AppState.addToLibrary(s);
      } else if (!l.has(s)) {
        l.own.add(s);
      }
    }
    AppState.readingLists.value = [...AppState.readingLists.value];
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final top = mq.padding.top + 7.4;
    final items = _all;
    return SizedBox(
      height: mq.size.height,
      child: Stack(children: [
        // sudut halaman sebelumnya yang mengintip di balik lembar
        Positioned(
          top: top - 9,
          left: 19,
          right: 19,
          height: 14,
          child: Container(
            decoration: const BoxDecoration(
                color: Color(0xFF202022),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
          ),
        ),
        Positioned(
          top: top,
          left: 0,
          right: 0,
          bottom: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            child: Container(
              color: C.bg,
              child: Column(children: [
                SizedBox(
                  height: 53,
                  child: Row(children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                            child: Text('Batal',
                                style: TextStyle(
                                    fontSize: 17, color: Colors.white))),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('${_sel.length} Dipilih',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _done,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                            child: Text('Selesai',
                                style: TextStyle(
                                    fontSize: 17, color: Colors.white))),
                      ),
                    ),
                  ]),
                ),
                const Divider(height: 1, color: Color(0xFF2C2C2E)),
                Container(
                  height: 37,
                  margin: const EdgeInsets.fromLTRB(15, 7, 15, 6),
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF3A3A3C)),
                      borderRadius: BorderRadius.circular(19)),
                  child: Row(children: [
                    const Icon(Icons.search, size: 23, color: Colors.white),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _q = v),
                        cursorColor: Colors.white,
                        style: const TextStyle(fontSize: 17),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Telusuri Perpustakaan',
                          hintStyle:
                              TextStyle(fontSize: 17, color: Color(0xFF9A9A9C)),
                        ),
                      ),
                    ),
                  ]),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                              AppState.library.value.isEmpty
                                  ? 'Perpustakaanmu masih kosong'
                                  : 'Tidak ada hasil',
                              style: const TextStyle(color: C.grey, fontSize: 16)),
                        )
                      : ListView(padding: EdgeInsets.zero, children: [
                          for (final s in items)
                            WideStoryRow(
                              s,
                              showAuthor: true,
                              synLines: 3,
                              selected: _sel.contains(s.title),
                              onTap: () => setState(() {
                                _sel.contains(s.title)
                                    ? _sel.remove(s.title)
                                    : _sel.add(s.title);
                              }),
                            ),
                        ]),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
