import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import 'list_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});
  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  static const _sorts = ['Terpopuler', 'Bab terbanyak', 'Judul A–Z'];
  int _cat = 0;
  int _sort = 0;
  bool _expanded = false;
  final _search = TextEditingController();
  final _catScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ServerStories.version.addListener(_onServer);
  }

  void _onServer() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ServerStories.version.removeListener(_onServer);
    _search.dispose();
    _catScroll.dispose();
    super.dispose();
  }

  List<Story> get _list {
    final q = _search.text.trim().toLowerCase();
    final List<Story> l = q.isEmpty
        ? [...storiesFor(kCategories[_cat])]
        : allStories
            .where((s) =>
                s.title.toLowerCase().contains(q) ||
                s.author.toLowerCase().contains(q) ||
                s.tags.any((t) => t.toLowerCase().contains(q)))
            .toList();
    if (_sort == 1) l.sort((a, b) => b.parts.compareTo(a.parts));
    if (_sort == 2) l.sort((a, b) => a.title.compareTo(b.title));
    return l;
  }

  void _filter() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 20, 22, 8),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Urutkan berdasarkan',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          ),
          for (var i = 0; i < _sorts.length; i++)
            ListTile(
              title: Text(_sorts[i]),
              trailing: i == _sort
                  ? const Icon(Icons.check, color: C.orange)
                  : null,
              onTap: () {
                setState(() => _sort = i);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _scrollCats() {
    if (!_catScroll.hasClients) return;
    _catScroll.animateTo(
        math.min(_catScroll.offset + 160, _catScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut);
  }

  void _pick(int i) => setState(() {
        _cat = i;
        _search.clear();
        _expanded = false;
      });

  Widget _tabs(bool searching) => SizedBox(
        height: 48,
        child: Row(children: [
          Expanded(
            child: ListView.builder(
              controller: _catScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 14),
              itemCount: kCategories.length,
              itemBuilder: (_, i) {
                final on = i == _cat && !searching;
                return GestureDetector(
                  onTap: () => _pick(i),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: IntrinsicWidth(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            Text(kCategories[i],
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: on
                                        ? Colors.white
                                        : const Color(0xFFBDBDBD))),
                            const Spacer(),
                            Container(
                                height: 3,
                                color: on ? C.orange : Colors.transparent),
                          ]),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
              onPressed: () => setState(() => _expanded = true),
              icon: const Icon(Icons.chevron_right, size: 30)),
        ]),
      );

  /// Panel semua genre (terbuka saat panah di kanan ditekan).
  Widget _panel() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        decoration: const BoxDecoration(
            color: Color(0xFF2E2E2E),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < kCategories.length; i++)
                GestureDetector(
                  onTap: () => _pick(i),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    decoration: BoxDecoration(
                        color: i == _cat && _search.text.trim().isEmpty
                            ? Colors.white
                            : const Color(0xFF3D3D3D),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(kCategories[i],
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: i == _cat && _search.text.trim().isEmpty
                                ? Colors.black
                                : Colors.white)),
                  ),
                ),
            ]),
          ),
          IconButton(
              onPressed: () => setState(() => _expanded = false),
              icon: const Icon(Icons.keyboard_arrow_up, size: 30)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final searching = _search.text.trim().isNotEmpty;
    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 17),
            decoration: InputDecoration(
              hintText: 'Telusuri cerita atau profil',
              hintStyle: const TextStyle(color: Color(0xFF9A9A9A), fontSize: 17),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9A9A9A)),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF9A9A9A)),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      }),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF4A4A4A))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white70)),
            ),
          ),
        ),
        if (_expanded) _panel() else _tabs(searching),
        if (!_expanded) const Divider(height: 1, color: Color(0xFF2E2E2E)),
        Expanded(
          child: Stack(children: [
            Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(children: [
                  Text('${list.length} Cerita',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _filter,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                          color: const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(26)),
                      child: Row(children: const [
                        Icon(Icons.tune, size: 20),
                        SizedBox(width: 8),
                        Text('Filter',
                            style:
                                TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ]),
                    ),
                  ),
                ]),
              ),
              Expanded(child: _results(list)),
            ]),
            if (_expanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _expanded = false),
                  child: const ColoredBox(color: Color(0xB3000000)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _results(List<Story> list) {
    return list.isEmpty
              ? const Center(
                  child: Text('Cerita tidak ditemukan',
                      style: TextStyle(color: C.grey, fontSize: 16)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => StoryRow(list[i], rank: i + 1),
                );
  }
}
