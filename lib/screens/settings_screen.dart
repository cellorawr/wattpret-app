import 'package:flutter/material.dart';
import '../api_service.dart';
import '../app_state.dart';
import '../theme.dart';
import 'settings_pages.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _go(BuildContext c, Widget w, {bool root = false}) =>
      Navigator.of(c, rootNavigator: root)
          .push(MaterialPageRoute(builder: (_) => w));

  Widget _tile(BuildContext c, String t, {required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
          child: Row(children: [
            Expanded(child: Text(t, style: const TextStyle(fontSize: 17))),
            const Icon(Icons.chevron_right, size: 28, color: Color(0xFF8A8A8A)),
          ]),
        ),
      );

  Widget _header(String t, {double top = 28}) => Container(
        width: double.infinity,
        color: const Color(0xFF1E1E1E),
        padding: EdgeInsets.fromLTRB(14, top, 14, 12),
        child: Text(t,
            style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontWeight: FontWeight.w800,
                fontSize: 15)),
      );

  /// Dialog konfirmasi bergaya iOS, lalu layar loading "Keluar", lalu kembali
  /// ke tampilan awal (Welcome / masuk).
  Future<void> _logout(BuildContext context) async {
    final nav = Navigator.of(context, rootNavigator: true);
    const bg = Color(0xFF262626);
    const line = Color(0xFF3A3A3C);
    const blue = Color(0xFF3F8CFF);

    Widget btn(BuildContext ctx, String t, bool confirm) => Expanded(
          child: InkWell(
            onTap: () => Navigator.pop(ctx, confirm),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              child: Text(t, style: const TextStyle(fontSize: 19, color: blue)),
            ),
          ),
        );

    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 270,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 18),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Apakah kamu yakin\ningin keluar?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  SizedBox(height: 6),
                  Text('Kamu akan keluar dari akunmu di perangkat ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15, height: 1.25, color: Colors.white)),
                ]),
              ),
              const Divider(height: 1, thickness: 1, color: line),
              SizedBox(
                height: 44,
                child: Row(children: [
                  btn(ctx, 'Batal', false),
                  Container(width: 1, color: line),
                  btn(ctx, 'Keluar', true),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) return;

    // Layar loading "Keluar" (kotak hitam + putaran).
    showDialog<void>(
      context: nav.context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            width: 160,
            height: 100,
            decoration: BoxDecoration(
                color: Colors.black, borderRadius: BorderRadius.circular(6)),
            child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        color: Color(0xFFE6E6E6),
                        backgroundColor: Color(0xFF3A3A3A)),
                  ),
                  SizedBox(height: 14),
                  Text('Keluar',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ]),
          ),
        ),
      ),
    );
    try {
      await Api.logout();
    } catch (_) {}
    AppState.resetSession();
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Pengaturan'),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFF2E2E2E))),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            _tile(context, 'Profil',
                onTap: () => _go(context, const ProfileSettingsScreen())),
            _tile(context, 'Akun',
                onTap: () => _go(context, const AccountScreen())),
            _tile(context, 'Notifikasi',
                onTap: () => _go(context, const NotificationSettingsScreen())),
            _tile(context, 'Mode gelap',
                onTap: () => _go(context, const DarkModeScreen())),
            _header('PRIVASI & KEAMANAN'),
            _tile(context, 'Preferensi konten',
                onTap: () => _go(context, const ContentPrefsScreen())),
            _tile(context, 'Akun yang disenyapkan',
                onTap: () => _go(
                    context,
                    const EmptyUsersScreen(
                        'Akun yang disenyapkan',
                        'Tidak ada pengguna yang disenyapkan.',
                        'Setelah kamu senyapkan seseorang, kamu tidak akan lagi menerima pesan, komentar cerita, atau postingan darinya.'))),
            _tile(context, 'Akun yang diblokir',
                onTap: () => _go(
                    context,
                    const EmptyUsersScreen(
                        'Akun yang diblokir',
                        'Tidak ada pengguna yang diblokir.',
                        'Ketika kamu memblokir seseorang, orang tersebut tidak akan bisa mengikutimu, mengirim pesan, memposting di profilmu, membaca dan mengomentari ceritamu.'))),
            _header('LANGGANAN'),
            _tile(context, 'Langganan premium',
                onTap: () => _go(context, const PremiumScreen(), root: true)),
            _tile(context, 'Personalisasi tema',
                onTap: () => _go(context, const ThemePersonalizeScreen())),
            _header('LAINNYA'),
            _tile(context, 'Akun tertaut',
                onTap: () => _go(context, const LinkedAccountsScreen())),
            _tile(context, 'Undang teman',
                onTap: () => _go(context, const InviteFriendsScreen())),
            _tile(context, 'Tentang Wattpret',
                onTap: () => _go(context, const AboutScreen())),
            _tile(context, 'Bantuan & dukungan',
                onTap: () => _go(context, const HelpSupportScreen())),
            InkWell(
              onTap: () => _go(context, const LicensesScreen()),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 17),
                child: Row(children: [
                  Expanded(
                      child:
                          Text('Versi 11.41.0', style: TextStyle(fontSize: 17))),
                  Icon(Icons.info_outline, color: Color(0xFF1E90FF), size: 28),
                ]),
              ),
            ),
            Container(height: 36, color: const Color(0xFF1E1E1E)),
            InkWell(
              onTap: () => _logout(context),
              child: Container(
                width: double.infinity,
                color: C.bg,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: const Text('Keluar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: C.red, fontSize: 17)),
              ),
            ),
            Container(
              width: double.infinity,
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: const Text('© 2026 Wattpret',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 14)),
            ),
          ]),
        ),
      ]),
    );
  }
}
