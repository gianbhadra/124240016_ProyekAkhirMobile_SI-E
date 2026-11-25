import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<bool> _reminderScheduled =
      NotificationService.isHourlyExpenseReminderScheduled();

  Future<void> _refreshStatus() async {
    setState(() {
      _reminderScheduled =
          NotificationService.isHourlyExpenseReminderScheduled();
    });
    await _reminderScheduled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pusat Notifikasi',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pengingat CoinWise juga dapat dilihat di sini.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconBubble(Icons.notifications_active_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pengingat CoinWise',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Jangan lupa catat pengeluaranmu hari ini agar '
                        'keuangan tetap terpantau.',
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<bool>(
                        future: _reminderScheduled,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              'Memeriksa jadwal pengingat...',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Text(
                              'Status pengingat tidak dapat diperiksa.',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 12,
                              ),
                            );
                          }
                          return Text(
                            snapshot.data == true
                                ? 'Aktif • dijadwalkan setiap 1 jam'
                                : 'Belum aktif • buka Beranda dan izinkan notifikasi',
                            style: TextStyle(
                              color: snapshot.data == true
                                  ? AppColors.successText
                                  : AppColors.dangerText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _refreshStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Periksa status lagi'),
          ),
        ],
      ),
    );
  }
}
