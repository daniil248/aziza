import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/i18n/generated/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _ctrl = TextEditingController();
  bool get _valid => _ctrl.text.replaceAll(RegExp(r'\D'), '').length >= 11;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                t.loginTitle,
                style: AppTypography.display(AppColors.textPrimary).copyWith(fontSize: 32),
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+\-\(\) ]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                onChanged: (_) => setState(() {}),
                style: AppTypography.bodyMedium(AppColors.textPrimary)
                    .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: t.loginPhoneHint,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Icon(LucideIcons.phone, size: 20),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                t.loginPolicy,
                style: AppTypography.caption(AppColors.textSecondary),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _valid
                      ? () => context.push('/login/otp?phone=${Uri.encodeComponent(_ctrl.text)}')
                      : null,
                  child: Text(t.loginGetCode),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});
  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool get _valid => _ctrl.text.length == 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                t.otpTitle,
                style: AppTypography.display(AppColors.textPrimary).copyWith(fontSize: 32),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.otpSent(widget.phone),
                style: AppTypography.body(AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (v) {
                      setState(() {});
                      if (v.length == 4) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) context.go('/');
                        });
                      }
                    },
                    style: AppTypography.display(AppColors.textPrimary).copyWith(
                      fontSize: 36,
                      letterSpacing: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '— — — —',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(t.otpResend),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _valid ? () => context.go('/') : null,
                  child: Text(t.otpVerify),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
