import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

class LearningProgressCard extends StatelessWidget {
  const LearningProgressCard({
    super.key,
    required this.completedCount,
    required this.totalModules,
    required this.nextModuleLabel,
    required this.onTap,
  });

  final int completedCount;
  final int totalModules;
  final String nextModuleLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = totalModules == 0 ? 0.0 : completedCount / totalModules;
    final percentage = (progress * 100).round();

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lanjutkan Belajar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$completedCount/$totalModules modul selesai',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            nextModuleLabel,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: AppColors.teal,
              backgroundColor: AppColors.recessed,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage% selesai',
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
