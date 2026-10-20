import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'profile_extras.dart';

/// Profil resmi "AmbassadorsID" (terverifikasi) dengan tab Bio / Percakapan.
/// Dibuka dari halaman Pembaruan > Temukan komunitasmu.
class AmbassadorsProfileScreen extends StatefulWidget {
  const AmbassadorsProfileScreen({super.key});
  @override
  State<AmbassadorsProfileScreen> createState() =>
      _AmbassadorsProfileScreenState();
}

class _AmbassadorsProfileScreenState extends State<AmbassadorsProfileScreen> {
  static const _name = 'AmbassadorsID';
  static const _teal = Color(0xFF0F6E66);
  int _tab = 0;
  bool _showMoreReplies = false;

  late final List<Message> _msgs = [
    Message('Zania_writers',
        'Sebenarnya pengen ikut, mohon maaf naskahku belum selesai Mind🙏',
        DateTime(2026, 10, 1)),
    Message('titinmasrur', 'KK aku mau, bisa bantu?', DateTime(2026, 9, 30),
        replies: [
          Reply(_name, 'Halo kak! Silakan cek info lengkapnya di Bio kami ya 🙌',
              DateTime(2026, 9, 30)),
        ]),
  ];

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  Future<void> _compose({Message? replyTo}) async {
    final text = await Navigator.of(context, rootNavigator: true).push<String>(
        MaterialPageRoute(
            builder: (_) => ComposeMessageScreen(replyTo: replyTo)));
    if (text == null || text.isEmpty) return;
    setState(() {
      if (replyTo == null) {
        _msgs.insert(0, Message(AppState.username, text, DateTime.now()));
      } else {
        replyTo.replies.add(Reply(AppState.username, text, DateTime.now()));
      }
    });
  }

  // ------------------------------ header ------------------------------
  Widget _badge(IconData icon) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration:
            const BoxDecoration(color: Color(0xFFFF6A2B), shape: BoxShape.circle),
        child: Icon(icon, size: 19, color: Colors.white),
      );

  Widget _stat(String n, String l) => Column(children: [
        Text(n, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(l,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFFE6E6E6), letterSpacing: 0.3)),
      ]);

  Widget _avatar() => Container(
        width: 132,
        height: 132,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: const Color(0xFF9BE8D6),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF1E3A36), width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          SizedBox(width: 70, child: Divider(color: _teal, thickness: 1.5)),
          SizedBox(height: 2),
          Text('AmbassadorsID',
              style: TextStyle(
                  color: _teal, fontSize: 15, fontWeight: FontWeight.w600)),
          SizedBox(height: 2),
          SizedBox(width: 70, child: Divider(color: _teal, thickness: 1.5)),
        ]),
      );

  Widget _header(bool following) => ClipRect(
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _HeaderPainter())),
          SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_back, size: 28),
                      onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.more_horiz, size: 28),
                      onPressed: () => showIosSheet(
                          context, ['Laporkan profil', 'Blokir'], (v) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('"$v" belum tersedia di versi demo')));
                      })),
                ]),
              ),
              _avatar(),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Flexible(
                  child: Text(_name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
                ),
                const SizedBox(width: 10),
                _badge(Icons.check),
                const SizedBox(width: 6),
                _badge(Icons.favorite),
              ]),
              const SizedBox(height: 2),
              const Text('@$_name',
                  style: TextStyle(fontSize: 18, color: Color(0xFFE6E6E6))),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => AppState.toggleFollow(_name),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  decoration: BoxDecoration(
                      color: following ? Colors.white24 : Colors.transparent,
                      border: Border.all(color: Colors.white, width: 1.6),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(following ? Icons.check : Icons.person_add_alt_1,
                        size: 26),
                    const SizedBox(width: 12),
                    Text(following ? 'Mengikuti' : 'Ikuti',
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _stat('4', 'KARYA'),
                _stat('7', 'DAFTAR BACAAN'),
                _stat('80,6Rb', 'PENGIKUT'),
              ]),
              const SizedBox(height: 20),
              Segmented(
                labels: const ['Bio', 'Percakapan'],
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
                bg: const Color(0x66FFFFFF),
                selBg: Colors.white,
                selText: const Color(0xFF9A9A9A),
                divider: Colors.transparent,
                text: Colors.white,
                height: 34,
                fontSize: 15,
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ]),
      );

  // -------------------------------- bio --------------------------------
  Widget _cover(Color bg, String title, {String? sub, String? tag}) => Container(
        width: 148,
        height: 215,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(color: bg),
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Text('W',
                style: TextStyle(
                    color: Color(0xFF1B6BFF),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic)),
            SizedBox(width: 4),
            Text('ambassador',
                style: TextStyle(
                    color: Color(0xFF1B3A5C),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
          const Spacer(),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF1B3A9C),
                  fontSize: 25,
                  height: 1.1,
                  fontWeight: FontWeight.w800)),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub,
                style: const TextStyle(
                    color: Color(0xFF1B3A9C),
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ],
          const Spacer(),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: Text(tag,
                  style: const TextStyle(
                      color: Color(0xFF1B3A5C),
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
        ]),
      );

  Widget _work(Widget cover, String title, String views, String stars, String parts) =>
      SizedBox(
        width: 158,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          cover,
          const SizedBox(height: 8),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 4),
          Row(children: [
            MiniStat(Icons.remove_red_eye, views),
            const SizedBox(width: 8),
            MiniStat(Icons.star, stars),
            const SizedBox(width: 8),
            MiniStat(Icons.format_list_bulleted, parts),
          ]),
        ]),
      );

  Widget _bio() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Text(
              'Merupakan laman resmi yang berada di bawah pengawasan Wattpret HQ '
              'dan dijalankan oleh Ambassadors Indonesia yaitu sukarelawan yang '
              'memberikan waktu mereka untuk mendukung komunitas Wattpret di '
              'Indonesia.',
              style: TextStyle(fontSize: 18, height: 1.35)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: const [
            Icon(Icons.location_on, size: 22, color: C.grey),
            SizedBox(width: 12),
            Text('Wattpret HQ', style: TextStyle(fontSize: 17, color: C.grey)),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Bergabung 12 tahun lalu',
              style: TextStyle(fontSize: 17, color: C.grey)),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Dikerjakan oleh AmbassadorsID',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('4 Cerita Terpublikasi',
                    style: TextStyle(color: C.grey, fontSize: 16)),
              ]),
            ),
            const Icon(Icons.chevron_right, size: 30, color: C.grey),
          ]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 290,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            children: [
              _work(
                  _cover(const Color(0xFFBDF5E6), 'Buku\nPanduan\nPraktis',
                      tag: 'AmbassadorsID'),
                  'Buku Panduan Praktis',
                  '112Rb',
                  '3,2Rb',
                  '6'),
              _work(
                  _cover(const Color(0xFFF7CAD9), 'The\nShortys', sub: '2026'),
                  'The Shortys 2026',
                  '48,1Rb',
                  '2,4Rb',
                  '3'),
              _work(
                  _cover(const Color(0xFFBDF5E6), 'Tantangan\nMenulis\n30 Hari'),
                  'Tantangan Menulis 30 Hari',
                  '76,5Rb',
                  '1,9Rb',
                  '30'),
              _work(
                  _cover(const Color(0xFFD7E3FF), 'Ambassadors\nID Award'),
                  'Ambassadors ID Award',
                  '21,7Rb',
                  '980',
                  '5'),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ]);

  // ----------------------------- percakapan -----------------------------
  Widget _post(Message m, {bool collapsible = false}) {
    const base = TextStyle(fontSize: 17, height: 1.35, color: Color(0xFFDDDDDD));
    final hasReplies = m.replies.isNotEmpty;
    final showReplies = !collapsible || _showMoreReplies;
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
          color: C.bg, border: Border.all(color: const Color(0xFF242424))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            m.author == AppState.username
                ? const Avatar(size: 48)
                : LetterAvatar(m.author, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: m.author,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        const TextSpan(text: ' memosting pesan'),
                      ]),
                      style: const TextStyle(fontSize: 17)),
                  const SizedBox(height: 2),
                  Text(_date(m.date),
                      style: const TextStyle(color: C.grey, fontSize: 15)),
                ]),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.more_horiz, color: C.grey),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: Text(m.text, style: base),
        ),
        if (hasReplies && showReplies)
          for (final r in m.replies)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                r.author == AppState.username
                    ? const Avatar(size: 30)
                    : LetterAvatar(r.author, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.author,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(r.text, style: base.copyWith(fontSize: 16)),
                  ]),
                ),
              ]),
            ),
        InkWell(
          onTap: () {
            if (collapsible && hasReplies && !_showMoreReplies) {
              setState(() => _showMoreReplies = true);
            } else {
              _compose(replyTo: m);
            }
          },
          child: Container(
            height: 48,
            color: const Color(0xFF2B2B2B),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              if (!(collapsible && hasReplies && !_showMoreReplies)) ...[
                const Icon(Icons.reply, size: 22, color: Color(0xFFB0B0B0)),
                const SizedBox(width: 12),
              ],
              Text(
                  collapsible && hasReplies && !_showMoreReplies
                      ? 'Lihat Balasan Lainnya'
                      : 'Balas',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB0B0B0))),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _conversation() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
        child: Column(children: [
          InkWell(
            onTap: _compose,
            child: Container(
              height: 46,
              margin: const EdgeInsets.only(bottom: 13),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration:
                  BoxDecoration(border: Border.all(color: const Color(0xFF242424))),
              child: const Row(children: [
                Avatar(size: 30),
                SizedBox(width: 14),
                Text('Posting Pesan...',
                    style: TextStyle(color: C.grey, fontSize: 17)),
              ]),
            ),
          ),
          for (final m in _msgs) _post(m, collapsible: m.replies.length == 1 && m.author == 'titinmasrur'),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: AppState.followed,
        builder: (context, fol, _) => ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(fol.contains(_name)),
            if (_tab == 0) _bio() else _conversation(),
          ],
        ),
      ),
    );
  }
}

/// Latar header: tosca keabu-abuan dengan bentuk dekoratif (ponsel & berlian).
class _HeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFA4C9C1));
    // gumpalan tosca di kiri bawah
    canvas.drawOval(Rect.fromLTWH(-w * 0.25, h * 0.45, w * 0.8, h * 0.6),
        Paint()..color = const Color(0xFF86D3C3));
    // tangan + ponsel di kanan
    canvas.drawOval(Rect.fromLTWH(w * 0.62, h * 0.38, w * 0.6, h * 0.5),
        Paint()..color = const Color(0xFFB07C70));
    canvas.save();
    canvas.translate(w * 0.74, h * 0.2);
    canvas.rotate(0.28);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w * 0.34, h * 0.5), const Radius.circular(10)),
        Paint()..color = const Color(0xFFE0A58A));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.025, h * 0.04, w * 0.29, h * 0.42),
            const Radius.circular(6)),
        Paint()..color = const Color(0xFFD38E70));
    canvas.restore();
    // berlian oranye
    final d = Path()
      ..moveTo(w * 0.70, h * 0.42)
      ..lineTo(w * 0.75, h * 0.52)
      ..lineTo(w * 0.70, h * 0.66)
      ..lineTo(w * 0.65, h * 0.52)
      ..close();
    canvas.drawPath(d, Paint()..color = const Color(0xFFE0703A));
    // tint gelap tipis agar teks putih terbaca
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0x22000000));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
