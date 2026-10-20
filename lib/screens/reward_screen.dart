import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets.dart';
import 'settings_pages.dart' show PremiumScreen;

/// Pusat Hadiah: Beli / Dapatkan Koin (+ Lewati Iklan).
/// Tampilan mengikuti aplikasi asli.
class RewardScreen extends StatefulWidget {
  /// 0 = Beli, 1 = Dapatkan.
  final int initialTab;
  const RewardScreen({super.key, this.initialTab = 1});
  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  late int _tab = widget.initialTab; // 0 = Beli, 1 = Dapatkan
  int _chip = 0; // 0 = Koin, 1 = Lewati Iklan
  int _skips = 0;
  final _webScroll = ScrollController();
  bool _skipPref = false;
  Timer? _timer;
  late String _updated = _now();

  static const _cardBg = Color(0xFF2B2B2D);
  static const _lavender = Color(0xFFD5CFF5);
  static const _premiumBg = Color(0xFF35354A);

  static String _now() {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _webScroll.dispose();
    super.dispose();
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  void _refresh() {
    setState(() => _updated = _now());
    _snack('Saldo Koin diperbarui');
  }

  // ------------------------------ KOMPONEN DASAR -----------------------------
  Widget _coin(double size) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFC72C),
            border: Border.all(
                color: const Color(0xFFE8A413), width: size > 24 ? 1.2 : 0.8)),
        child: WLogo(size: size * 0.55, color: Colors.white),
      );

  /// Ikon paket koin (tumpukan / toples / kantung / peti).
  Widget _packIcon(int n) {
    Widget at(double l, double b, Widget w) =>
        Positioned(left: l, bottom: b, child: w);
    final kids = <Widget>[];
    if (n == 30) {
      kids.addAll([
        at(14, 18, Transform.rotate(angle: -0.5, child: _coin(22))),
        at(2, 10, Transform.rotate(angle: 0.3, child: _coin(24))),
        at(18, 4, _coin(24)),
        Positioned(
            right: -2,
            top: 6,
            child: Transform.rotate(
                angle: -0.6,
                child: Container(
                    width: 26,
                    height: 6,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE5533D),
                        borderRadius: BorderRadius.circular(4))))),
      ]);
    } else if (n == 90) {
      kids.addAll([
        Positioned(
            left: 9,
            bottom: 0,
            child: Container(
              width: 36,
              height: 42,
              decoration: BoxDecoration(
                  color: const Color(0x33A9C8E8),
                  border: Border.all(color: const Color(0x99B8D4F2)),
                  borderRadius: BorderRadius.circular(9)),
            )),
        at(13, 3, _coin(15)),
        at(26, 3, _coin(15)),
        at(19, 12, _coin(15)),
        at(14, 21, _coin(15)),
        at(26, 21, _coin(15)),
        at(19, 28, _coin(14)),
        Positioned(
            left: 14,
            top: 2,
            child: Container(
                width: 26,
                height: 8,
                decoration: BoxDecoration(
                    color: const Color(0xFF5A6BB5),
                    borderRadius: BorderRadius.circular(3)))),
      ]);
    } else if (n == 270) {
      kids.addAll([
        Positioned(
            left: 4,
            bottom: 0,
            child: Container(
              width: 46,
              height: 34,
              decoration: const BoxDecoration(
                  color: Color(0xFF4B4F9E),
                  borderRadius: BorderRadius.all(Radius.elliptical(23, 17))),
            )),
        at(8, 22, _coin(16)),
        at(22, 26, _coin(16)),
        at(30, 20, _coin(16)),
        at(16, 12, _coin(16)),
        Positioned(
            left: 6,
            top: 4,
            child: Transform.rotate(
                angle: -0.7,
                child: Container(width: 3, height: 18, color: const Color(0xFF6C74C9)))),
      ]);
    } else {
      kids.addAll([
        Positioned(
            left: 2,
            bottom: 0,
            child: Container(
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                  color: const Color(0xFF5B5FB0),
                  border: Border.all(color: const Color(0xFF3F4283), width: 1.5),
                  borderRadius: BorderRadius.circular(4)),
              child: Center(
                  child: Container(
                      width: 18, height: 10, color: const Color(0xFFEDEDF7))),
            )),
        at(8, 24, _coin(16)),
        at(22, 28, _coin(17)),
        at(35, 24, _coin(16)),
        at(15, 34, _coin(15)),
        at(28, 36, _coin(15)),
      ]);
    }
    return SizedBox(
        width: 56, height: 54, child: Stack(clipBehavior: Clip.none, children: kids));
  }

  // --------------------------------- SEGMEN ----------------------------------
  Widget _segmented() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: const Color(0xFF2B2B2D),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          for (var i = 0; i < 2; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = i),
                child: Container(
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color:
                          _tab == i ? const Color(0xFF5A5A5C) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6.5)),
                  child: Text(i == 0 ? 'Beli' : 'Dapatkan',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white)),
                ),
              ),
            ),
        ]),
      );

  Widget _chipBtn(String t, int i) {
    final on = _chip == i;
    return GestureDetector(
      onTap: () => setState(() => _chip = i),
      child: Container(
        height: 35,
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: on ? Colors.white : const Color(0xFF2B2B2D),
            borderRadius: BorderRadius.circular(5)),
        child: Text(t,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: on ? Colors.black : Colors.white)),
      ),
    );
  }

  // --------------------------------- SALDO -----------------------------------
  Widget _balance() => ValueListenableBuilder<int>(
        valueListenable: AppState.coins,
        builder: (_, coins, __) => Container(
          height: 97,
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          decoration: BoxDecoration(
              color: const Color(0xFF1E1E1F),
              borderRadius: BorderRadius.circular(8)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(children: [
              _coin(20),
              const SizedBox(width: 8),
              Text('$coins',
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w600, height: 1.1)),
              const Spacer(),
              Text('Terakhir diperbarui pada $_updated',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB4B4B4))),
              const SizedBox(width: 8),
              GestureDetector(
                  onTap: _refresh,
                  child: const Icon(Icons.sync, size: 22, color: Colors.white)),
            ]),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Pembelian ',
                    style: TextStyle(fontSize: 16, color: Color(0xFFB4B4B4))),
                Text('$coins',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                Container(width: 1, height: 13, color: const Color(0xFF666666)),
                const SizedBox(width: 12),
                const Text('Bonus ',
                    style: TextStyle(fontSize: 16, color: Color(0xFFB4B4B4))),
                const Text('0',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right, size: 20),
              ]),
            ),
          ]),
        ),
      );

  /// Kartu saldo Lewati Iklan (ikon + jumlah saja).
  Widget _skipBalance() => Container(
        height: 97,
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
            color: const Color(0xFF1E1E1F),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.skip_next_outlined, size: 24),
          const SizedBox(width: 8),
          Text('$_skips',
              style: const TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w600, height: 1.1)),
        ]),
      );

  // ------------------------------- TAB BELI ----------------------------------
  Widget _premiumBanner() => Container(
        height: 117,
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.fromLTRB(18, 0, 14, 0),
        decoration: BoxDecoration(
            color: _premiumBg, borderRadius: BorderRadius.circular(7)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                  left: 4,
                  top: 0,
                  child: Transform.rotate(
                      angle: 0.75,
                      child: const Icon(Icons.vpn_key,
                          size: 52, color: Color(0xFFF2C628)))),
              Positioned(
                  left: 0,
                  bottom: 6,
                  child: Container(
                      width: 12,
                      height: 34,
                      decoration: BoxDecoration(
                          color: const Color(0xFF2AA9A0),
                          borderRadius: BorderRadius.circular(3)))),
              Positioned(
                  left: 26,
                  bottom: 0,
                  child: Container(
                      width: 14,
                      height: 38,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8472E),
                          borderRadius: BorderRadius.circular(3)))),
              Positioned(right: 0, bottom: 4, child: _coin(14)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                          fontSize: 14.5, height: 1.3, color: Color(0xFFE8E4FA)),
                      children: [
                        TextSpan(text: 'Penawaran terbaik: dapatkan '),
                        TextSpan(
                            text: '200 Bonus Koin',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: ' untuk sebulan, bebas iklan, dan banyak lagi.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PremiumScreen())),
                    child: Container(
                      width: double.infinity,
                      height: 26,
                      decoration: BoxDecoration(
                          color: _lavender, borderRadius: BorderRadius.circular(14)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.bolt, size: 12, color: Colors.black),
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 54,
                          child: Text('Beralih ke Premium+',
                              maxLines: 2,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12.5,
                                  height: 1.05,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  ),
                ]),
          ),
        ]),
      );

  // (koin, harga, bonus Premium)
  static const _packs = <(int, String, int)>[
    (30, 'Rp10.000', 9),
    (90, 'Rp25.000', 27),
    (270, 'Rp67.000', 81),
    (500, 'Rp125.000', 150),
  ];

  Widget _buy() {
    return ListView(padding: EdgeInsets.zero, children: [
      const SizedBox(height: 23),
      _premiumBanner(),
      const SizedBox(height: 22),
      for (final p in _packs)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppState.buyCoins(p.$1);
            _snack('+${p.$1} Koin ditambahkan (demo)');
          },
          child: Container(
            height: 73,
            margin: const EdgeInsets.fromLTRB(15, 0, 15, 12),
            padding: const EdgeInsets.fromLTRB(12, 0, 11, 0),
            decoration: BoxDecoration(
                color: _cardBg, borderRadius: BorderRadius.circular(5)),
            child: Row(children: [
              _packIcon(p.$1),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${p.$1} Coins',
                          style: const TextStyle(
                              fontSize: 19.5, fontWeight: FontWeight.w500, height: 1.15)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text('+${p.$3} dengan Premium',
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFFA6A6A8))),
                        const SizedBox(width: 3),
                        const Icon(Icons.bolt, size: 11, color: Color(0xFFA6A6A8)),
                      ]),
                    ]),
              ),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 19),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFF3E3E40),
                    borderRadius: BorderRadius.circular(17)),
                child: Text(p.$2,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      const SizedBox(height: 12),
    ]);
  }

  // ------------------------------ TAB DAPATKAN -------------------------------
  Widget _outlineBtn(Widget? lead, String t, VoidCallback onTap,
          {double? width}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: 33,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1.6),
              borderRadius: BorderRadius.circular(20)),
          child: Row(
              mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (lead != null) ...[lead, const SizedBox(width: 8)],
                Text(t,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
        ),
      );

  Widget _offerCard(String title, String sub, IconData icon,
          {required Widget button, Widget? footer}) =>
      Container(
        width: double.infinity,
        height: 149,
        margin: const EdgeInsets.fromLTRB(0.5, 0, 0.5, 16),
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        decoration: BoxDecoration(
            color: const Color(0xFF141414),
            border: Border.all(color: const Color(0xFF3C3C3C), width: 1),
            borderRadius: BorderRadius.circular(4)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 17),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w700, height: 1.15)),
                const SizedBox(height: 5),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 14.5, color: Color(0xFFA4A4A4), height: 1.15)),
                const SizedBox(height: 14),
                button,
                if (footer != null) ...[const SizedBox(height: 9), footer],
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: Color(0xFF27272A), shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: Colors.white),
            ),
          ),
        ]),
      );

  /// Sampul mini untuk kotak "Wattpret Originals" (terpotong di bawah).
  Widget _miniCovers() => SizedBox(
        height: 66,
        child: ClipRect(
          child: Padding(
            padding: const EdgeInsets.only(left: 81),
            child: Stack(clipBehavior: Clip.hardEdge, children: [
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 61,
                  height: 92,
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 30),
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF6B5D58), Color(0xFF2B2422)])),
                  child: const Text('mezzanin',
                      style: TextStyle(
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                          color: Color(0xFFBDB5B0))),
                ),
              ),
              Positioned(
                left: 53,
                top: 3,
                child: Container(
                  width: 61,
                  height: 92,
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF3C8FB8), Color(0xFF123D5C)])),
                  child: const Column(children: [
                    Text('DEAD',
                        style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDCEBF4))),
                    Text('IF',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8DBBD6))),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _earn() {
    return Column(children: [
      _offerCard(
        'Penawaran Koin',
        'Selesaikan misi untuk dapatkan Bonus Koin',
        Icons.celebration_outlined,
        button: _outlineBtn(_coin(20), 'Dapatkan 1000+ Koin',
            () => _snack('Penawaran Koin belum tersedia di versi demo')),
        footer: const Text.rich(TextSpan(
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFA8A8A8)),
            children: [
              TextSpan(text: 'Penawaran Koin disediakan oleh '),
              TextSpan(text: 'Tapjoy', style: TextStyle(color: Color(0xFF6FC9C3))),
            ])),
      ),
      _offerCard(
        'Video iklan',
        'Tonton iklan untuk dapatkan Bonus Koin',
        Icons.movie_creation_outlined,
        button: _outlineBtn(_coin(20), 'Dapatkan hingga 10 Koin', () {
          final ok = AppState.claimDaily();
          setState(() {});
          _snack(ok
              ? 'Kamu mendapat 10 Koin!'
              : 'Tidak ada iklan yang tersedia saat ini');
        }),
      ),
      const SizedBox(height: 14),
      const Padding(
        padding: EdgeInsets.only(left: 4),
        child: SizedBox(
          width: double.infinity,
          child: Text('Koin yang diperoleh di sini akan kedaluwarsa dalam 30 hari',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: TextStyle(fontSize: 14.5, color: Color(0xFFBDBDBD))),
        ),
      ),
      const SizedBox(height: 34),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.only(top: 18),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD0D0D0), width: 1),
            borderRadius: BorderRadius.circular(2)),
        child: Column(children: [
          const Text('Gunakan Koin untuk membaca\nWattpret Originals',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 19.5, fontWeight: FontWeight.w700, height: 1.18)),
          const SizedBox(height: 8),
          const Text('Koleksi bacaan pilihan. Dijamin terhibur.',
              style: TextStyle(fontSize: 14.5, color: Color(0xFFBDBDBD))),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _outlineBtn(
                null,
                'Jelajahi Wattpret Originals',
                () => _snack('Wattpret Originals belum tersedia di versi demo'),
                width: double.infinity),
          ),
          const SizedBox(height: 17),
          _miniCovers(),
        ]),
      ),
      const SizedBox(height: 57),
      for (final t in const ['FAQ Mendapatkan Koin', 'Kebijakan Pembayaran'])
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(t,
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
        ),
      const SizedBox(height: 20),
    ]);
  }

  // --------------------------- TAB DAPATKAN: LEWATI IKLAN --------------------
  Widget _skipTab() => Column(children: [
        Container(
          width: double.infinity,
          height: 149,
          margin: const EdgeInsets.fromLTRB(0.5, 0, 0.5, 22),
          padding: const EdgeInsets.fromLTRB(15, 17, 15, 0),
          decoration: BoxDecoration(
              color: const Color(0xFF141414),
              border: Border.all(color: const Color(0xFF3C3C3C)),
              borderRadius: BorderRadius.circular(4)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Video iklan',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                const Text('Tonton iklan untuk mendapatkan 3 Lewati Iklan',
                    style: TextStyle(
                        fontSize: 14.5, height: 1.15, color: Color(0xFFA4A4A4))),
                const SizedBox(height: 12),
                _outlineBtn(const Icon(Icons.play_arrow, size: 20),
                    'Dapatkan 3 Lewati Iklan', () {
                  setState(() => _skips += 3);
                  _snack('+3 Lewati Iklan ditambahkan (demo)');
                }),
              ]),
            ),
            const SizedBox(width: 10),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: Color(0xFF27272A), shape: BoxShape.circle),
              child: const Icon(Icons.movie_creation_outlined, size: 30),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
          child: Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Preferensi Lewati Iklan',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text(
                    'Jika diaktifkan, kamu bisa mendapatkan Lewati Iklan di antara bab cerita saat kamu membaca',
                    style: TextStyle(
                        fontSize: 14, height: 1.3, color: Color(0xFFA5A5A5))),
              ]),
            ),
            const SizedBox(width: 10),
            Switch(
              value: _skipPref,
              onChanged: (v) => setState(() => _skipPref = v),
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFFE8703A),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF3A3A3C),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ]),
        ),
        const SizedBox(height: 26),
        const Text('FAQ Lewati Iklan',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 40),
      ]);

  /// Area hitam (seperti web view) berisi konten tab Dapatkan.
  Widget _webArea(Widget child) => Container(
        margin: const EdgeInsets.fromLTRB(15, 23, 15, 7),
        color: Colors.black,
        child: RawScrollbar(
          controller: _webScroll,
          thumbVisibility: true,
          thickness: 2.5,
          radius: const Radius.circular(2),
          thumbColor: const Color(0xFF8A8A8A),
          padding: const EdgeInsets.only(right: 4, top: 14, bottom: 4),
          child: ListView(
            controller: _webScroll,
            padding: const EdgeInsets.only(top: 12),
            children: [child],
          ),
        ),
      );

  // ------------------------------ POPUP "CARA KERJANYA" ----------------------
  void _showHowItWorks() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) {
        const gray = Color(0xFFA8A8A8);
        const body = TextStyle(fontSize: 14.5, height: 1.8, color: gray);
        Widget bullet(String t) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                  width: 18,
                  child: Text('•',
                      textAlign: TextAlign.center, style: body)),
              const SizedBox(width: 3),
              Expanded(child: Text(t, style: body)),
            ]);
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.9,
          decoration: const BoxDecoration(
              color: Color(0xFF141414),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(19, 0, 19, 30),
            children: [
              SizedBox(
                height: 55,
                child: Row(children: [
                  const Expanded(
                      child: Text('Cara kerjanya',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700))),
                  GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Padding(
                          padding: EdgeInsets.fromLTRB(8, 8, 5, 8),
                          child: Icon(Icons.close, size: 24))),
                ]),
              ),
              const SizedBox(height: 22),
              const Text('Koin yang Dibeli',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Koin yang kamu beli dari toko Koin.', style: body),
              const SizedBox(height: 17),
              const Text('Bonus Koin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Coins you have earned on Wattpret.', style: body),
              bullet('You can earn Bonus Coins by redeeming Coin Offers, watching ads, etc.'),
              bullet('When redeeming Coins, Bonus Coins will be spent before Purchased Coins.'),
              bullet('Bonus Coins expire after earning them. Check out the FAQ below to learn more.'),
              const SizedBox(height: 24),
              const Center(
                  child: Text('FAQ Mendapatkan Koin',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              const SizedBox(height: 22),
              Center(
                child: SizedBox(
                    width: 177,
                    height: 177,
                    child: CustomPaint(painter: _HelpArtPainter())),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final skipView = _tab == 1 && _chip == 1;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: 46,
        leadingWidth: 56,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: const Padding(
                padding: EdgeInsets.only(left: 25, right: 10),
                child: Icon(Icons.arrow_back, size: 23)),
          ),
        ),
        title: const Text('Pusat Hadiah'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25),
            child: GestureDetector(
              onTap: _showHowItWorks,
              child: Container(
                width: 19,
                height: 19,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.6)),
                child: const Text('?',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, height: 1.0)),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFF2E2E2E))),
      ),
      body: Column(children: [
        const SizedBox(height: 15),
        _segmented(),
        const SizedBox(height: 15),
        if (_tab == 1) ...[
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(children: [_chipBtn('Koin', 0), _chipBtn('Lewati Iklan', 1)]),
          ),
          const SizedBox(height: 16),
        ],
        if (skipView) _skipBalance() else _balance(),
        Expanded(
          child: _tab == 0
              ? _buy()
              : _webArea(skipView ? _skipTab() : _earn()),
        ),
      ]),
    );
  }
}

/// Ilustrasi "kunci emas + orang-orang" pada popup Cara kerjanya.
class _HelpArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 335, size.height / 335);
    Paint f(int c) => Paint()..color = Color(c);
    RRect rr(double l, double t, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r));

    const pink = 0xFFF6C6DD, gold = 0xFFF2C628, goldD = 0xFFC9981A;
    const teal = 0xFF2AA9A0, navy = 0xFF2F6E8E, red = 0xFFE8472E, org = 0xFFF28A2E;

    // awan & panah merah muda
    canvas.drawRRect(rr(60, 20, 150, 38, 19), f(pink));
    canvas.drawRRect(rr(0, 160, 150, 38, 19), f(pink));
    canvas.drawRRect(rr(235, 112, 100, 22, 11), f(pink));
    canvas.drawPath(
        Path()
          ..moveTo(78, 22)
          ..lineTo(120, 8)
          ..lineTo(110, 40)
          ..close(),
        f(pink));
    canvas.drawPath(
        Path()
          ..moveTo(215, 235)
          ..lineTo(270, 245)
          ..lineTo(222, 285)
          ..close(),
        f(pink));

    // buku
    final bookC = [0xFF2F7F96, 0xFFEFEFEF, 0xFF2F7F96, 0xFFEFEFEF];
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(rr(148, 268 + i * 13.0, 68, 11, 2), f(bookC[i]));
    }

    // orang kiri
    canvas.drawRRect(rr(64, 188, 40, 70, 8), f(teal));
    canvas.drawRRect(rr(66, 255, 14, 50, 4), f(navy));
    canvas.drawRRect(rr(86, 255, 14, 50, 4), f(navy));
    canvas.drawRRect(rr(60, 302, 24, 10, 4), f(0xFFE5E5E5));
    canvas.drawRRect(rr(84, 302, 24, 10, 4), f(0xFFE5E5E5));
    canvas.drawRRect(rr(60, 152, 10, 46, 5), f(teal));
    canvas.drawRRect(rr(98, 152, 10, 46, 5), f(teal));

    // orang tengah (jaket merah)
    canvas.drawCircle(const Offset(176, 150), 16, f(0xFF5A3A2A));
    canvas.drawRRect(rr(146, 160, 54, 70, 12), f(red));
    canvas.drawRRect(rr(152, 226, 16, 44, 4), f(0xFFB86B3F));
    canvas.drawRRect(rr(176, 226, 16, 44, 4), f(0xFFB86B3F));
    canvas.drawRRect(rr(128, 122, 10, 56, 5), f(red));

    // orang kanan atas (diangkat)
    canvas.drawCircle(const Offset(228, 56), 12, f(0xFF5A3A2A));
    canvas.drawRRect(rr(214, 68, 28, 34, 8), f(0xFFF4F4F4));
    canvas.drawRRect(rr(214, 100, 28, 22, 6), f(teal));
    canvas.drawRRect(rr(218, 120, 8, 30, 3), f(0xFFB86B3F));
    canvas.drawRRect(rr(230, 120, 8, 30, 3), f(0xFFB86B3F));

    // orang kanan bawah
    canvas.drawRRect(rr(232, 190, 48, 56, 10), f(navy));
    canvas.drawRRect(rr(240, 242, 14, 52, 4), f(org));
    canvas.drawRRect(rr(262, 242, 14, 52, 4), f(org));

    // koin emas kanan bawah
    canvas.drawCircle(const Offset(290, 262), 26, f(gold));
    canvas.drawCircle(
        const Offset(290, 262),
        26,
        Paint()
          ..color = const Color(goldD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    // kunci emas (diagonal)
    canvas.save();
    canvas.translate(110, 150);
    canvas.rotate(-0.68);
    canvas.drawRRect(rr(20, -10, 190, 20, 6), f(gold));
    canvas.drawRRect(rr(176, 4, 14, 30, 3), f(gold));
    canvas.drawRRect(rr(196, 4, 14, 22, 3), f(gold));
    canvas.restore();
    for (final o in const [Offset(88, 128), Offset(66, 152), Offset(92, 176)]) {
      canvas.drawCircle(o, 22, f(gold));
    }
    canvas.drawCircle(const Offset(88, 152), 30, f(gold));
    canvas.drawCircle(const Offset(88, 152), 9, f(0xFF141414));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
