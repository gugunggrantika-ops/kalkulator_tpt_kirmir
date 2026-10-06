import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const KalkulatorTptApp());
}

// ============================================================
// DATA ANALISA
// ============================================================

class KomponenAnalisa {
  String nama;
  double koef;
  String satuan;
  double harga;

  KomponenAnalisa({
    required this.nama,
    required this.koef,
    required this.satuan,
    this.harga = 0,
  });

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'koef': koef,
        'satuan': satuan,
        'harga': harga,
      };

  factory KomponenAnalisa.fromJson(Map<String, dynamic> json) {
    return KomponenAnalisa(
      nama: json['nama'] ?? '',
      koef: (json['koef'] ?? 0).toDouble(),
      satuan: json['satuan'] ?? '',
      harga: (json['harga'] ?? 0).toDouble(),
    );
  }
}

class AnalisaPekerjaan {
  String nama;
  String satuanVolume;
  List<KomponenAnalisa> komponen;

  AnalisaPekerjaan({
    required this.nama,
    required this.satuanVolume,
    required this.komponen,
  });

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'satuanVolume': satuanVolume,
        'komponen': komponen.map((e) => e.toJson()).toList(),
      };

  factory AnalisaPekerjaan.fromJson(Map<String, dynamic> json) {
    return AnalisaPekerjaan(
      nama: json['nama'] ?? '',
      satuanVolume: json['satuanVolume'] ?? '',
      komponen: (json['komponen'] as List)
          .map(
            (e) => KomponenAnalisa.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

// ============================================================
// DATA DIMENSI
// ============================================================

class Dimensi {
  double panjang;
  double lebarAtas;
  double lebarBawah;
  double tinggi;

  Dimensi({
    this.panjang = 0,
    this.lebarAtas = 0,
    this.lebarBawah = 0,
    this.tinggi = 0,
  });
}

// ============================================================
// HASIL
// ============================================================

class HasilVolume {
  double bouwplank = 0;
  double galian = 0;
  double urugan = 0;
  double pondasi = 0;
  double badan = 0;
  double pasangan = 0;
  double plesteran = 0;
  double acian = 0;
  double siaran = 0;
}

// ============================================================
// APP
// ============================================================

class KalkulatorTptApp extends StatelessWidget {
  const KalkulatorTptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kalkulator TPT / Kirmir',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
      ),
      home: const MainShell(),
    );
  }
}

// ============================================================
// MAIN SHELL
// ============================================================

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int halaman = 0;

  final panjangType1 = TextEditingController(text: '20');
  final panjangType2 = TextEditingController(text: '0');

  // Galian
  final galian1Atas = TextEditingController(text: '0.40');
  final galian1Bawah = TextEditingController(text: '0.40');
  final galian1Tinggi = TextEditingController(text: '0.40');

  final galian2Atas = TextEditingController(text: '0.50');
  final galian2Bawah = TextEditingController(text: '0.50');
  final galian2Tinggi = TextEditingController(text: '0.40');

  // Urugan
  final urugan1Lebar = TextEditingController(text: '0.40');
  final urugan1Tebal = TextEditingController(text: '0.05');

  final urugan2Lebar = TextEditingController(text: '0.50');
  final urugan2Tebal = TextEditingController(text: '0.05');

  // Pondasi
  final pondasi1Atas = TextEditingController(text: '0.40');
  final pondasi1Bawah = TextEditingController(text: '0.40');
  final pondasi1Tinggi = TextEditingController(text: '0.40');

  final pondasi2Atas = TextEditingController(text: '0.50');
  final pondasi2Bawah = TextEditingController(text: '0.50');
  final pondasi2Tinggi = TextEditingController(text: '0.40');

  // Badan Type 1
  final badan1Atas = TextEditingController(text: '0');
  final badan1Bawah = TextEditingController(text: '0');
  final badan1Tinggi = TextEditingController(text: '0');

  // Badan Type 2 Segmen A
  final badan2AAtas = TextEditingController(text: '0.30');
  final badan2ABawah = TextEditingController(text: '0.40');
  final badan2ATinggi = TextEditingController(text: '1.00');

  // Badan Type 2 Segmen B
  final badan2BAtas = TextEditingController(text: '0.50');
  final badan2BBawah = TextEditingController(text: '0.30');
  final badan2BTinggi = TextEditingController(text: '1.50');

  // Plester
  final plester1Lebar = TextEditingController(text: '0.35');
  final plester2Lebar = TextEditingController(text: '0.35');

  // Siaran
  final siaran1Lebar = TextEditingController(text: '1.00');
  final siaran2Lebar = TextEditingController(text: '1.50');

  HasilVolume hasil = HasilVolume();

  List<AnalisaPekerjaan> analisa = [];

  @override
  void initState() {
    super.initState();
    muatData();
  }

  double angka(TextEditingController c) {
    return double.tryParse(
          c.text.replaceAll(',', '.').trim(),
        ) ??
        0;
  }

  double volumeTrapesium(
    double panjang,
    double atas,
    double bawah,
    double tinggi,
  ) {
    return panjang * ((atas + bawah) / 2) * tinggi;
  }

  double volumePersegi(
    double panjang,
    double lebar,
    double tinggi,
  ) {
    return panjang * lebar * tinggi;
  }

  // ==========================================================
  // HARGA DEFAULT SK KADES 2027
  // Sumber: sheet "SK KADES 2027" kolom "Harga SK Kades"
  // dan sheet "SK KADES UPAH" pada file Excel pengguna.
  // ==========================================================

  double hargaDefault(String nama) {
    const hargaMaterial = <String, double>{
      'Batu belah 15/20': 270000,
      'Pasir pasang': 366000,
      // Sirtu / pasir batu pada Excel SK Kades 2027 = Rp 193.000/m3.
      // Di analisa pekerjaan aplikasi material ini bernama 'Pasir urug'.
      'Pasir urug': 193000,
      'Sirtu': 193000,
      'Pasir batu': 193000,
      'Sirtu / pasir batu': 193000,
      'Portland cement @ 50 kg': 78000,
      'Kaso 5/7 cm': 3070000,
      'Kaso 5/7 Kayu kelas II': 3070000,
      'Papan 2/20': 2935000,
      'Papan Albasiah': 2935000,
      'Paku': 24000,
      'Paku 4 cm sd 7 cm': 24000,
    };

    const hargaUpah = <String, double>{
      'Pekerja': 100000,
      'Tukang': 120000,
      'Tukang batu': 120000,
      'Tukang kayu': 120000,
      'Kepala tukang': 125000,
      'Kep. tukang': 125000,
      'Mandor': 130000,
    };

    if (hargaMaterial.containsKey(nama)) return hargaMaterial[nama]!;
    if (hargaUpah.containsKey(nama)) return hargaUpah[nama]!;
    return 0;
  }

  // ==========================================================
  // ANALISA DEFAULT
  // ==========================================================

  List<AnalisaPekerjaan> analisaDefault() {
    return [
      AnalisaPekerjaan(
        nama: 'Profil melintang galian',
        satuanVolume: 'm',
        komponen: [
          KomponenAnalisa(
            nama: 'Kaso 5/7 cm',
            koef: 0.0025,
            satuan: 'm3',
          ),
          KomponenAnalisa(
            nama: 'Papan 2/20',
            koef: 0.0042,
            satuan: 'm3',
          ),
          KomponenAnalisa(
            nama: 'Paku',
            koef: 0.2,
            satuan: 'kg',
          ),
          KomponenAnalisa(
            nama: 'Pekerja',
            koef: 0.06,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Tukang kayu',
            koef: 0.02,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Mandor',
            koef: 0.006,
            satuan: 'OH',
          ),
        ],
      ),

      AnalisaPekerjaan(
        nama: 'Galian tanah ≤ 1 m',
        satuanVolume: 'm3',
        komponen: [
          KomponenAnalisa(
            nama: 'Pekerja',
            koef: 0.563,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Mandor',
            koef: 0.0563,
            satuan: 'OH',
          ),
        ],
      ),

      AnalisaPekerjaan(
        nama: 'Urugan pasir',
        satuanVolume: 'm3',
        komponen: [
          KomponenAnalisa(
            nama: 'Pasir urug',
            koef: 1.2,
            satuan: 'm3',
          ),
          KomponenAnalisa(
            nama: 'Pekerja',
            koef: 0.3,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Mandor',
            koef: 0.01,
            satuan: 'OH',
          ),
        ],
      ),

      AnalisaPekerjaan(
        nama: 'Pasangan batu mortar Tipe O',
        satuanVolume: 'm3',
        komponen: [
          KomponenAnalisa(
            nama: 'Batu belah 15/20',
            koef: 1.2,
            satuan: 'm3',
          ),
          KomponenAnalisa(
            nama: 'Pasir pasang',
            koef: 0.544,
            satuan: 'm3',
          ),
          KomponenAnalisa(
            nama: 'Portland cement @ 50 kg',
            koef: 135 / 50,
            satuan: 'zak',
          ),
          KomponenAnalisa(
            nama: 'Pekerja',
            koef: 2.7,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Tukang batu',
            koef: 0.9,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Mandor',
            koef: 0.27,
            satuan: 'OH',
          ),
        ],
      ),

      AnalisaPekerjaan(
        nama: 'Plesteran mortar Tipe S',
        satuanVolume: 'm2',
        komponen: [
          KomponenAnalisa(
            nama: 'Pasir pasang',
            koef: 0.03,
            satuan: 'm3',
          ),
          KomponenAnalisa(
            nama: 'Portland cement @ 50 kg',
            koef: 7.776 / 50,
            satuan: 'zak',
          ),
          KomponenAnalisa(
            nama: 'Pekerja',
            koef: 0.384,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Tukang batu',
            koef: 0.192,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Kepala tukang',
            koef: 0.019,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Mandor',
            koef: 0.019,
            satuan: 'OH',
          ),
        ],
      ),

      AnalisaPekerjaan(
        nama: 'Acian',
        satuanVolume: 'm2',
        komponen: [
          KomponenAnalisa(
            nama: 'Portland cement @ 50 kg',
            koef: 3.25 / 50,
            satuan: 'kg',
          ),
          KomponenAnalisa(
            nama: 'Pekerja',
            koef: 0.2,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Tukang batu',
            koef: 0.1,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Kepala tukang',
            koef: 0.01,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Mandor',
            koef: 0.02,
            satuan: 'OH',
          ),
        ],
      ),

      AnalisaPekerjaan(
        nama: 'Siaran mortar Tipe S',
        satuanVolume: 'm2',
        komponen: [
          KomponenAnalisa(
            nama: 'Pasir pasang',
            koef: 0.018,
            satuan: 'm3',
          ),
          KomponenAnalisa(
            nama: 'Portland cement @ 50 kg',
            koef: 4.84 / 50,
            satuan: 'kg',
          ),
          KomponenAnalisa(
            nama: 'Pekerja',
            koef: 0.3,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Tukang batu',
            koef: 0.15,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Kepala tukang',
            koef: 0.015,
            satuan: 'OH',
          ),
          KomponenAnalisa(
            nama: 'Mandor',
            koef: 0.03,
            satuan: 'OH',
          ),
        ],
      ),
    ];
  }

  // ==========================================================
  // SIMPAN / MUAT
  // ==========================================================

  Future<void> muatData() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString('analisa_tpt');

    if (data == null) {
      analisa = analisaDefault();
    } else {
      final List decoded = jsonDecode(data);

      analisa = decoded
          .map(
            (e) => AnalisaPekerjaan.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }

    // Isi harga default hanya jika harga sebelumnya masih 0.
    // Harga yang sudah diedit pengguna tidak ditimpa.
    for (final pekerjaan in analisa) {
      for (final item in pekerjaan.komponen) {
        if (item.harga <= 0) {
          item.harga = hargaDefault(item.nama);
        }
      }
    }

    await prefs.setString(
      'analisa_tpt',
      jsonEncode(analisa.map((e) => e.toJson()).toList()),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> simpanAnalisa() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'analisa_tpt',
      jsonEncode(
        analisa.map((e) => e.toJson()).toList(),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analisa dan koefisien berhasil disimpan'),
        ),
      );
    }
  }

  // ==========================================================
  // HITUNG VOLUME
  // ==========================================================

  void hitungVolume() {
    final p1 = angka(panjangType1);
    final p2 = angka(panjangType2);

    // Bouwplank sesuai pola workbook
    hasil.bouwplank =
        ((p1 / 5) + 1) +
        ((p2 / 7) + 1);

    // Galian
    final galianType1 = volumeTrapesium(
      p1,
      angka(galian1Atas),
      angka(galian1Bawah),
      angka(galian1Tinggi),
    );

    final galianType2 = volumeTrapesium(
      p2,
      angka(galian2Atas),
      angka(galian2Bawah),
      angka(galian2Tinggi),
    );

    hasil.galian = galianType1 + galianType2;

    // Urugan
    final uruganType1 = volumePersegi(
      p1,
      angka(urugan1Lebar),
      angka(urugan1Tebal),
    );

    final uruganType2 = volumePersegi(
      p2,
      angka(urugan2Lebar),
      angka(urugan2Tebal),
    );

    hasil.urugan = uruganType1 + uruganType2;

    // Pondasi
    final pondasiType1 = volumeTrapesium(
      p1,
      angka(pondasi1Atas),
      angka(pondasi1Bawah),
      angka(pondasi1Tinggi),
    );

    final pondasiType2 = volumeTrapesium(
      p2,
      angka(pondasi2Atas),
      angka(pondasi2Bawah),
      angka(pondasi2Tinggi),
    );

    hasil.pondasi = pondasiType1 + pondasiType2;

    // Badan Type 1
    final badanType1 = volumeTrapesium(
      p1,
      angka(badan1Atas),
      angka(badan1Bawah),
      angka(badan1Tinggi),
    );

    // Badan Type 2 terdiri dari dua segmen
    final badanType2A = volumeTrapesium(
      p2,
      angka(badan2AAtas),
      angka(badan2ABawah),
      angka(badan2ATinggi),
    );

    final badanType2B = volumeTrapesium(
      p2,
      angka(badan2BAtas),
      angka(badan2BBawah),
      angka(badan2BTinggi),
    );

    hasil.badan =
        badanType1 +
        badanType2A +
        badanType2B;

    hasil.pasangan =
        hasil.pondasi +
        hasil.badan;

    // Plesteran
    hasil.plesteran =
        (p1 * angka(plester1Lebar)) +
        (p2 * angka(plester2Lebar));

    // Acian mengikuti luas plesteran
    hasil.acian = hasil.plesteran;

    // Siaran
    hasil.siaran =
        (p1 * angka(siaran1Lebar)) +
        (p2 * angka(siaran2Lebar));

    setState(() {});
  }

  // ==========================================================
  // FIELD
  // ==========================================================

  Widget field(
    String label,
    TextEditingController controller, {
    String suffix = 'm',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget section(
    String title,
    List<Widget> children, {
    IconData icon = Icons.straighten,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }

  // ==========================================================
  // HALAMAN PERHITUNGAN
  // ==========================================================

  Widget halamanHitung() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: const [
                Icon(
                  Icons.construction,
                  size: 50,
                ),
                SizedBox(height: 8),
                Text(
                  'KALKULATOR TPT / KIRMIR',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Perhitungan volume Type 1 dan Type 2',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        section(
          'Panjang TPT',
          [
            field(
              'Panjang Type 1',
              panjangType1,
            ),
            field(
              'Panjang Type 2',
              panjangType2,
            ),
          ],
          icon: Icons.straighten,
        ),

        section(
          'Galian Type 1',
          [
            field('Lebar atas', galian1Atas),
            field('Lebar bawah', galian1Bawah),
            field('Kedalaman', galian1Tinggi),
          ],
          icon: Icons.landscape,
        ),

        section(
          'Galian Type 2',
          [
            field('Lebar atas', galian2Atas),
            field('Lebar bawah', galian2Bawah),
            field('Kedalaman', galian2Tinggi),
          ],
          icon: Icons.landscape,
        ),

        section(
          'Urugan Type 1',
          [
            field('Lebar', urugan1Lebar),
            field('Tebal', urugan1Tebal),
          ],
          icon: Icons.layers,
        ),

        section(
          'Urugan Type 2',
          [
            field('Lebar', urugan2Lebar),
            field('Tebal', urugan2Tebal),
          ],
          icon: Icons.layers,
        ),

        section(
          'Pondasi Type 1',
          [
            field('Lebar atas', pondasi1Atas),
            field('Lebar bawah', pondasi1Bawah),
            field('Tinggi', pondasi1Tinggi),
          ],
          icon: Icons.foundation,
        ),

        section(
          'Pondasi Type 2',
          [
            field('Lebar atas', pondasi2Atas),
            field('Lebar bawah', pondasi2Bawah),
            field('Tinggi', pondasi2Tinggi),
          ],
          icon: Icons.foundation,
        ),

        section(
          'Badan Kirmir Type 1',
          [
            field('Tebal atas', badan1Atas),
            field('Tebal bawah', badan1Bawah),
            field('Tinggi', badan1Tinggi),
          ],
          icon: Icons.domain,
        ),

        section(
          'Badan Kirmir Type 2 - Segmen A',
          [
            field('Tebal atas', badan2AAtas),
            field('Tebal bawah', badan2ABawah),
            field('Tinggi', badan2ATinggi),
          ],
          icon: Icons.domain,
        ),

        section(
          'Badan Kirmir Type 2 - Segmen B',
          [
            field('Tebal atas', badan2BAtas),
            field('Tebal bawah', badan2BBawah),
            field('Tinggi', badan2BTinggi),
          ],
          icon: Icons.domain,
        ),

        section(
          'Plesteran',
          [
            field('Lebar / tinggi Type 1', plester1Lebar),
            field('Lebar / tinggi Type 2', plester2Lebar),
          ],
          icon: Icons.format_paint,
        ),

        section(
          'Siaran',
          [
            field('Lebar Type 1', siaran1Lebar),
            field('Lebar Type 2', siaran2Lebar),
          ],
          icon: Icons.grid_on,
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 55,
          child: FilledButton.icon(
            onPressed: hitungVolume,
            icon: const Icon(Icons.calculate),
            label: const Text(
              'HITUNG VOLUME',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // RAB
  // ==========================================================

  double volumePekerjaan(AnalisaPekerjaan pekerjaan) {
    // Beberapa data lama di HP tersimpan dengan karakter '≤' yang rusak
    // menjadi teks seperti 'â‰¤'. Karena itu Galian dikenali berdasarkan
    // awal nama pekerjaan, bukan kecocokan karakter '≤' secara persis.
    final nama = pekerjaan.nama.trim().toLowerCase();

    if (nama == 'profil melintang galian') {
      return hasil.bouwplank;
    }

    if (nama.startsWith('galian tanah')) {
      return hasil.galian;
    }

    if (nama == 'urugan pasir') {
      return hasil.urugan;
    }

    if (nama == 'pasangan batu mortar tipe o') {
      return hasil.pasangan;
    }

    if (nama == 'plesteran mortar tipe s') {
      return hasil.plesteran;
    }

    if (nama == 'acian') {
      return hasil.acian;
    }

    if (nama == 'siaran mortar tipe s') {
      return hasil.siaran;
    }

    return 0;
  }

  double subtotalPekerjaan(AnalisaPekerjaan pekerjaan) {
    final volume = volumePekerjaan(pekerjaan);
    return pekerjaan.komponen.fold<double>(
      0,
      (total, item) => total + (volume * item.koef * item.harga),
    );
  }

  double totalRab() {
    return analisa.fold<double>(
      0,
      (total, pekerjaan) => total + subtotalPekerjaan(pekerjaan),
    );
  }

  String rupiah(double nilai) {
    final angka = nilai.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < angka.length; i++) {
      if (i > 0 && (angka.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(angka[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  Widget rabPekerjaanCard(AnalisaPekerjaan pekerjaan) {
    final volume = volumePekerjaan(pekerjaan);
    final subtotal = subtotalPekerjaan(pekerjaan);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.receipt_long),
        title: Text(
          pekerjaan.nama,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Volume: ${volume.toStringAsFixed(3)} ${pekerjaan.satuanVolume}  •  ${rupiah(subtotal)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                ...pekerjaan.komponen.map(
                  (item) {
                    final kebutuhan = volume * item.koef;
                    final biaya = kebutuhan * item.harga;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nama,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Koef: ${item.koef.toStringAsFixed(4)} ${item.satuan}',
                          ),
                          Text(
                            'Kebutuhan: ${kebutuhan.toStringAsFixed(3)} ${item.satuan}',
                          ),
                          Text(
                            'Harga: ${rupiah(item.harga)} / ${item.satuan}',
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Biaya: ${rupiah(biaya)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SUBTOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      rupiah(subtotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget halamanRab() {
    final total = totalRab();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Icon(Icons.account_balance_wallet, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'RENCANA ANGGARAN BIAYA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Volume × koefisien × harga material/upah',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TOTAL RAB',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        rupiah(total),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (hasil.pasangan == 0 &&
            hasil.galian == 0 &&
            hasil.urugan == 0 &&
            hasil.plesteran == 0 &&
            hasil.acian == 0 &&
            hasil.siaran == 0)
          Card(
            color: Colors.amber.shade50,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Belum ada volume yang dihitung. Masuk ke menu Hitung, isi dimensi, lalu tekan HITUNG VOLUME terlebih dahulu.',
              ),
            ),
          ),

        ...analisa.map(rabPekerjaanCard),

        const SizedBox(height: 10),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CATATAN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Harga material dan upah mengikuti data pada menu Pengaturan. Jika harga atau koefisien diubah, kembali ke halaman RAB untuk melihat hasil terbaru.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // HASIL
  // ==========================================================

  Widget hasilItem(
    String nama,
    double nilai,
    String satuan,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calculate),
        title: Text(nama),
        trailing: Text(
          '${nilai.toStringAsFixed(3)} $satuan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget halamanHasil() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'HASIL VOLUME',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        hasilItem(
          'Profil melintang / Bouwplank',
          hasil.bouwplank,
          'm',
        ),

        hasilItem(
          'Galian tanah ≤ 1 m',
          hasil.galian,
          'm³',
        ),

        hasilItem(
          'Urugan pasir',
          hasil.urugan,
          'm³',
        ),

        hasilItem(
          'Pondasi pasangan batu',
          hasil.pondasi,
          'm³',
        ),

        hasilItem(
          'Badan kirmir',
          hasil.badan,
          'm³',
        ),

        hasilItem(
          'Total pasangan batu',
          hasil.pasangan,
          'm³',
        ),

        hasilItem(
          'Plesteran',
          hasil.plesteran,
          'm²',
        ),

        hasilItem(
          'Acian',
          hasil.acian,
          'm²',
        ),

        hasilItem(
          'Siaran',
          hasil.siaran,
          'm²',
        ),
      ],
    );
  }

  // ==========================================================
  // PENGATURAN
  // ==========================================================

  Widget halamanPengaturan() {
    return PengaturanPage(
      analisa: analisa,
      onSave: () async {
        await simpanAnalisa();
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      halamanHitung(),
      halamanHasil(),
      halamanRab(),
      halamanPengaturan(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          halaman == 0
              ? 'Perhitungan TPT / Kirmir'
              : halaman == 1
                  ? 'Hasil Perhitungan'
                  : halaman == 2
                      ? 'RAB'
                      : 'Pengaturan',
        ),
        centerTitle: true,
      ),
      body: pages[halaman],
      bottomNavigationBar: NavigationBar(
        selectedIndex: halaman,
        onDestinationSelected: (index) {
          setState(() {
            halaman = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.construction),
            label: 'Hitung',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Hasil',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'RAB',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PENGATURAN
// ============================================================

class PengaturanPage extends StatefulWidget {
  final List<AnalisaPekerjaan> analisa;
  final Future<void> Function() onSave;

  const PengaturanPage({
    super.key,
    required this.analisa,
    required this.onSave,
  });

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  final Map<String, TextEditingController> hargaController = {};

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 2,
      vsync: this,
    );

    for (final pekerjaan in widget.analisa) {
      for (final item in pekerjaan.komponen) {
        hargaController[
          '${pekerjaan.nama}|${item.nama}'
        ] = TextEditingController(
          text: item.harga == 0
              ? ''
              : item.harga.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    tabController.dispose();

    for (final c in hargaController.values) {
      c.dispose();
    }

    super.dispose();
  }

  Widget angkaField(
    String label,
    double nilai,
    ValueChanged<double> onChanged,
  ) {
    final controller = TextEditingController(
      text: nilai.toString(),
    );

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        final angka = double.tryParse(
              value.replaceAll(',', '.'),
            ) ??
            0;

        onChanged(angka);
      },
    );
  }

  Widget tabKoefisien() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'ANALISA & KOEFISIEN',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Koefisien dapat diubah sesuai analisa yang digunakan.',
        ),

        const SizedBox(height: 12),

        ...widget.analisa.map(
          (pekerjaan) => Card(
            child: ExpansionTile(
              title: Text(
                pekerjaan.nama,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Satuan: ${pekerjaan.satuanVolume}',
              ),
              children: [
                ...pekerjaan.komponen.map(
                  (item) => Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(item.nama),
                        ),
                        SizedBox(
                          width: 105,
                          child: TextFormField(
                            initialValue:
                                item.koef.toString(),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration:
                                const InputDecoration(
                              labelText: 'Koef',
                              border:
                                  OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              item.koef =
                                  double.tryParse(
                                        value.replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      ) ??
                                      0;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 45,
                          child: Text(
                            item.satuan,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        FilledButton.icon(
          onPressed: widget.onSave,
          icon: const Icon(Icons.save),
          label: const Text('SIMPAN KOEFISIEN'),
        ),
      ],
    );
  }

  Widget tabHarga() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'HARGA MATERIAL & UPAH',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Masukkan harga terbaru. Harga tersimpan di HP.',
        ),

        const SizedBox(height: 12),

        ...widget.analisa.map(
          (pekerjaan) => Card(
            child: ExpansionTile(
              title: Text(
                pekerjaan.nama,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                ...pekerjaan.komponen.map(
                  (item) {
                    final key =
                        '${pekerjaan.nama}|${item.nama}';

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        8,
                      ),
                      child: TextField(
                        controller: hargaController[key],
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              '${item.nama} (${item.satuan})',
                          prefixText: 'Rp ',
                          border:
                              const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          item.harga =
                              double.tryParse(
                                    value
                                        .replaceAll('.', '')
                                        .replaceAll(',', '.'),
                                  ) ??
                                  0;
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        FilledButton.icon(
          onPressed: widget.onSave,
          icon: const Icon(Icons.save),
          label: const Text('SIMPAN HARGA'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.tune),
              text: 'Koefisien',
            ),
            Tab(
              icon: Icon(Icons.payments),
              text: 'Harga',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              tabKoefisien(),
              tabHarga(),
            ],
          ),
        ),
      ],
    );
  }
}
