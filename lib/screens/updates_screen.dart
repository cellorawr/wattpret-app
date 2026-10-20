import 'package:flutter/material.dart';
import '../api_service.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'other_profile_screen.dart';
import 'story_screen.dart' show openStory;

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});
  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  int _tab = 0;
  final Set<int> _followed = {};

  /// Notifikasi dari server (null = sedang memuat).
  List<Map<String, dynamic>>? _items;

  /// Feed Sosial dan pesan di dinding profilku (null = sedang memuat).
  List<Map<String, dynamic>>? _feedItems;
  List<Map<String, dynamic>>? _wall;

  @override
  void initState() {
    super.initState();
    _loadNotifs();
    _loadFeed();
    _loadWall();
  }

  Future<void> _loadFeed() async {
    if (!Api.isLoggedIn) {
      if (mounted) setState(() => _feedItems = []);
      return;
    }
    try {
      final l = await Api.feed();
      if (mounted) setState(() => _feedItems = l);
    } catch (_) {
      if (mounted) setState(() => _feedItems ??= []);
    }
  }

  /// Pesan yang ditulis orang lain di dinding profilku (termasuk balasan).
  Future<void> _loadWall() async {
    if (!Api.isLoggedIn) {
      if (mounted) setState(() => _wall = []);
      return;
    }
    try {
      final l = await Api.messages(AppState.username);
      final out = <Map<String, dynamic>>[];
      String who(Map<String, dynamic> m) =>
          ((m['author'] as Map?)?['username'] ?? '').toString();
      for (final m in l) {
        if (who(m) != AppState.username) out.add(m);
        for (final r in (m['replies'] as List? ?? const [])) {
          final rm = Map<String, dynamic>.from(r as Map);
          if (who(rm) != AppState.username) out.add(rm);
        }
      }
      out.sort((a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'));
      if (mounted) setState(() => _wall = out);
    } catch (_) {
      if (mounted) setState(() => _wall ??= []);
    }
  }

  /// Ketuk notifikasi: buka ceritanya, atau profil orang yang bersangkutan.
  Future<void> _openNotif(Map<String, dynamic> j) async {
    final sid = int.tryParse('${j['story_id']}');
    if (sid != null) {
      try {
        final d = await Api.story(sid);
        d['chapters_count'] ??= (d['chapters'] as List?)?.length ?? 0;
        if (!mounted) return;
        openStory(context, Story.fromJson(d));
        return;
      } catch (_) {}
    }
    final a = j['actor'];
    final name = a is Map ? (a['username'] ?? '').toString() : '';
    if (name.isNotEmpty && mounted) _openCommunity(name);
  }

  Future<void> _loadNotifs() async {
    if (!Api.isLoggedIn) {
      if (mounted) setState(() => _items = []);
      return;
    }
    try {
      final l = await Api.notifications();
      if (!mounted) return;
      setState(() => _items = l);
      // Setelah tab Notifikasi dibuka, semuanya dianggap sudah dibaca.
      if (_tab == 1 && l.any((j) => j['read_at'] == null)) {
        Api.markAllRead().catchError((_) {});
      }
    } catch (_) {
      if (mounted) setState(() => _items ??= []);
    }
  }

  void _openCommunity(String name) {
    // Dibuka di dalam Navigator tab ini agar bilah navigasi bawah tetap tampil.
    final page = OtherProfileScreen(name);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _community(int i, String name, String fol, Widget avatar) {
    final on = _followed.contains(i);
    return Expanded(
      child: Column(children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openCommunity(name),
          child: Column(children: [
            avatar,
            const SizedBox(height: 10),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('$fol Pengikut',
                style: const TextStyle(fontSize: 16, color: Color(0xFFDDDDDD))),
          ]),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => setState(() => on ? _followed.remove(i) : _followed.add(i)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
                color: on ? C.orange : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(22)),
            child: Text(on ? 'Mengikuti' : 'Ikuti',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ]),
    );
  }

  Widget _circle(Color c, Widget child) => Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      child: child);

  Widget _skeleton(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
          color: const Color(0xFFE2E2E2), borderRadius: BorderRadius.circular(4)));

  Widget _feedRow(Map<String, dynamic> j) {
    final story = Story.fromJson(Map<String, dynamic>.from(j['story'] as Map));
    final ch = j['chapter'] is Map ? Map<String, dynamic>.from(j['chapter']) : null;
    final when = DateTime.tryParse('${j['at']}')?.toLocal();
    final text = ch == null
        ? '${story.author} menerbitkan cerita baru'
        : '${story.author} memperbarui cerita dengan Bab ${ch['number']}';
    return InkWell(
      onTap: () => openStory(context, story),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF2E2E2E)))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            LetterAvatar(story.author, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(text,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text(when == null ? '' : timeAgo(when),
                    style: const TextStyle(fontSize: 13, color: C.grey)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BookCover(story, w: 64, h: 96),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(story.title.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                if (ch != null) ...[
                  const SizedBox(height: 4),
                  Text('Bab ${ch['number']}: ${ch['title']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Color(0xFFBDBDBD))),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  MiniStat(Icons.remove_red_eye, story.views),
                  const SizedBox(width: 12),
                  MiniStat(Icons.star, votesOf(story)),
                ]),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _feedBody() {
    final items = _feedItems;
    if (items == null) {
      return const Padding(
          padding: EdgeInsets.only(top: 110),
          child: Align(
              alignment: Alignment.topCenter,
              child: Text('Memuat feed...',
                  style: TextStyle(fontSize: 16, color: C.grey))));
    }
    if (items.isEmpty) return SingleChildScrollView(child: _feed());
    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView(
          padding: EdgeInsets.zero, children: [for (final j in items) _feedRow(j)]),
    );
  }

  Widget _feed() {
    return Column(children: [
      const SizedBox(height: 56),
      Container(
        width: 198,
        height: 108,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6)),
        child: Column(children: [
          Row(children: [
            const CircleAvatar(
                radius: 8, backgroundColor: Color(0xFFD0D0D0)),
            const SizedBox(width: 8),
            _skeleton(100, 6),
            const Spacer(),
            _skeleton(22, 5),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _skeleton(36, 50),
            const SizedBox(width: 6),
            Column(children: [_skeleton(14, 22), const SizedBox(height: 6), _skeleton(14, 22)]),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _skeleton(76, 5),
              const SizedBox(height: 5),
              _skeleton(76, 5),
              const SizedBox(height: 5),
              _skeleton(50, 5),
            ]),
          ]),
        ]),
      ),
      const SizedBox(height: 40),
      const Text('Melalui cerita, kita saling bertemu',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      const Text('Ikuti orang lain untuk menghidupkan feed kamu\ndan temukan dunia baru',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, height: 1.3)),
      const SizedBox(height: 120),
      const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
            padding: EdgeInsets.only(left: 22, bottom: 16),
            child: Text('Temukan komunitasmu',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _community(
              0,
              'AmbassadorsID',
              '80.7k',
              _circle(const Color(0xFF8EE3D1),
                  const Text('AmbassadorsID',
                      style: TextStyle(
                          color: Color(0xFF0F5E56),
                          fontSize: 7,
                          fontWeight: FontWeight.w800)))),
          _community(
              1,
              'action',
              '110.0k',
              _circle(const Color(0xFF2B2B2B),
                  const Text('action\nand\nadventure',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFFFFD400),
                          fontSize: 8,
                          height: 1.05,
                          fontWeight: FontWeight.w800)))),
          _community(2, 'adventure', '108.4k',
              _circle(const Color(0xFF4A4A4A), const SizedBox())),
        ]),
      ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _notifRow(Map<String, dynamic> j) =>
      InkWell(onTap: () => _openNotif(j), child: _notifRowBody(j));

  Widget _notifRowBody(Map<String, dynamic> j) {
    final unread = j['read_at'] == null;
    final a = j['actor'];
    final name = a is Map ? (a['username'] ?? '').toString() : 'Wattpret';
    final when = DateTime.tryParse('${j['created_at']}')?.toLocal();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
          color: unread ? const Color(0xFF1B1B1B) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Color(0xFF2E2E2E)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LetterAvatar(name.isEmpty ? 'Wattpret' : name, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((j['message'] ?? '').toString(),
                style: const TextStyle(fontSize: 16, height: 1.3)),
            const SizedBox(height: 4),
            Text(when == null ? '' : timeAgo(when),
                style: const TextStyle(fontSize: 13, color: C.grey)),
          ]),
        ),
        if (unread)
          Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 6, left: 8),
              decoration:
                  const BoxDecoration(color: C.orange, shape: BoxShape.circle)),
      ]),
    );
  }

  Widget _notifs() {
    final items = _items;
    if (items == null) {
      return const Padding(
          padding: EdgeInsets.only(top: 110),
          child: Align(
              alignment: Alignment.topCenter,
              child: Text('Memuat notifikasi...',
                  style: TextStyle(fontSize: 16, color: C.grey))));
    }
    if (items.isEmpty) return _notifsEmpty();
    return RefreshIndicator(
      onRefresh: _loadNotifs,
      child: ListView(
          padding: EdgeInsets.zero, children: [for (final j in items) _notifRow(j)]),
    );
  }

  Widget _notifsEmpty() => const Padding(
        padding: EdgeInsets.fromLTRB(40, 110, 40, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text('Tidak ada notifikasi untuk\nsaat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24, height: 1.25, color: C.orange)),
          SizedBox(height: 18),
          Text(
              'Pembaruan dari cerita di perpustakaan dan profil\nyang kamu ikuti akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, height: 1.35, color: Color(0xFFBDBDBD))),
        ]),
      );

  Widget _wallRow(Map<String, dynamic> m) {
    final who = ((m['author'] as Map?)?['username'] ?? 'pengguna').toString();
    final when = DateTime.tryParse('${m['created_at']}')?.toLocal();
    final isReply = m['parent_id'] != null;
    return InkWell(
      onTap: () => _openCommunity(who),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF2E2E2E)))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LetterAvatar(who, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isReply ? '$who membalas di profilmu' : '$who menulis di profilmu',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${m['body']}',
                  style: const TextStyle(fontSize: 16, height: 1.3)),
              const SizedBox(height: 4),
              Text(when == null ? '' : timeAgo(when),
                  style: const TextStyle(fontSize: 13, color: C.grey)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _messages() {
    final items = _wall;
    if (items == null) {
      return const Padding(
          padding: EdgeInsets.only(top: 110),
          child: Align(
              alignment: Alignment.topCenter,
              child: Text('Memuat pesan...',
                  style: TextStyle(fontSize: 16, color: C.grey))));
    }
    if (items.isEmpty) return _messagesEmpty();
    return RefreshIndicator(
      onRefresh: _loadWall,
      child: ListView(
          padding: EdgeInsets.zero, children: [for (final m in items) _wallRow(m)]),
    );
  }

  Widget _messagesEmpty() => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(children: [
          SizedBox(
              width: 250,
              height: 190,
              child: CustomPaint(painter: _RidePainter())),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text('Dapatkan berita dan pembaruan dari\ntim Wattpret',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, height: 1.25)),
          ),
          const SizedBox(height: 16),
          const Text('Kamu tidak memiliki pesan.',
              style: TextStyle(fontSize: 19)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Text('Pembaruan',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
        ),
        Segmented(
          labels: const ['Feed Sosial', 'Notifikasi', 'Pesan'],
          index: _tab,
          onChanged: (i) {
            setState(() => _tab = i);
            if (i == 0) _loadFeed();
            if (i == 1) _loadNotifs();
            if (i == 2) _loadWall();
          },
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFF2E2E2E)),
        Expanded(
          child: _tab == 0
              ? _feedBody()
              : _tab == 1
                  ? _notifs()
                  : _messages(),
        ),
      ]),
    );
  }
}

/// Ilustrasi sederhana: tiga pesepeda di bukit oranye di bawah pohon.
class _RidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Paint f(Color c) => Paint()..color = c;
    // awan
    final cloud = f(const Color(0xFFF2A0C0));
    canvas.drawOval(Rect.fromLTWH(w * 0.08, h * 0.1, w * 0.26, h * 0.07), cloud);
    canvas.drawOval(Rect.fromLTWH(w * 0.24, h * 0.04, w * 0.3, h * 0.07), cloud);
    canvas.drawOval(Rect.fromLTWH(w * 0.7, h * 0.18, w * 0.24, h * 0.06), cloud);
    // matahari
    canvas.drawCircle(Offset(w * 0.78, h * 0.1), h * 0.1, f(const Color(0xFFFFD60A)));
    // pohon
    final trunk = Path()
      ..moveTo(w * 0.5, h * 0.78)
      ..lineTo(w * 0.52, h * 0.1)
      ..lineTo(w * 0.62, h * 0.12)
      ..lineTo(w * 0.62, h * 0.78)
      ..close();
    canvas.drawPath(trunk, f(const Color(0xFF8A5A3C)));
    // bukit
    canvas.drawOval(Rect.fromLTWH(0, h * 0.62, w, h * 0.36), f(const Color(0xFFFF7A2F)));
    // sepeda + orang
    final wheel = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final dark = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const skins = [Color(0xFFC98A5B), Color(0xFFF1C27D), Color(0xFFB5683B)];
    const tops = [Color(0xFFFFC72C), Color(0xFF2DB6C4), Color(0xFFE8503A)];
    for (var i = 0; i < 3; i++) {
      final cx = w * (0.22 + i * 0.28);
      final cy = h * 0.74;
      for (final dx in [-w * 0.065, w * 0.065]) {
        canvas.drawCircle(Offset(cx + dx, cy), h * 0.085, wheel);
        canvas.drawCircle(Offset(cx + dx, cy), h * 0.085, dark);
      }
      canvas.drawLine(Offset(cx - w * 0.065, cy), Offset(cx, cy - h * 0.1), dark);
      canvas.drawLine(Offset(cx, cy - h * 0.1), Offset(cx + w * 0.065, cy), dark);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx, cy - h * 0.2), width: w * 0.06, height: h * 0.14),
              const Radius.circular(4)),
          f(tops[i]));
      canvas.drawCircle(Offset(cx, cy - h * 0.31), h * 0.04, f(skins[i]));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
