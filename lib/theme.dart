import 'package:flutter/material.dart';

class C {
  static const bg = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const orange = Color(0xFFFF6122);
  static const red = Color(0xFFFF5A3C);
  static const teal = Color(0xFF74D0CF);
  static const link = Color(0xFF7CCFC9);
  static const grey = Color(0xFF9E9E9E);
  static const chip = Color(0xFF2A2A2A);
  static const tan = Color(0xFFBF8B68);
  static const sheet = Color(0xFF2C2C2E);
  static const iosBlue = Color(0xFF4C9AFF);
  static const premium = Color(0xFFA89BE6); // ungu "Tanpa Iklan / Premium"
  static const premiumBg = Color(0xFF33323F);
  static const sepia = Color(0xFFFAEFD9);
  static const line = Color(0xFF2E2E2E);
}

ThemeData buildTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(primary: C.orange, surface: C.bg),
    splashFactory: NoSplash.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
    ),
  );
}

/// Font berkait (serif) untuk editor bab, seperti di Wattpret.
const TextStyle kSerif = TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: ['Times New Roman', 'serif'],
    fontSize: 20);


/// Mode terang: seluruh aplikasi digambar dengan tema gelap lalu warnanya
/// dibalik (terang <-> gelap) sambil mempertahankan rona (oranye tetap oranye).
const List<double> kInvertHue = <double>[
  0.574, -1.430, -0.144, 0, 255, //
  -0.426, -0.430, -0.144, 0, 255, //
  -0.426, -1.430, 0.856, 0, 255, //
  0, 0, 0, 1, 0,
];

/// Menyimpan apakah aplikasi sedang dalam mode terang.
class LightScope extends InheritedWidget {
  final bool light;
  const LightScope({super.key, required this.light, required super.child});

  static bool of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<LightScope>()?.light ?? false;

  @override
  bool updateShouldNotify(LightScope old) => old.light != light;
}

/// Membatalkan pembalikan warna untuk isi tertentu (foto, sampul, halaman biru
/// Premium, dll.) supaya warnanya tetap seperti aslinya di mode terang.
class LightCounter extends StatelessWidget {
  final Widget child;
  final bool? enabled;
  const LightCounter({super.key, required this.child, this.enabled});

  @override
  Widget build(BuildContext context) {
    if (!(enabled ?? LightScope.of(context))) return child;
    return ColorFiltered(
        colorFilter: const ColorFilter.matrix(kInvertHue), child: child);
  }
}
