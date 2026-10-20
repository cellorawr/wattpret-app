import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Layar kamera langsung (live preview) untuk mengambil foto.
/// Dipakai saat "Mengambil Foto" dipilih di web/desktop, di mana
/// image_picker hanya membuka pemilih berkas (galeri), bukan kamera.
///
/// Mengembalikan [Uint8List] berisi foto lewat `Navigator.pop`, atau `null`
/// bila dibatalkan / kamera tidak tersedia.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cams = [];
  CameraController? _ctrl;
  int _index = 0;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      _cams = await availableCameras();
      if (_cams.isEmpty) {
        setState(() => _error = 'Kamera tidak ditemukan di perangkat ini.');
        return;
      }
      // Utamakan kamera belakang bila ada.
      final back = _cams.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      _index = back >= 0 ? back : 0;
      await _start(_cams[_index]);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.code.toLowerCase().contains('denied') ||
              e.code.toLowerCase().contains('permission')
          ? 'Izin kamera ditolak. Izinkan akses kamera lalu coba lagi.'
          : 'Tidak bisa membuka kamera (${e.code}).');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Tidak bisa membuka kamera.');
    }
  }

  Future<void> _start(CameraDescription cam) async {
    final old = _ctrl;
    final c = CameraController(cam, ResolutionPreset.high, enableAudio: false);
    setState(() => _ctrl = null);
    await old?.dispose();
    await c.initialize();
    if (!mounted) {
      await c.dispose();
      return;
    }
    setState(() => _ctrl = c);
  }

  Future<void> _switch() async {
    if (_cams.length < 2 || _busy) return;
    _busy = true;
    try {
      _index = (_index + 1) % _cams.length;
      await _start(_cams[_index]);
    } catch (_) {
      if (mounted) setState(() => _error = 'Tidak bisa berpindah kamera.');
    } finally {
      _busy = false;
    }
  }

  Future<void> _shoot() async {
    final c = _ctrl;
    if (c == null || !c.value.isInitialized || _busy) return;
    _busy = true;
    try {
      final x = await c.takePicture();
      final bytes = await x.readAsBytes();
      if (mounted) Navigator.pop(context, bytes);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal mengambil foto.');
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctrl;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          Positioned.fill(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 17)),
                    ),
                  )
                : (c == null || !c.value.isInitialized)
                    ? const Center(child: CircularProgressIndicator())
                    : Center(child: CameraPreview(c)),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (_error == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 64),
                  GestureDetector(
                    onTap: _shoot,
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4)),
                      child: const DecoratedBox(
                          decoration: BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: _cams.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.cameraswitch,
                                color: Colors.white, size: 30),
                            onPressed: _switch,
                          )
                        : null,
                  ),
                ],
              ),
            ),
        ]),
      ),
    );
  }
}
