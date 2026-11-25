import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class LearningLesson {
  final String title;
  final String body;

  const LearningLesson(this.title, this.body);
}

class LearningQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const LearningQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class LearningModule {
  final String id;
  final String title;
  final String summary;
  final IconData icon;
  final List<LearningLesson> lessons;
  final List<LearningQuestion> questions;

  const LearningModule({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.lessons,
    required this.questions,
  });
}

const learningModules = <LearningModule>[
  LearningModule(
    id: 'crypto-basics',
    title: 'Mengenal aset kripto',
    summary: 'Kenali aset digital, coin, token, dan perubahan harga.',
    icon: Icons.currency_bitcoin,
    lessons: [
      LearningLesson(
        'Apa itu aset kripto?',
        'Aset kripto adalah aset digital yang kepemilikan dan transaksinya '
            'dicatat menggunakan teknologi kriptografi dan jaringan komputer. '
            'Nilainya dapat naik maupun turun tajam.',
      ),
      LearningLesson(
        'Coin dan token',
        'Coin berjalan di blockchain-nya sendiri, seperti BTC di Bitcoin. '
            'Token dibuat di atas blockchain yang sudah ada. Keduanya tetap '
            'memiliki risiko dan tidak menjamin keuntungan.',
      ),
    ],
    questions: [
      LearningQuestion(
        question: 'Pernyataan mana yang tepat tentang harga aset kripto?',
        options: [
          'Harganya selalu naik dalam jangka panjang.',
          'Harganya bisa naik atau turun dan tidak ada keuntungan yang dijamin.',
          'Nilainya dijamin oleh bank.',
        ],
        correctIndex: 1,
        explanation: 'Harga kripto berfluktuasi. Kenaikan sebelumnya bukan '
            'jaminan bahwa harga akan naik lagi.',
      ),
      LearningQuestion(
        question: 'Apa perbedaan umum coin dan token?',
        options: [
          'Coin memiliki blockchain sendiri; token menggunakan blockchain yang ada.',
          'Token selalu lebih aman daripada coin.',
          'Tidak ada perbedaan sama sekali.',
        ],
        correctIndex: 0,
        explanation:
            'Coin biasanya merupakan aset native blockchain, sedangkan '
            'token diterbitkan menggunakan blockchain yang sudah ada.',
      ),
    ],
  ),
  LearningModule(
    id: 'blockchain-basics',
    title: 'Memahami blockchain',
    summary:
        'Pelajari catatan bersama, konfirmasi transaksi, dan biaya jaringan.',
    icon: Icons.link,
    lessons: [
      LearningLesson(
        'Catatan bersama',
        'Blockchain adalah catatan transaksi yang disalin dan diperiksa oleh '
            'banyak komputer dalam jaringan. Aturan untuk menambahkan catatan '
            'bergantung pada blockchain tersebut.',
      ),
      LearningLesson(
        'Konfirmasi dan biaya',
        'Transaksi perlu diproses oleh jaringan. Beberapa jaringan mengenakan '
            'biaya transaksi, yang sering disebut biaya jaringan atau gas fee. '
            'Biaya dan waktu proses dapat berubah.',
      ),
    ],
    questions: [
      LearningQuestion(
        question: 'Apa yang sebaiknya dilakukan sebelum mengirim aset?',
        options: [
          'Memastikan alamat dan jaringan tujuan cocok.',
          'Mengirim dulu agar biaya tidak berubah.',
          'Mengirim seed phrase kepada penerima.',
        ],
        correctIndex: 0,
        explanation:
            'Alamat atau jaringan yang keliru dapat membuat aset tidak '
            'sampai atau sulit dipulihkan. Periksa detail transaksi sebelum '
            'mengonfirmasi.',
      ),
      LearningQuestion(
        question: 'Apa yang dapat terjadi pada biaya transaksi?',
        options: [
          'Selalu gratis.',
          'Dapat berubah sesuai jaringan dan kondisi penggunaan.',
          'Selalu sama di semua blockchain.',
        ],
        correctIndex: 1,
        explanation: 'Biaya bergantung pada aturan dan kepadatan jaringan. '
            'Periksa biaya yang ditampilkan sebelum mengirim.',
      ),
    ],
  ),
  LearningModule(
    id: 'wallet-security',
    title: 'Wallet dan keamanan',
    summary: 'Pahami alamat publik, private key, dan seed phrase.',
    icon: Icons.security,
    lessons: [
      LearningLesson(
        'Kunci wallet',
        'Wallet membantu mengelola kunci untuk mengakses aset yang tercatat di '
            'blockchain. Alamat publik dapat dibagikan untuk menerima aset, '
            'tetapi private key dan seed phrase harus dirahasiakan.',
      ),
      LearningLesson(
        'Lindungi seed phrase',
        'Simpan seed phrase secara offline di tempat aman. Jangan masukkan ke '
            'tautan, formulir, atau aplikasi yang tidak dipercaya. Pihak '
            'dukungan resmi tidak memerlukan seed phrase untuk membantu.',
      ),
    ],
    questions: [
      LearningQuestion(
        question:
            'Seseorang yang mengaku petugas meminta seed phrase. Apa yang kamu lakukan?',
        options: [
          'Memberikannya agar akun bisa diverifikasi.',
          'Menolak dan tidak membagikannya kepada siapa pun.',
          'Mengirim hanya beberapa kata.',
        ],
        correctIndex: 1,
        explanation: 'Siapa pun yang memiliki seed phrase dapat mengendalikan '
            'wallet. Jangan pernah membagikannya, termasuk kepada orang yang '
            'mengaku sebagai petugas.',
      ),
      LearningQuestion(
        question:
            'Informasi mana yang umumnya dapat dibagikan untuk menerima aset?',
        options: [
          'Seed phrase.',
          'Private key.',
          'Alamat publik wallet, setelah memastikan jaringannya cocok.',
        ],
        correctIndex: 2,
        explanation:
            'Alamat publik digunakan untuk menerima aset. Tetap periksa '
            'jaringan dan alamatnya; private key dan seed phrase harus tetap rahasia.',
      ),
    ],
  ),
  LearningModule(
    id: 'risk-management',
    title: 'Risiko dan keputusan keuangan',
    summary:
        'Kenali volatilitas, diversifikasi, dan batas kemampuan finansial.',
    icon: Icons.balance,
    lessons: [
      LearningLesson(
        'Pahami risikonya',
        'Nilai aset dapat turun tajam, dan seluruh modal yang digunakan bisa '
            'berisiko. Hindari memakai uang kebutuhan pokok, dana darurat, atau '
            'uang pinjaman untuk berlatih investasi.',
      ),
      LearningLesson(
        'Tidak ada strategi yang pasti untung',
        'Diversifikasi dapat mengurangi ketergantungan pada satu aset, tetapi '
            'tidak menghilangkan risiko. Pembelian berkala (DCA) juga tidak '
            'menjamin hasil positif.',
      ),
    ],
    questions: [
      LearningQuestion(
        question: 'Uang mana yang paling tepat digunakan untuk simulasi?',
        options: [
          'Dana sewa dan kebutuhan pokok.',
          'Dana darurat.',
          'Saldo virtual atau uang yang tidak dibutuhkan untuk kebutuhan penting.',
        ],
        correctIndex: 2,
        explanation: 'Kebutuhan penting dan dana darurat sebaiknya tidak '
            'dipertaruhkan. Simulasi menggunakan saldo virtual untuk belajar '
            'tanpa risiko uang sungguhan.',
      ),
      LearningQuestion(
        question: 'Apakah DCA menjamin keuntungan?',
        options: [
          'Ya, karena harga pasti pulih.',
          'Tidak. DCA mengatur waktu pembelian, tetapi risiko kerugian tetap ada.',
          'Ya, jika dilakukan setiap minggu.',
        ],
        correctIndex: 1,
        explanation: 'DCA tidak dapat memastikan harga akan naik. Nilai aset '
            'tetap bisa turun, sehingga hasil akhirnya bisa merugi.',
      ),
    ],
  ),
  LearningModule(
    id: 'scam-awareness',
    title: 'Mengenali penipuan',
    summary:
        'Waspadai janji untung pasti, tautan palsu, dan permintaan akses wallet.',
    icon: Icons.gpp_maybe,
    lessons: [
      LearningLesson(
        'Tanda bahaya',
        'Janji keuntungan pasti, tekanan untuk segera transfer, hadiah yang '
            'meminta biaya di muka, dan pesan pribadi yang meminta rahasia '
            'wallet adalah tanda bahaya.',
      ),
      LearningLesson(
        'Berhenti dan verifikasi',
        'Jangan membuka tautan atau memasang aplikasi dari sumber yang tidak '
            'dikenal. Periksa alamat situs dan pengumuman melalui kanal resmi '
            'yang kamu cari sendiri, bukan dari tautan pesan mencurigakan.',
      ),
    ],
    questions: [
      LearningQuestion(
        question:
            'Sebuah grup menjanjikan keuntungan pasti jika kamu transfer sekarang. Apa langkah aman?',
        options: [
          'Transfer sedikit untuk mencoba.',
          'Jangan transfer; hentikan interaksi dan verifikasi secara mandiri.',
          'Berikan seed phrase agar mereka bisa mengelola investasi.',
        ],
        correctIndex: 1,
        explanation:
            'Keuntungan pasti dan tekanan untuk segera bertindak adalah '
            'tanda bahaya. Jangan kirim uang atau rahasia wallet.',
      ),
      LearningQuestion(
        question: 'Bagaimana cara memeriksa tautan layanan kripto?',
        options: [
          'Membuka tautan dari pesan yang tidak diminta.',
          'Memeriksa alamat situs melalui kanal resmi yang dicari sendiri.',
          'Mengirim kode verifikasi kepada pengirim.',
        ],
        correctIndex: 1,
        explanation: 'Cari kanal resmi secara mandiri dan periksa alamat situs '
            'dengan teliti. Jangan membagikan kode verifikasi atau seed phrase.',
      ),
    ],
  ),
];

class LearningModuleScreen extends StatefulWidget {
  final LearningModule module;
  final int moduleNumber;
  final int totalModules;
  final Future<bool> Function() onComplete;

  const LearningModuleScreen({
    super.key,
    required this.module,
    required this.moduleNumber,
    required this.totalModules,
    required this.onComplete,
  });

  @override
  State<LearningModuleScreen> createState() => _LearningModuleScreenState();
}

class _LearningModuleScreenState extends State<LearningModuleScreen> {
  int _questionIndex = 0;
  int? _selectedOption;
  bool _saving = false;

  Future<void> _continue() async {
    final question = widget.module.questions[_questionIndex];
    if (_selectedOption == null) return;
    if (_selectedOption != question.correctIndex) {
      setState(() => _selectedOption = null);
      return;
    }

    if (_questionIndex < widget.module.questions.length - 1) {
      setState(() {
        _questionIndex++;
        _selectedOption = null;
      });
      return;
    }

    setState(() => _saving = true);
    final saved = await widget.onComplete();
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.module.questions[_questionIndex];
    final answered = _selectedOption != null;
    final correct = _selectedOption == question.correctIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.module.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'JALUR BELAJAR • MODUL ${widget.moduleNumber} DARI ${widget.totalModules}',
            style: const TextStyle(
              color: AppColors.tealDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.module.summary,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SectionTitle('Materi'),
          for (final lesson in widget.module.lessons)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(lesson.body),
                  ],
                ),
              ),
            ),
          const SectionTitle('Kuis singkat'),
          Text(
            'Soal ${_questionIndex + 1} dari ${widget.module.questions.length}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_questionIndex + (correct ? 1 : 0)) /
                widget.module.questions.length,
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              question.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < question.options.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                onTap: answered
                    ? null
                    : () => setState(() => _selectedOption = index),
                color: !answered
                    ? null
                    : index == question.correctIndex
                        ? AppColors.successBg
                        : index == _selectedOption
                            ? AppColors.dangerBg
                            : null,
                child: Row(
                  children: [
                    Expanded(child: Text(question.options[index])),
                    if (answered && index == question.correctIndex)
                      const Icon(Icons.check_circle, color: AppColors.success),
                    if (answered && index == _selectedOption && !correct)
                      const Icon(Icons.cancel, color: AppColors.danger),
                  ],
                ),
              ),
            ),
          if (answered) ...[
            const SizedBox(height: 4),
            AppCard(
              color: correct ? AppColors.successBg : AppColors.dangerBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correct ? 'Jawaban benar' : 'Belum tepat',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: correct
                          ? AppColors.successText
                          : AppColors.dangerText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(question.explanation),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: _saving
                  ? 'Menyimpan progres...'
                  : correct
                      ? _questionIndex == widget.module.questions.length - 1
                          ? 'Selesaikan modul'
                          : 'Pertanyaan berikutnya'
                      : 'Coba lagi',
              loading: _saving,
              onPressed: _saving ? null : _continue,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
