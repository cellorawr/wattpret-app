import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/settings_pages.dart' show SettingsStore;
import 'screens/welcome_screen.dart';
import 'api_service.dart';
import 'data.dart' show ServerStories;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.init();
  ServerStories.load(); // ambil cerita dari server (tanpa menunggu)
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const WattpretApp());
}

/// Ukuran layar HP virtual (rasio 9 : 19,5 seperti HP modern).
/// Di Chrome/desktop aplikasi digambar pada ukuran ini lalu diskalakan agar
/// pas dengan tinggi jendela, jadi panjang : lebarnya selalu sama dengan HP.
/// Tidak ada bingkai HP; sisi kiri-kanan hitam polos.
/// Di HP asli (lebar < [kPhoneBreakpoint]) aplikasi memakai layar penuh.
const Size kPhoneSize = Size(390, 844);
const double kPhoneBreakpoint = 600;

/// Teks sedikit diperkecil supaya proporsinya seperti aplikasi mobile.
const double kTextScale = 0.86;

class WattpretApp extends StatelessWidget {
  const WattpretApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wattpret',
      theme: buildTheme(),
      builder: (context, child) => ValueListenableBuilder<String>(
        valueListenable: SettingsStore.darkMode,
        builder: (context, mode, _) {
          // Aktif = gelap, Nonaktif = terang, Otomatis = ikut pengaturan HP.
          final light = mode == 'Nonaktif' ||
              (mode == 'Otomatis' &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.light);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: light
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
            child: LightScope(
              light: light,
              child: _PhoneViewport(
                  light: light, child: child ?? const SizedBox.shrink()),
            ),
          );
        },
      ),
      home: const WelcomeScreen(),
    );
  }
}

class _PhoneViewport extends StatelessWidget {
  final Widget child;
  final bool light;
  const _PhoneViewport({required this.child, required this.light});

  Widget _paint(Widget c) {
    final body = ColoredBox(color: C.bg, child: c);
    return light
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix(kInvertHue), child: body)
        : body;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scaler = TextScaler.linear(mq.textScaler.scale(1) * kTextScale);

    // HP asli: layar penuh.
    if (mq.size.width < kPhoneBreakpoint) {
      return MediaQuery(
        data: mq.copyWith(textScaler: scaler),
        child: _paint(child),
      );
    }

    // Chrome / desktop: kolom berproporsi HP, setinggi jendela.
    const pad = EdgeInsets.only(top: 14, bottom: 8);
    return ColoredBox(
      color: light ? const Color(0xFFE6E6E6) : Colors.black,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: kPhoneSize.width,
            height: kPhoneSize.height,
            child: MediaQuery(
              data: mq.copyWith(
                size: kPhoneSize,
                padding: pad,
                viewPadding: pad,
                textScaler: scaler,
              ),
              child: ClipRect(child: _paint(child)),
            ),
          ),
        ),
      ),
    );
  }
}
