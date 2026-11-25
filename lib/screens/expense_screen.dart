import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  static const _categories = [
    'Makan & Minum',
    'Transportasi',
    'Kebutuhan',
    'Pendidikan',
    'Hiburan',
    'Lainnya',
  ];

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _listController = ScrollController();
  String _category = _categories.first;
  DateTime _date = DateTime.now();
  bool _saving = false;
  int? _editingExpenseId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text);
    final editingId = _editingExpenseId;
    setState(() => _saving = true);
    try {
      if (editingId == null) {
        await AppState.instance.addExpense(
          amount: amount,
          category: _category,
          note: _noteController.text,
          date: _date,
        );
      } else {
        final updated = await AppState.instance.updateExpense(
          id: editingId,
          amount: amount,
          category: _category,
          note: _noteController.text,
          date: _date,
        );
        if (!updated) {
          throw StateError('Catatan pengeluaran tidak ditemukan.');
        }
      }
      if (!mounted) return;
      _amountController.clear();
      _noteController.clear();
      setState(() {
        _date = DateTime.now();
        _category = _categories.first;
        _editingExpenseId = null;
        _saving = false;
      });
      showSnack(
        context,
        editingId == null
            ? 'Pengeluaran berhasil disimpan'
            : 'Pengeluaran berhasil diperbarui',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(
        context,
        '${editingId == null ? 'Gagal menyimpan' : 'Gagal memperbarui'} '
        'pengeluaran: $error',
        error: true,
      );
    }
  }

  void _startEditing(Map<String, dynamic> expense) {
    setState(() {
      _editingExpenseId = expense['id'] as int;
      _amountController.text =
          (expense['amount'] as num).toDouble().toStringAsFixed(0);
      _noteController.text = expense['note'] as String;
      _category = expense['category'] as String;
      _date = DateTime.fromMillisecondsSinceEpoch(expense['waktu'] as int);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _listController.hasClients) {
        _listController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _cancelEditing() {
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _editingExpenseId = null;
      _category = _categories.first;
      _date = DateTime.now();
    });
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pengeluaran?'),
        content:
            const Text('Catatan pengeluaran ini akan dihapus dari perangkat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AppState.instance.deleteExpense(id);
      if (!mounted) return;
      if (_editingExpenseId == id) _cancelEditing();
      showSnack(context, 'Pengeluaran dihapus');
    } catch (error) {
      if (mounted) {
        showSnack(context, 'Gagal menghapus pengeluaran: $error', error: true);
      }
    }
  }

  double _monthTotal(
    List<Map<String, dynamic>> expenses,
    DateTime month,
  ) {
    return expenses.where((expense) {
      final date = DateTime.fromMillisecondsSinceEpoch(expense['waktu'] as int);
      return date.year == month.year && date.month == month.month;
    }).fold<double>(
      0,
      (total, expense) => total + (expense['amount'] as num).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Catat Pengeluaran')),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final expenses = app.expenses;
          final now = DateTime.now();
          final previousMonth = DateTime(now.year, now.month - 1);
          return ListView(
            controller: _listController,
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                color: AppColors.tealSoft.withValues(alpha: 0.55),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total pengeluaran bulan ini',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rupiah(_monthTotal(expenses, now)),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    const Text(
                      'Total pengeluaran bulan lalu',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rupiah(_monthTotal(expenses, previousMonth)),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingExpenseId == null
                            ? 'Pengeluaran baru'
                            : 'Edit pengeluaran',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Nominal',
                          prefixText: 'Rp ',
                        ),
                        validator: (value) {
                          final amount = double.tryParse(value ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Masukkan nominal lebih dari 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey<int?>(_editingExpenseId),
                        initialValue: _category,
                        decoration:
                            const InputDecoration(labelText: 'Kategori'),
                        items: [
                          for (final category in _categories)
                            DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteController,
                        maxLength: 80,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                          hintText: 'Contoh: makan siang',
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                              'Tanggal: ${DateFormat('dd/MM/yyyy').format(_date)}'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        label: _editingExpenseId == null
                            ? 'Simpan Pengeluaran'
                            : 'Perbarui Pengeluaran',
                        icon: _editingExpenseId == null
                            ? Icons.save_outlined
                            : Icons.edit_outlined,
                        loading: _saving,
                        onPressed: _save,
                      ),
                      if (_editingExpenseId != null)
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: _saving ? null : _cancelEditing,
                            child: const Text('Batal mengedit'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SectionTitle('Riwayat Pengeluaran'),
              if (expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Belum ada pengeluaran yang dicatat.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
              for (final expense in expenses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: Row(
                      children: [
                        const IconBubble(Icons.receipt_long),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense['category'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              if ((expense['note'] as String).isNotEmpty)
                                Text(
                                  expense['note'] as String,
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 12),
                                ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      expense['waktu'] as int),
                                ),
                                style: const TextStyle(
                                    color: AppColors.hint, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          rupiah(expense['amount'] as num),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Aksi catatan',
                          onSelected: (action) {
                            if (action == 'edit') {
                              _startEditing(expense);
                            } else if (action == 'delete') {
                              _confirmDelete(expense['id'] as int);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: AppColors.danger),
                                  SizedBox(width: 8),
                                  Text('Hapus'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
