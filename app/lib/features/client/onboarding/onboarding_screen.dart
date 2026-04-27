import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const seenKey = 'onboarding_seen_v1';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(OnboardingScreen.seenKey, true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final slides = [
      _Slide(
        icon: LucideIcons.utensils,
        bg: const Color(0xFFF6E9C9),
        title: t.onboarding1Title,
        body: t.onboarding1Body,
      ),
      _Slide(
        icon: LucideIcons.creditCard,
        bg: const Color(0xFFEFE7DA),
        title: t.onboarding2Title,
        body: t.onboarding2Body,
      ),
      _Slide(
        icon: LucideIcons.crown,
        bg: const Color(0xFFFAF1D6),
        title: t.onboarding3Title,
        body: t.onboarding3Body,
      ),
    ];
    final isLast = _page == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(t.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: slides,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: AppDuration.base,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: active ? 24 : 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.gold : AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _ctrl.nextPage(
                        duration: AppDuration.base,
                        curve: AppDuration.cubicEmphasized,
                      );
                    }
                  },
                  child: Text(isLast ? t.onboardingStart : t.onboardingNext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.icon,
    required this.bg,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color bg;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: AppColors.textPrimary.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.display(AppColors.textPrimary).copyWith(fontSize: 30),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.body(AppColors.textSecondary),
            ),
          ],
        ),
      );
}

/// Has the user seen onboarding? Read once at app start; never invalidated mid-session.
final onboardingSeenProvider = Provider<bool>(
  (ref) => ref.read(sharedPrefsProvider).getBool(OnboardingScreen.seenKey) ?? false,
);
