import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

// ===========================================================================
// Halaman-halaman pengisian "Edit Cerita". Masing-masing halaman baru
// (bukan pop-up), seperti di aplikasi Wattpret asli.
// ===========================================================================

const kStoryTypes = ['Fiksi', 'Fiksi Penggemar', 'Nonfiksi', 'Puisi'];

const kStoryTypeIntro =
    'Memilih jenis cerita akan memungkinkan kamu untuk menentukan genre, '
    'sub-Genre, fandom, klasifikasi fandom, dan lebih banyak lagi kategorisasi '
    'cerita yang akan membantu kami menghubungkan pembaca yang tepat dengan '
    'ceritamu secara lebih baik.';

const kFictionGenres = [
  'Aksi dan Thriller',
  'Budaya dan Identitas',
  'Fantasi',
  'Fiksi Ilmiah',
  'Fiksi Sejarah',
  'Horor',
  'LGBTQIA+',
  'Misteri',
  'Paranormal',
  'Romansa',
  'Tema Sosial',
];

const kNonFictionGenres = [
  'Biografi dan Memoar',
  'Esai',
  'Humor',
  'Jurnalisme',
  'Motivasi dan Pengembangan Diri',
  'Perjalanan',
  'Sains dan Teknologi',
  'Sejarah',
  'Spiritual',
];

const kFandomClasses = [
  'Musik dan Band',
  'Aktor dan Selebriti',
  'Film dan Serial TV',
  'Anime dan Manga',
  'Buku dan Sastra',
  'Game',
  'Olahraga',
  'Lainnya',
];

const kFandoms = [
  '1Direction',
  '2Moons',
  '5sos',
  '9-1-1',
  'A Court Of Thorns And Roses',
  'A\$AP Rocky',
  'Aaron Taylor-Johnson',
  'Ace Attorney',
  'aespa',
  'American Horror Story',
  'Among Us',
  'Anushka Sharma',
  'Ariana Grande',
  'Arknights',
  'Avengers',
  'Blackpink',
  'BTS',
  'Harry Potter',
  'Haikyuu!!',
  'Jujutsu Kaisen',
  'Naruto',
  'NCT',
  'One Piece',
  'Percy Jackson',
  'Seventeen',
  'Stray Kids',
  'Supernatural',
  'The Hunger Games',
  'Twice',
];

// ---------------------------------------------------------------------------
// Halaman isi teks (Judul, Deskripsi)
// ---------------------------------------------------------------------------
class TextEntryPage extends StatefulWidget {
  final String title, initial, hint;
  final bool multi;
  const TextEntryPage(
      {super.key,
      required this.title,
      this.initial = '',
      this.hint = '',
      this.multi = false});
  @override
  State<TextEntryPage> createState() => _TextEntryPageState();
}

class _TextEntryPageState extends State<TextEntryPage> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _done() => Navigator.pop(context, _c.text.trim());

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done();
      },
      child: Scaffold(
        appBar: wAppBar(context, title: widget.title, onLeading: _done),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _c,
            autofocus: true,
            minLines: widget.multi ? 6 : 1,
            maxLines: widget.multi ? null : 1,
            textInputAction:
                widget.multi ? TextInputAction.newline : TextInputAction.done,
            onSubmitted: widget.multi ? null : (_) => _done(),
            cursorColor: C.iosBlue,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle:
                  const TextStyle(color: Color(0xFF6E6E6E), fontSize: 18),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman Tag
// ---------------------------------------------------------------------------
class TagsPage extends StatefulWidget {
  final List<String> initial;
  const TagsPage({super.key, this.initial = const []});
  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  late final List<String> _tags = [...widget.initial];
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _add(String raw) {
    for (final t in raw.split(RegExp(r'[,#]+'))) {
      final v = t.trim().toLowerCase();
      if (v.isNotEmpty && !_tags.contains(v) && _tags.length < 25) _tags.add(v);
    }
    _c.clear();
    setState(() {});
  }

  void _done() {
    if (_c.text.trim().isNotEmpty) _add(_c.text);
    Navigator.pop(context, _tags);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done();
      },
      child: Scaffold(
        appBar: wAppBar(context, title: 'Tag', onLeading: _done),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 20), children: [
          TextField(
            controller: _c,
            autofocus: true,
            cursorColor: C.iosBlue,
            style: const TextStyle(fontSize: 18),
            onChanged: (v) {
              if (v.endsWith(',')) _add(v);
            },
            onSubmitted: _add,
            decoration: const InputDecoration(
              hintText: 'Tambahkan tag, pisahkan dengan koma',
              hintStyle: TextStyle(color: Color(0xFF6E6E6E), fontSize: 18),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in _tags)
              GestureDetector(
                onTap: () => setState(() => _tags.remove(t)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      color: C.chip, borderRadius: BorderRadius.circular(9)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(t,
                        style: const TextStyle(
                            fontSize: 15, color: Color(0xFFE0E0E0))),
                    const SizedBox(width: 6),
                    const Icon(Icons.close, size: 15, color: C.grey),
                  ]),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman daftar pilihan (Jenis cerita, Genre, Bahasa, Hak Cipta, dst.)
// ---------------------------------------------------------------------------
class OptionPage extends StatefulWidget {
  final String title;
  final List<String> options;
  final String selected;

  /// Teks pengantar di atas daftar (mis. penjelasan Jenis cerita).
  final String? intro;

  /// Label abu-abu di atas daftar yang bisa dilipat (mis. "Genre #1").
  final String? sectionLabel;
  final bool bold;

  /// Jika true, menekan pilihan yang sudah dipilih akan menghapusnya ("").
  final bool clearable;
  const OptionPage(
      {super.key,
      required this.title,
      required this.options,
      this.selected = '',
      this.intro,
      this.sectionLabel,
      this.bold = true,
      this.clearable = false});
  @override
  State<OptionPage> createState() => _OptionPageState();
}

class _OptionPageState extends State<OptionPage> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: wAppBar(context,
          title: widget.title, actions: [const InfoIcon(), const SizedBox(width: 4)]),
      body: ListView(padding: const EdgeInsets.only(bottom: 20), children: [
        if (widget.intro != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(widget.intro!,
                style: const TextStyle(fontSize: 16, height: 1.35)),
          ),
        if (widget.sectionLabel != null)
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
              child: Row(children: [
                Text(widget.sectionLabel!,
                    style: const TextStyle(fontSize: 16, color: C.grey)),
                const Spacer(),
                Icon(_open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: C.grey, size: 26),
              ]),
            ),
          ),
        if (_open || widget.sectionLabel == null)
          for (final o in widget.options)
            InkWell(
              onTap: () => Navigator.pop(
                  context, (widget.clearable && o == widget.selected) ? '' : o),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Row(children: [
                  Expanded(
                    child: Text(o,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                widget.bold ? FontWeight.w700 : FontWeight.w400)),
                  ),
                  if (o == widget.selected)
                    const Icon(Icons.check, color: C.orange, size: 22),
                ]),
              ),
            ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman Fandom (cari atau tambahkan sendiri)
// ---------------------------------------------------------------------------
class FandomPage extends StatefulWidget {
  final String title;
  final List<String> exclude;
  const FandomPage({super.key, required this.title, this.exclude = const []});
  @override
  State<FandomPage> createState() => _FandomPageState();
}

class _FandomPageState extends State<FandomPage> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim();
    final list = [
      for (final f in kFandoms)
        if (!widget.exclude.contains(f) &&
            f.toLowerCase().contains(q.toLowerCase()))
          f
    ];
    final exact = kFandoms.any((f) => f.toLowerCase() == q.toLowerCase());
    return Scaffold(
      appBar: wAppBar(context,
          title: widget.title, actions: [const InfoIcon(), const SizedBox(width: 4)]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              cursorColor: C.iosBlue,
              style: const TextStyle(fontSize: 17),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Cari atau tambahkan sendiri',
                hintStyle:
                    const TextStyle(color: Color(0xFF8E8E8E), fontSize: 17),
                prefixIcon: const Icon(Icons.search, size: 24),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        const BorderSide(color: Color(0xFF8E8E8E), width: 1.2)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.white, width: 1.2)),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.only(bottom: 20), children: [
            if (q.isNotEmpty && !exact)
              InkWell(
                onTap: () => Navigator.pop(context, q),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text('Tambahkan "$q"',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: C.orange)),
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text('Fandom Wattpret (A-Z)',
                  style: TextStyle(fontSize: 16, color: C.grey)),
            ),
            for (final f in list)
              InkWell(
                onTap: () => Navigator.pop(context, f),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(f,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}


// ===========================================================================
// Data pilihan sesuai aplikasi asli
// ===========================================================================
class KOpt {
  final String name, desc;
  const KOpt(this.name, [this.desc = '']);
}

const kPoetryCategories = [
  KOpt('Epos',
      'Puisi bernarasi panjang, biasanya menceritakan tentang kepahlawanan (seperti The Illiad atau Odyssey)'),
  KOpt('Haiku',
      'Puisi asal Jepang yang terdiri dari tiga baris dengan pola suku kata 5–7–5, berjumlah total tujuh belas suku kata.'),
  KOpt('Kumpulan Puisi',
      'Kumpulan lebih dari satu puisi yang biasanya mengangkat satu tema tertentu.'),
  KOpt('Limerick',
      'Puisi yang biasanya bersifat jenaka dengan pola rima AABBA, di mana baris pertama, kedua, dan kelima (A) lebih panjang, sementara baris ketiga dan keempat (B) lebih pendek.'),
  KOpt('Lirik / Liris',
      'Puisi yang mengungkapkan emosi atau perasaan, atau teks berupa lirik lagu.'),
  KOpt('Prosa / Narasi',
      'Cerita yang ditulis dalam bait-bait puisi dengan pola tertentu (seperti The Canterbury Tales)'),
  KOpt('Sajak Bebas',
      'Puisi yang tidak terikat pada bentuk, struktur, atau pola rima tertentu.'),
  KOpt('Soneta',
      'Puisi empat belas baris dengan pola rima tertentu, biasanya untuk mengungkapkan perasaan.'),
];

const kNonfictionCategories = [
  KOpt('Autobiografi',
      'Cerita tentang kehidupan penulis yang ditulis oleh penulis itu sendiri.'),
  KOpt('Info Terkini',
      'Komunikasi dari penulis kepada pembacanya yang berisi informasi terbaru, misalnya tentang tanggal rilis atau hiatus.'),
  KOpt('Informasi dan Panduan',
      'Tulisan nonfiksi yang menyediakan informasi atau saran.'),
  KOpt('Jurnal / Buku Harian',
      'Tulisan non-naratif yang merincikan keseharian atau pikiran dan perasaan penulis.'),
  KOpt('Klub Buku',
      'Cerita yang mendiskusikan cerita lain di Wattpret.'),
  KOpt('Lokakarya dan Umpan Balik',
      'Cerita yang bertujuan untuk memberikan umpan balik serta bantuan dalam menulis, menyunting, dan membuat sampul.'),
  KOpt('Penghargaan & Kontes',
      'Cerita yang menjelaskan peraturan dan informasi kontes dan penghargaan.'),
  KOpt('Refleksi',
      'Tulisan non-naratif yang membahas peristiwa atau topik masa lalu dengan menelaah dan mengkaji apa yang terjadi.'),
  KOpt('Rekomendasi',
      'Rekomendasi bacaan, tontonan, atau hal yang bisa didengarkan.'),
  KOpt('Resensi',
      'Cerita yang mengulas dan mengkritik cerita lain di Wattpret.'),
  KOpt('Wawancara',
      'Wawancara dengan penulis yang membahas karya dan kehidupan mereka.'),
];

const kFandomTopics = [
  'Acara TV',
  'Anime dan Manga',
  'Band dan Grup Musik',
  'Buku dan Literatur',
  'Film',
  'K-pop',
  'Musikal dan Teater',
  'Olahraga',
  'Permainan',
  'Tokoh Terkenal',
  'Tokoh Terkenal: Aktor',
  'Tokoh Terkenal: Atlet',
  'Tokoh Terkenal: Musisi',
  'Tokoh Terkenal: Pemengaruh',
  'Webtoon dan Komik',
];

const kFanFormats = [
  KOpt('Alternate Universe (AU)',
      'Karya yang membawa karakter dan menempatkan mereka dalam latar atau situasi yang berbeda dari apa yang ditetapkan dalam cerita aslinya. Cerita-cerita ini sering kali mengeksplorasi skenario "bagaimana jika", yang berbeda dari kanon yang sudah ada.'),
  KOpt('Crossover',
      'Cerita yang menggabungkan tokoh, latar, atau dunia dari beberapa fandom.'),
  KOpt('Karakter Asli (OC)',
      '"Karakter Asli". Menampilkan karakter yang dibuat oleh penulis.'),
  KOpt('One shot',
      'Karya yang hanya terdiri dari satu bab. Bisa panjang atau pendek.'),
  KOpt('Self-Insert / Imagines',
      'Jenis karya ini melibatkan penulis menciptakan tokoh yang merepresentasikan dirinya sendiri dan memasukkannya ke dalam cerita yang sudah ada.'),
  KOpt('Xreader',
      'Reader-insert adalah tokoh yang dirancang untuk membuat pembaca merasa terlibat langsung dalam cerita (misalnya menggunakan Y/N).'),
];

const kRights = [
  KOpt('Hak Cipta Dilindungi Undang-Undang',
      'Kamu tidak mengizinkan karyamu digunakan atau diadaptasi dalam bentuk apa pun tanpa seizinmu.'),
  KOpt('Domain Publik',
      'Lisensi ini mengizinkan siapa saja menggunakan ceritamu untuk tujuan apa pun—mereka dapat dengan bebas mencetak, menjual, atau mengubah ceritamu menjadi film.'),
  KOpt('Atribusi Creative Commons (CC)',
      'Kamu memegang hak atas ceritamu, tetapi mengizinkan hal-hal seperti penerjemahan atau adaptasi dengan kredit kembali kepadamu.'),
  KOpt('(CC) Atribusi-NonKomersial',
      'Lisensi ini mengizinkan orang lain untuk menggubah, mengadaptasi, dan mengembangkan karyamu secara nonkomersial dengan tetap mencantumkan namamu.'),
  KOpt('(CC) Atribusi-NonKomersial-TanpaTurunan',
      'Lisensi ini mengizinkan orang lain untuk membagikan karyamu kepada orang lain selama tidak diubah dan namamu tetap tercantum.'),
  KOpt('(CC) Atribusi-NonKomersial-BerbagiSerupa',
      'Lisensi ini mengizinkan orang lain untuk mengadaptasi dan mengembangkan karyamu secara nonkomersial, dengan syarat namamu tetap tercantum dan ketentuan yang sama juga berlaku pada karya turunan.'),
  KOpt('(CC) Atribusi-BerbagiSerupa',
      'Lisensi ini mengizinkan orang lain untuk mengadaptasi dan mengembangkan karyamu, bahkan untuk tujuan komersial, dengan syarat namamu tetap tercantum dan ketentuan yang sama juga berlaku pada karya turunan.'),
  KOpt('(CC) Atribusi-TanpaTurunan',
      'Lisensi ini mengizinkan orang lain untuk menggunakan kembali karyamu dengan tujuan apa pun, tetapi tidak boleh dimodifikasi dan namamu tetap tercantum.'),
];

// ---------------------------------------------------------------------------
// Halaman pilihan tunggal dengan deskripsi (Kategori puisi / nonfiksi)
// ---------------------------------------------------------------------------
class DescribedOptionPage extends StatelessWidget {
  final String title;
  final List<KOpt> items;
  final String selected;
  const DescribedOptionPage(
      {super.key,
      required this.title,
      required this.items,
      this.selected = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: wAppBar(context,
          title: title, actions: [const InfoIcon(), const SizedBox(width: 4)]),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 28), children: [
        for (final o in items)
          InkWell(
            onTap: () => Navigator.pop(context, o.name),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(o.desc,
                        style: const TextStyle(
                            fontSize: 15, height: 1.3, color: Color(0xFFE6E6E6))),
                  ]),
                ),
                if (o.name == selected)
                  const Padding(
                    padding: EdgeInsets.only(left: 10, top: 2),
                    child: Icon(Icons.check, color: C.orange, size: 22),
                  ),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman kotak centang "Pilih semua yang sesuai" (Topik fandom, Format fanfiksi)
// ---------------------------------------------------------------------------
class CheckListPage extends StatefulWidget {
  final String title;
  final List<KOpt> items;
  final List<String> initial;
  const CheckListPage(
      {super.key,
      required this.title,
      required this.items,
      this.initial = const []});
  @override
  State<CheckListPage> createState() => _CheckListPageState();
}

class _CheckListPageState extends State<CheckListPage> {
  late final Set<String> _sel = {...widget.initial};

  void _done() => Navigator.pop(context, [
        for (final o in widget.items)
          if (_sel.contains(o.name)) o.name
      ]);

  Widget _box(bool on) => Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.only(top: 1),
        decoration: BoxDecoration(
            color: on ? C.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
                color: on ? C.orange : const Color(0xFFBDBDBD), width: 1.6)),
        child: on
            ? const Icon(Icons.check, size: 17, color: Colors.white)
            : null,
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done();
      },
      child: Scaffold(
        appBar: wAppBar(context,
            title: widget.title,
            onLeading: _done,
            actions: [const InfoIcon(), const SizedBox(width: 4)]),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
          const Text('Pilih semua yang sesuai',
              style: TextStyle(fontSize: 17, color: C.grey)),
          const SizedBox(height: 10),
          for (final o in widget.items)
            InkWell(
              onTap: () => setState(() {
                if (!_sel.remove(o.name)) _sel.add(o.name);
              }),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: o.desc.isEmpty ? 11 : 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _box(_sel.contains(o.name)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      if (o.desc.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(o.desc,
                            style: const TextStyle(
                                fontSize: 15,
                                height: 1.3,
                                color: Color(0xFFBDBDBD))),
                      ],
                    ]),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Halaman "Pilih Hak Cipta" (daftar lisensi lengkap + ikon bantuan)
// ---------------------------------------------------------------------------
class RightsPage extends StatelessWidget {
  final String selected;
  const RightsPage({super.key, this.selected = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: wAppBar(context, title: 'Pilih Hak Cipta', actions: [
        IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Pilih lisensi yang sesuai dengan karyamu'))),
            icon: const Icon(Icons.help_outline, size: 26)),
        const SizedBox(width: 4),
      ]),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        for (final o in kRights) ...[
          InkWell(
            onTap: () => Navigator.pop(context, o.name),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.name,
                        style: TextStyle(
                            fontSize: 17,
                            color: o.name == selected ? C.orange : Colors.white)),
                    const SizedBox(height: 4),
                    Text(o.desc,
                        style: const TextStyle(
                            fontSize: 15, height: 1.3, color: Color(0xFFB5B5B5))),
                  ]),
                ),
                if (o.name == selected)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child:
                        Icon(Icons.check_circle_outline, color: C.orange, size: 30),
                  ),
              ]),
            ),
          ),
          const Divider(height: 1, indent: 16, color: Color(0xFF2E2E2E)),
        ],
      ]),
    );
  }
}

// ===========================================================================
// Baris formulir + bagian "Jenis cerita ... Hak Cipta" yang dipakai bersama
// oleh layar "Edit Cerita" (terbit pertama) dan "Edit Cerita" (karya lama).
// ===========================================================================
class StoryFormRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool required;
  final Widget? value, below;
  const StoryFormRow(this.label, this.onTap,
      {super.key, this.required = false, this.value, this.below});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(label, style: const TextStyle(fontSize: 18)),
                  if (required)
                    const Text(' *',
                        style: TextStyle(color: Color(0xFFFF5A3C), fontSize: 18)),
                  if (value != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                        child: Align(alignment: Alignment.centerRight, child: value)),
                  ],
                ]),
                if (below != null)
                  Padding(padding: const EdgeInsets.only(top: 9), child: below),
              ]),
            ),
            const Icon(Icons.chevron_right, size: 26, color: Color(0xFFBDBDBD)),
          ]),
        ),
      ),
      const Divider(height: 1, indent: 16, color: Color(0xFF2E2E2E)),
    ]);
  }
}

Widget storyFormValue(String t) => Text(t,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(fontSize: 17, color: Color(0xFF9A9A9A)));

class StoryTypeFields extends StatelessWidget {
  final Work work;
  final VoidCallback onChanged;
  const StoryTypeFields({super.key, required this.work, required this.onChanged});

  Work get w => work;
  bool get _fic => w.type == 'Fiksi';
  bool get _fan => w.type == 'Fiksi Penggemar';
  bool get _non => w.type == 'Nonfiksi';
  bool get _poem => w.type == 'Puisi';

  Future<T?> _go<T>(BuildContext c, Widget page) =>
      Navigator.of(c, rootNavigator: true)
          .push<T>(MaterialPageRoute(builder: (_) => page));

  Widget _newBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: const Color(0xFFA9CB8B), borderRadius: BorderRadius.circular(6)),
        child: const Text('BARU',
            style: TextStyle(
                color: Color(0xFF1E3A12),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.1)),
      );

  Future<void> _type(BuildContext c) async {
    final r = await _go<String>(c, OptionPage(
        title: 'Jenis cerita',
        options: kStoryTypes,
        selected: w.type,
        intro: kStoryTypeIntro));
    if (r != null && r.isNotEmpty && r != w.type) {
      w.type = r;
      w.genres.clear();
      w.fandoms.clear();
      w.fandomClass = null;
      w.category = null;
      w.fandomTopics.clear();
      w.fanFormats.clear();
      onChanged();
    }
  }

  Future<void> _category(BuildContext c, String title, List<KOpt> items) async {
    final r = await _go<String>(c,
        DescribedOptionPage(title: title, items: items, selected: w.category ?? ''));
    if (r != null && r.isNotEmpty) {
      w.category = r;
      onChanged();
    }
  }

  Future<void> _genre(BuildContext c, int i) async {
    final others = [
      for (var k = 0; k < w.genres.length; k++)
        if (k != i) w.genres[k]
    ];
    final r = await _go<String>(c, OptionPage(
        title: 'Genre #${i + 1}',
        sectionLabel: (_fan && i == 0) ? 'Genre #1 (opsional)' : 'Genre #${i + 1}',
        options: [
          for (final g in kFictionGenres)
            if (!others.contains(g)) g
        ],
        selected: i < w.genres.length ? w.genres[i] : '',
        clearable: i > 0 || _fan));
    if (r == null) return;
    if (r.isEmpty) {
      if (i < w.genres.length) w.genres.removeAt(i);
    } else if (i < w.genres.length) {
      w.genres[i] = r;
    } else {
      w.genres.add(r);
    }
    onChanged();
  }

  Future<void> _fandom(BuildContext c, int i) async {
    final others = [
      for (var k = 0; k < w.fandoms.length; k++)
        if (k != i) w.fandoms[k]
    ];
    final r = await _go<String>(
        c, FandomPage(title: 'Fandom #${i + 1}', exclude: others));
    if (r == null || r.isEmpty) return;
    if (i < w.fandoms.length) {
      w.fandoms[i] = r;
    } else {
      w.fandoms.add(r);
    }
    onChanged();
  }

  Future<void> _topics(BuildContext c) async {
    final r = await _go<List<String>>(c, CheckListPage(
        title: 'Topik fandom',
        items: [for (final t in kFandomTopics) KOpt(t)],
        initial: w.fandomTopics));
    if (r != null) {
      w.fandomTopics = r;
      onChanged();
    }
  }

  Future<void> _formats(BuildContext c) async {
    final r = await _go<List<String>>(c, CheckListPage(
        title: 'Format fanfiksi', items: kFanFormats, initial: w.fanFormats));
    if (r != null) {
      w.fanFormats = r;
      onChanged();
    }
  }

  Future<void> _tags(BuildContext c) async {
    final r = await _go<List<String>>(c, TagsPage(initial: w.tags));
    if (r != null) {
      w.tags = r;
      onChanged();
    }
  }

  Future<void> _rights(BuildContext c) async {
    final r = await _go<String>(c, RightsPage(selected: w.rights));
    if (r != null && r.isNotEmpty) {
      w.rights = r;
      onChanged();
    }
  }

  Widget _tagChips() => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in w.tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8)),
            child: Text(t, style: const TextStyle(fontSize: 16)),
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    final typeChosen = w.type.isNotEmpty;
    String g(int i) => i < w.genres.length ? w.genres[i] : '';
    String f(int i) => i < w.fandoms.length ? w.fandoms[i] : '';
    return Column(children: [
      StoryFormRow('Jenis cerita', () => _type(context),
          required: true,
          value: typeChosen ? storyFormValue(w.type) : _newBadge()),
      if (_poem)
        StoryFormRow('Kategori puisi',
            () => _category(context, 'Kategori puisi', kPoetryCategories),
            value: storyFormValue(w.category ?? '')),
      if (_non)
        StoryFormRow('Kategori nonfiksi',
            () => _category(context, 'Kategori nonfiksi', kNonfictionCategories),
            value: storyFormValue(w.category ?? '')),
      if (_fan) ...[
        StoryFormRow('Fandom #1', () => _fandom(context, 0),
            required: true, value: storyFormValue(f(0))),
        StoryFormRow('Fandom #2', () => _fandom(context, 1),
            value: storyFormValue(f(1))),
        StoryFormRow('Fandom #3', () => _fandom(context, 2),
            value: storyFormValue(f(2))),
        StoryFormRow('Topik fandom', () => _topics(context),
            value: storyFormValue(w.fandomTopics.join(', '))),
        StoryFormRow('Format fanfiksi', () => _formats(context),
            value: storyFormValue(w.fanFormats.join(', '))),
      ],
      if (_fic || _fan) ...[
        StoryFormRow('Genre #1', () => _genre(context, 0),
            required: _fic, value: storyFormValue(g(0))),
        StoryFormRow('Genre #2', () => _genre(context, 1),
            value: storyFormValue(g(1))),
        StoryFormRow('Genre #3', () => _genre(context, 2),
            value: storyFormValue(g(2))),
      ],
      StoryFormRow('Tag', () => _tags(context),
          required: true, below: w.tags.isEmpty ? null : _tagChips()),
      StoryFormRow('Hak Cipta', () => _rights(context),
          value: storyFormValue(w.rights)),
    ]);
  }
}
