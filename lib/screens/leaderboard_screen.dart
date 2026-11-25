import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

/// Papan skor online (data dari Supabase).
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final Future<List<Map<String, dynamic>>?> _future = SupabaseService.leaderboard();

  @override
  Widget build(BuildContext context) {
    final me = AppState.instance.user?.username;
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard Online')),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data;
          if (data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  SupabaseService.enabled
                      ? 'Tidak bisa memuat. Periksa koneksi internet.\n${SupabaseService.lastError}'
                      : 'Supabase belum diatur (SUPABASE_URL dan SUPABASE_KEY).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            );
          }
          // Ambil skor terbaik tiap pengguna (data sudah terurut dari skor tertinggi).
          final best = <String, int>{};
          for (final r in data) {
            best.putIfAbsent(r['username'] as String, () => r['skor'] as int);
          }
          final list = best.entries.take(10).toList();
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada skor. Mainkan Tebak Tren dulu!'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    color: list[i].key == me ? AppColors.tealSoft.withValues(alpha: 0.5) : null,
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      SizedBox(
                        width: 36,
                        child: Text(i < 3 ? ['🥇', '🥈', '🥉'][i] : '${i + 1}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ),
                      Expanded(
                        child: Text('@${list[i].key}${list[i].key == me ? ' (kamu)' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Text('${list[i].value}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
