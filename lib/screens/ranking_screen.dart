import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';

/// "Peringkat Cerita": peringkat cerita pada tag / kategori (dibuka dari
/// baris "#5 [tag] >" di halaman cerita).
class StoryRankingScreen extends StatelessWidget {
  final Story story;
  final String genre;
  const StoryRankingScreen(this.story, {super.key, this.genre = 'romansa'});

  static const _gray = Color(0xFFA5A5A5);

  int get _h {
    var h = 11;
    for (final c in story.title.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  Widget _rank(String n, {bool big = false, Color color = Colors.white}) =>
      SizedBox(
        width: 58,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.only(top: big ? 3 : 2),
            child: Text('#',
                style: TextStyle(fontSize: 11, height: 1.0, color: color)),
          ),
          Text(n,
              style: TextStyle(
                  fontSize: big ? 31 : 22,
                  height: 1.0,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ]),
      );

  Widget _medal() => SizedBox(
        width: 26,
        height: 32,
        child: Stack(alignment: Alignment.topCenter, children: [
          Positioned(
              bottom: 0,
              child: Container(
                  width: 11, height: 13, color: const Color(0xFF14A89A))),
          Container(
            width: 23,
            height: 23,
            decoration: BoxDecoration(
                color: const Color(0xFFF5A02A),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFC04D), width: 1.5)),
            child: const Icon(Icons.star, size: 15, color: Colors.white),
          ),
        ]),
      );

  Widget _card(
      {required double height,
      required Widget rank,
      required String tag,
      String? sub,
      required String total,
      bool featured = false}) {
    return Container(
      height: height,
      margin: const EdgeInsets.fromLTRB(9.5, 0, 9.5, 0),
      padding: const EdgeInsets.only(left: 11, right: 8),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF353535)),
          borderRadius: BorderRadius.circular(2)),
      child: Row(children: [
        rank,
        const SizedBox(width: 12.5),
        Expanded(
          child: featured
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(tag,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(total,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontStyle: FontStyle.italic,
                              color: _gray)),
                    ])
              : Row(children: [
                  Expanded(
                    child: Text(tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                  Text(total,
                      style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: _gray)),
                ]),
        ),
        if (featured) ...[_medal(), const SizedBox(width: 14)],
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, size: 22, color: Colors.white),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = _h;
    final tags = story.tags.take(4).toList();
    final others = <(String, String, String)>[];
    for (var i = 0; i < tags.length; i++) {
      if (i == 0) {
        others.add(('1', tags[i], 'dari 1.000+ cerita'));
      } else {
        final total = 40 + (h * (i + 3)) % 380;
        final rank = 1 + (h * (i + 7)) % total;
        others.add(('$rank', tags[i], 'dari $total cerita'));
      }
    }
    final title = story.title.replaceAll('\n', ' ');
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
        centerTitle: true,
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
        title: const Text('Peringkat Cerita',
            style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w600)),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFF2E2E2E))),
      ),
      body: ListView(padding: EdgeInsets.zero, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 19, 10, 0),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 21,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.2)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 19, 10, 11),
          child: Text('Peringkat Paling Mengesankan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        _card(
            height: 60,
            rank: _rank('1', big: true, color: C.orange),
            tag: genre,
            total: 'dari 1.000+ cerita',
            featured: true),
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 20, 10, 11),
          child: Text('Peringkat Lainnya',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        for (final o in others) ...[
          _card(height: 46.5, rank: _rank(o.$1), tag: o.$2, total: o.$3),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 20),
      ]),
    );
  }
}
