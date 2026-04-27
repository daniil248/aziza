import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';

class CourierHomeScreen extends ConsumerWidget {
  const CourierHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aziza Courier')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _OrderCard(
            code: 'AZF-1042',
            address: 'Абая 150, кв. 12',
            distance: '2.4 км',
            payout: '+1 200 ₸',
          ),
          _OrderCard(
            code: 'AZF-1043',
            address: 'Жибек жолы 87, оф. 504',
            distance: '4.1 км',
            payout: '+1 400 ₸',
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.code,
    required this.address,
    required this.distance,
    required this.payout,
  });

  final String code;
  final String address;
  final String distance;
  final String payout;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(code, style: AppTypography.subtitle(AppColors.textPrimary)),
                const Spacer(),
                Text(
                  payout,
                  style: AppTypography.bodyMedium(AppColors.gold)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(address,
                      style: AppTypography.body(AppColors.textPrimary)),
                ),
                Text(distance, style: AppTypography.caption(AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Принять заказ'),
              ),
            ),
          ],
        ),
      );
}
