import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import 'details_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _toDetails(BuildContext c) => Navigator.push(
      c, MaterialPageRoute(builder: (_) => const DetailsScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(children: [
            const Spacer(flex: 3),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('wattpret',
                  style: TextStyle(
                      color: C.orange,
                      fontSize: 44,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1)),
              SizedBox(width: 8),
              WLogo(size: 54),
            ]),
            const SizedBox(height: 34),
            const Text('Komunitas global\nterbesar untuk bercerita',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 31, fontWeight: FontWeight.w800, height: 1.25)),
            const SizedBox(height: 28),
            _Social(
                icon: const Text('G',
                    style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.w900,
                        fontSize: 22)),
                label: 'Daftar dengan Google',
                onTap: () {}), // belum difungsikan
            const SizedBox(height: 14),
            _Social(
                icon: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                        color: const Color(0xFF3B5998),
                        borderRadius: BorderRadius.circular(3)),
                    child: const Text('f',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            height: 1))),
                label: 'Daftar dengan Facebook',
                onTap: () {}), // belum difungsikan
            const SizedBox(height: 14),
            Row(children: const [
              Expanded(child: Divider(color: Color(0xFF333333))),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('atau',
                      style: TextStyle(color: C.grey, fontSize: 13))),
              Expanded(child: Divider(color: Color(0xFF333333))),
            ]),
            const SizedBox(height: 14),
            WhiteButton('Daftar dengan email', onTap: () => _toDetails(context)),
            const Spacer(flex: 4),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('Saya sudah memiliki akun',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Social extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color bg;
  final bool bold;
  final VoidCallback onTap;
  const _Social(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.bg = Colors.transparent,
      this.bold = true});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFD0D0D0), width: 1.3)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            icon,
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: bold ? 16 : 19,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
          ]),
        ),
      );
}
