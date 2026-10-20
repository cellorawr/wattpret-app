import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'app_state.dart';
import 'data.dart';
import 'theme.dart';
import 'screens/settings_pages.dart' show PremiumScreen;

/// Logo "W" Wattpret (gambar transparan yang diwarnai sesuai [color]).
class WLogo extends StatelessWidget {
  final double size;
  final Color color;
  const WLogo({super.key, this.size = 34, this.color = C.orange});
  @override
  Widget build(BuildContext context) => Image.asset('assets/logo_w.png',
      height: size * 0.8,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.high);
}

class WhiteButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const WhiteButton(this.label, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: const StadiumBorder(),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          child: Text(label),
        ),
      );
}

InputDecoration pillDecoration(
    {String? hint,
    String? label,
    bool error = false,
    Color? borderColor,
    double vPad = 17,
    Widget? suffix}) {
  final col = error ? C.red : (borderColor ?? const Color(0xFF5E5E5E));
  OutlineInputBorder b(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: c, width: 1.3));
  return InputDecoration(
    hintText: hint,
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    hintStyle: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 17),
    labelStyle: TextStyle(color: col, fontSize: 15),
    floatingLabelStyle: TextStyle(color: col, fontSize: 15),
    contentPadding: EdgeInsets.symmetric(horizontal: 26, vertical: vPad),
    enabledBorder: b(col),
    border: b(col),
    focusedBorder: b(error ? C.red : (borderColor ?? C.orange)),
    suffixIcon: suffix,
  );
}

class AppCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const AppCheck({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: value ? Colors.white : Colors.transparent,
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: value
              ? const Icon(Icons.check, color: Colors.black, size: 22)
              : null,
        ),
      );
}

class Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final Color bg, selBg, selText, text, divider;
  final double height, fontSize;
  const Segmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.bg = const Color(0xFF1F1F1F),
    this.selBg = const Color(0xFF5B5D61),
    this.selText = Colors.white,
    this.text = Colors.white,
    this.divider = const Color(0xFF3F3F3F),
    this.height = 40,
    this.fontSize = 15,
  });
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Container(
                  width: 1,
                  height: height * 0.45,
                  color: (i == index || i - 1 == index)
                      ? Colors.transparent
                      : divider),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: i == index ? selBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(labels[i],
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: fontSize,
                          color: i == index ? selText : text)),
                ),
              ),
            ),
          ],
        ]),
      );
}

/// Nama berkas cover: judul huruf kecil, selain huruf/angka jadi "_".
/// Contoh: "Silencio" -> assets/covers/silencio.jpg
/// (Ganti berkasnya dengan cover aslimu bila ada, nama berkas jangan diubah.)
String coverAsset(String title) {
  final s = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return 'assets/covers/$s.jpg';
}

class BookCover extends StatelessWidget {
  final Story story;
  final double w, h;
  const BookCover(this.story, {super.key, this.w = 93, this.h = 145});

  Widget _fallback() => Container(
        width: w,
        height: h,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: story.color, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: Text(story.title,
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: story.textColor,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                fontSize: w * 0.17)),
      );

  Widget _asset() => Image.asset(
        coverAsset(story.title),
        width: w,
        height: h,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _fallback(),
      );

  @override
  Widget build(BuildContext context) => LightCounter(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: story.cover != null
              ? Image.memory(story.cover!,
                  width: w,
                  height: h,
                  fit: BoxFit.cover,
                  gaplessPlayback: true)
              : (story.coverUrl != null && story.coverUrl!.isNotEmpty)
                  ? Image.network(story.coverUrl!,
                      width: w,
                      height: h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _asset())
                  : _asset(),
        ),
      );
}

class CoverWithBadge extends StatelessWidget {
  final Story story;
  const CoverWithBadge(this.story, {super.key});
  @override
  Widget build(BuildContext context) => BookCover(story);
}

class StatChip extends StatelessWidget {
  final String text;
  const StatChip(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
            color: C.chip, borderRadius: BorderRadius.circular(9)),
        child: Text(text,
            style: const TextStyle(fontSize: 15, color: Color(0xFFE0E0E0))),
      );
}

class ViewsRow extends StatelessWidget {
  final String views;
  final int? parts;
  const ViewsRow(this.views, {super.key, this.parts});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.remove_red_eye_outlined, size: 22, color: C.grey),
        const SizedBox(width: 6),
        Text(views, style: const TextStyle(color: C.grey, fontSize: 15)),
        if (parts != null) ...[
          const SizedBox(width: 10),
          Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                  color: Color(0xFF555555), shape: BoxShape.circle)),
          const SizedBox(width: 10),
          const Icon(Icons.format_list_bulleted, size: 22, color: C.grey),
          const SizedBox(width: 6),
          Text('$parts', style: const TextStyle(color: C.grey, fontSize: 15)),
        ]
      ]);
}

class Avatar extends StatelessWidget {
  final double size;
  const Avatar({super.key, this.size = 36});
  @override
  Widget build(BuildContext context) => LightCounter(
        child: ValueListenableBuilder<Uint8List?>(
          valueListenable: AppState.avatarBytes,
          builder: (_, bytes, __) => Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB98A5E),
                border: Border.all(color: const Color(0xFF3A3A3A), width: 1.5)),
            child: bytes != null
                ? Image.memory(bytes,
                    fit: BoxFit.cover, width: size, height: size)
                : Icon(Icons.egg_alt,
                    size: size * 0.7, color: const Color(0xFFF1D9B5)),
          ),
        ),
      );
}

/// Kolase daftar bacaan: satu kotak besar + dua kotak kecil. Kotak diisi cover
/// cerita yang ada di daftar (urut dari cerita pertama); yang belum terisi
/// tampil sebagai kotak abu-abu berlogo W, seperti di Wattpret.
class WCollage extends StatelessWidget {
  final double size;
  final Color bg;
  final List<Story> stories;
  const WCollage(
      {super.key,
      this.size = 115,
      this.bg = const Color(0xFF2E2E2E),
      this.stories = const []});

  Widget _box(double w, double h, double fs, Story? s) {
    if (s != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(width: w, height: h, child: _fill(s, w, h)),
      );
    }
    return Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text('w',
          style: TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
              fontSize: fs,
              height: 1,
              color: const Color(0xFF151515))),
    );
  }

  Widget _fill(Story s, double w, double h) => LightCounter(
        child: s.cover != null
            ? Image.memory(s.cover!,
                width: w, height: h, fit: BoxFit.cover, gaplessPlayback: true)
            : Image.asset(coverAsset(s.title),
                width: w,
                height: h,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => Container(
                    width: w,
                    height: h,
                    color: s.color,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(4),
                    child: Text(s.title.replaceAll('\n', ' '),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: s.textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: w * 0.14)))),
      );

  @override
  Widget build(BuildContext context) {
    final gap = size * 0.035;
    final bigW = size * 0.64;
    final smallW = size - bigW - gap;
    final smallH = (size - gap) / 2;
    Story? at(int i) => i < stories.length ? stories[i] : null;
    return SizedBox(
      width: size,
      height: size,
      child: Row(children: [
        _box(bigW, size, size * 0.3, at(0)),
        SizedBox(width: gap),
        Column(children: [
          _box(smallW, smallH, size * 0.14, at(1)),
          SizedBox(height: gap),
          _box(smallW, smallH, size * 0.14, at(2)),
        ]),
      ]),
    );
  }
}

/// Lembar aksi bergaya iOS (daftar pilihan + tombol "Batal").
Future<void> showIosSheet(
    BuildContext context, List<String> options, ValueChanged<String> onPick,
    {String? title,
    List<String> destructive = const [],
    double itemHeight = 58,
    double bottomPad = 8,
    bool root = false}) {
  Widget btn(String t, VoidCallback f, {bool bold = false}) => InkWell(
        onTap: f,
        child: Container(
          height: itemHeight,
          alignment: Alignment.center,
          child: Text(t,
              style: TextStyle(
                  color: destructive.contains(t)
                      ? const Color(0xFFFF453A)
                      : C.iosBlue,
                  fontSize: 20,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        ),
      );
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: root,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPad),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            decoration: BoxDecoration(
                color: C.sheet, borderRadius: BorderRadius.circular(14)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              if (title != null) ...[
                Container(
                  height: 52,
                  alignment: Alignment.center,
                  child: Text(title,
                      style: const TextStyle(
                          color: Color(0xFFBDBDBD), fontSize: 16)),
                ),
                const Divider(height: 1, color: Color(0xFF444446)),
              ],
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: Color(0xFF444446)),
                btn(options[i], () {
                  Navigator.pop(ctx);
                  onPick(options[i]);
                }),
              ],
            ]),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: C.sheet, borderRadius: BorderRadius.circular(14)),
            clipBehavior: Clip.antiAlias,
            child: btn('Batal', () => Navigator.pop(ctx), bold: true),
          ),
        ]),
      ),
    ),
  );
}


/// AppBar ala Wattpret asli: tinggi 48, garis tipis di bawah, judul tengah.
PreferredSizeWidget wAppBar(BuildContext context,
    {String? title,
    Widget? titleWidget,
    IconData leading = Icons.arrow_back,
    VoidCallback? onLeading,
    List<Widget>? actions,
    bool centerTitle = true,
    double titleSpacing = 0}) {
  return AppBar(
    toolbarHeight: 48,
    centerTitle: centerTitle,
    titleSpacing: titleSpacing,
    leading: IconButton(
        icon: Icon(leading, size: 26),
        onPressed: onLeading ?? () => Navigator.pop(context)),
    title: titleWidget ??
        Text(title ?? '',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
    actions: actions,
    bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFF2E2E2E))),
  );
}

/// Ikon info (i) berbingkai bulat seperti di halaman pengaturan cerita.
class InfoIcon extends StatelessWidget {
  final VoidCallback? onTap;
  const InfoIcon({super.key, this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.8)),
          child: const Text('i',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, height: 1)),
        ),
      );
}

/// Avatar bulat berisi huruf awal (untuk pengguna lain).
class LetterAvatar extends StatelessWidget {
  final String name;
  final double size;
  const LetterAvatar(this.name, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    const cols = [
      Color(0xFF3B6EA5),
      Color(0xFF8E5A9B),
      Color(0xFF3F8F7A),
      Color(0xFFB8643C),
      Color(0xFF6A7B3A),
      Color(0xFFA64B57),
    ];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration:
          BoxDecoration(shape: BoxShape.circle, color: cols[h % cols.length]),
      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }
}

/// Ikon + angka kecil (mata / bintang / komentar).
class MiniStat extends StatelessWidget {
  final IconData icon;
  final String text;
  const MiniStat(this.icon, this.text, {super.key});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 17, color: C.grey),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: C.grey, fontSize: 14)),
      ]);
}

/// Perkiraan jumlah vote dari teks views contoh ("24,5Jt" -> "2,1Jt").
String votesFromViews(String views) {
  final m = RegExp(r'^([\d,\.]+)\s*(Jt|Rb)?$').firstMatch(views.trim());
  if (m == null) return views;
  var n = double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0;
  if (m.group(2) == 'Jt') n *= 1e6;
  if (m.group(2) == 'Rb') n *= 1e3;
  final v = n * 0.085;
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1).replaceAll('.', ',')}Jt';
  if (v >= 1e3) return '${(v / 1e3).round()}Rb';
  return '${v.round()}';
}

/// Jumlah vote cerita: angka asli dari server bila ada, jika tidak perkiraan
/// dari views (untuk cerita contoh bawaan).
String votesOf(Story s) {
  final id = s.id;
  final n = id == null ? null : Story.voteCounts[id];
  return n != null ? fmtCount(n) : votesFromViews(s.views);
}

/// Garis putus-putus (kotak "+" tambah cerita).
class DashedRect extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRect(Offset.zero & size);
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Kotak peringatan gaya iOS (judul, isi, dua tombol).
Future<bool> showIosConfirm(BuildContext context,
    {required String title,
    required String message,
    String cancel = 'Batal',
    String ok = 'Ya',
    bool destructive = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: C.sheet,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(children: [
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.35)),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFF444446)),
        SizedBox(
          height: 48,
          child: Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => Navigator.pop(ctx, false),
                child: Center(
                    child: Text(cancel,
                        style: const TextStyle(
                            color: C.iosBlue, fontSize: 18))),
              ),
            ),
            const VerticalDivider(width: 1, color: Color(0xFF444446)),
            Expanded(
              child: InkWell(
                onTap: () => Navigator.pop(ctx, true),
                child: Center(
                    child: Text(ok,
                        style: TextStyle(
                            color: destructive ? C.red : C.iosBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w700))),
              ),
            ),
          ]),
        ),
      ]),
    ),
  );
  return r ?? false;
}


/// Banner iklan contoh dengan label "Iklan" di atasnya (tidak mengarah ke mana pun).
class AdBanner extends StatelessWidget {
  final double top;
  final bool onLight;
  const AdBanner({super.key, this.top = 14, this.onLight = false});

  @override
  Widget build(BuildContext context) {
    final lineC = onLight ? const Color(0xFFCFCFCF) : const Color(0xFF444444);
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 22),
          Expanded(child: Divider(color: lineC, height: 1)),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 64),
              child: Text('Iklan',
                  style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 13))),
          Expanded(child: Divider(color: lineC, height: 1)),
          const SizedBox(width: 22),
        ]),
        const SizedBox(height: 8),
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 22),
          color: Colors.white,
          child: Row(children: [
            Container(
                width: 50,
                height: 50,
                color: const Color(0xFF3B82F6),
                child: const Icon(Icons.auto_awesome, color: Colors.white)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contoh Iklan : Aplikasi Hemat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    Text('Ruang iklan contoh. Tidak mengarah ke mana pun.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: Color(0xFF666666), fontSize: 11)),
                  ]),
            ),
            Container(
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(16)),
              child: const Text('Buka',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Kartu "Bebas iklan - Membaca tanpa gangguan - Coba Premium".
class PremiumCard extends StatelessWidget {
  const PremiumCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
            color: C.premiumBg, borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                  color: Color(0xFF4B4768), shape: BoxShape.circle),
              child: const Icon(Icons.bolt, color: C.premium, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Bebas iklan',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Membaca tanpa gangguan',
                    style: TextStyle(fontSize: 15, color: Color(0xFFA8A8B0))),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const PremiumScreen())),
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFFA89BE6),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Coba Premium',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ),
          ),
        ]),
      );
}

/// Titik-titik indikator di atas halaman cerita (seperti carousel Wattpret).
class PageDots extends StatelessWidget {
  final int active, count;
  const PageDots({super.key, this.active = 0, this.count = 6});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == active ? 30 : (i >= count - 1 ? 5 : 9),
              height: i >= count - 1 ? 5 : 9,
              decoration: BoxDecoration(
                  color: i == active ? const Color(0xFFFF5A1F) : const Color(0xFF555555),
                  borderRadius: BorderRadius.circular(6)),
            ),
        ],
      );
}

/// Ikon lingkaran kecil dengan tanda "+" (untuk menambah ke daftar / komentar).
class PlusCircle extends StatelessWidget {
  final double size;
  final Color color;
  const PlusCircle({super.key, this.size = 40, this.color = const Color(0xFF9A9A9A)});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration:
            BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.6)),
        child: Icon(Icons.add, size: size * 0.55, color: color),
      );
}


/// Menu titik tiga pada pesan: "Laporkan pesan" (biru) dan "Hapus" (merah,
/// hanya untuk pesan milik sendiri), plus tombol "Batal".
Future<void> showMessageMenu(BuildContext context,
    {required bool own, VoidCallback? onDelete}) {
  return showIosSheet(
    context,
    [
      'Laporkan pesan',
      if (own) 'Hapus',
    ],
    (v) {
      if (v == 'Hapus') {
        onDelete?.call();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Pesan dilaporkan')));
      }
    },
    destructive: const ['Hapus'],
    itemHeight: 54,
    bottomPad: 22,
    root: true,
  );
}

/// Ikon "kirim" (pesawat kertas bergaris) seperti di aplikasi asli.
class SendIcon extends StatelessWidget {
  final double size;
  final Color color;
  const SendIcon({super.key, this.size = 24, this.color = Colors.white});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _SendPainter(color));
}

class _SendPainter extends CustomPainter {
  final Color color;
  _SendPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
        Path()
          ..moveTo(22 * k, 2 * k)
          ..lineTo(11 * k, 13 * k),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(22 * k, 2 * k)
          ..lineTo(15 * k, 22 * k)
          ..lineTo(11 * k, 13 * k)
          ..lineTo(2 * k, 9 * k)
          ..close(),
        p);
  }

  @override
  bool shouldRepaint(covariant _SendPainter old) => old.color != color;
}
