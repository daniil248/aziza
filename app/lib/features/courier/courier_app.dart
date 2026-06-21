import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/auth_api.dart';
import '../../core/api/auth_dto.dart';
import '../../core/api/order_status.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/session/session.dart';

/// Courier feed provider — refreshed on demand via invalidate.
final courierFeedProvider = FutureProvider<CourierFeed>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isLoggedIn) {
    return CourierFeed(available: const [], mine: const [], done: const []);
  }
  return ref.read(ordersApiProvider).courierOrders();
});

/// Root: shows login if logged-out OR logged in as non-courier; board otherwise.
class CourierHomeScreen extends ConsumerWidget {
  const CourierHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.isLoggedIn && session.isCourier) {
      return const _CourierBoard();
    }
    return const _CourierLogin();
  }
}

class _CourierLogin extends ConsumerStatefulWidget {
  const _CourierLogin();

  @override
  ConsumerState<_CourierLogin> createState() => _CourierLoginState();
}

class _CourierLoginState extends ConsumerState<_CourierLogin> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  String get _digits => _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
  bool get _valid => _digits.length >= 10 && _passCtrl.text.length >= 6;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user =
          await ref.read(sessionProvider.notifier).loginWithPassword(_digits, _passCtrl.text);
      if (!user.isCourier) {
        await ref.read(sessionProvider.notifier).logout();
        if (mounted) setState(() => _error = 'Этот аккаунт не является курьером');
        return;
      }
      ref.invalidate(courierFeedProvider);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Не удалось войти');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aziza Courier')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text('Вход для курьера',
                  style: AppTypography.display(AppColors.textPrimary).copyWith(fontSize: 28)),
              const SizedBox(height: AppSpacing.xxl),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+\-\(\) ]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Телефон',
                  prefixIcon: Icon(LucideIcons.phone, size: 20),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Пароль',
                  prefixIcon: Icon(LucideIcons.lock, size: 20),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: AppTypography.caption(AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _valid && !_busy ? _submit : null,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Войти'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourierBoard extends ConsumerWidget {
  const _CourierBoard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(courierFeedProvider);
    final name = ref.watch(sessionProvider).user?.name ?? 'Курьер';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Курьер · $name'),
          actions: [
            IconButton(
              tooltip: 'Обновить',
              icon: const Icon(LucideIcons.refreshCw, size: 20),
              onPressed: () => ref.invalidate(courierFeedProvider),
            ),
            IconButton(
              tooltip: 'Выйти',
              icon: const Icon(LucideIcons.logOut, size: 20),
              onPressed: () => ref.read(sessionProvider.notifier).logout(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Свободные'),
              Tab(text: 'Мои'),
              Tab(text: 'Доставленные'),
            ],
          ),
        ),
        body: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ошибка: $e',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(courierFeedProvider),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
          data: (f) => TabBarView(
            children: [
              _OrderList(orders: f.available, kind: _Kind.available),
              _OrderList(orders: f.mine, kind: _Kind.mine),
              _OrderList(orders: f.done, kind: _Kind.done),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Kind { available, mine, done }

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.orders, required this.kind});
  final List<OrderDto> orders;
  final _Kind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return Center(
        child: Text('Пусто', style: AppTypography.body(AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(courierFeedProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: orders.length,
        itemBuilder: (_, i) => _CourierOrderCard(order: orders[i], kind: kind),
      ),
    );
  }
}

class _CourierOrderCard extends ConsumerStatefulWidget {
  const _CourierOrderCard({required this.order, required this.kind});
  final OrderDto order;
  final _Kind kind;

  @override
  ConsumerState<_CourierOrderCard> createState() => _CourierOrderCardState();
}

class _CourierOrderCardState extends ConsumerState<_CourierOrderCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? conflictMsg}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(courierFeedProvider);
    } on ApiException catch (e) {
      final msg = e.statusCode == 409 ? (conflictMsg ?? e.message) : e.message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final api = ref.read(ordersApiProvider);
    final info = orderStatusInfo(o.status);

    return Container(
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
              Text('№ ${o.code}',
                  style: AppTypography.subtitle(AppColors.textPrimary)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(info.label,
                    style: AppTypography.caption(info.color)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(o.total.toString(),
                  style: AppTypography.bodyMedium(AppColors.gold)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (o.client != null)
            _IconRow(
              icon: LucideIcons.user,
              text: [
                if ((o.client!.name ?? '').isNotEmpty) o.client!.name!,
                if ((o.client!.phone ?? '').isNotEmpty) '+${o.client!.phone!}',
              ].join(' · '),
            ),
          if (o.address != null)
            _IconRow(icon: LucideIcons.mapPin, text: o.address!.oneLine),
          _IconRow(
            icon: LucideIcons.banknote,
            text: '${paymentMethodLabel(o.paymentMethod)} · ${o.totalQty} поз.',
          ),
          if (o.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              o.items
                  .map((it) => '${it.qty}× ${it.variantLabel}')
                  .join(', '),
              style: AppTypography.caption(AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else
            ..._actions(o, api),
        ],
      ),
    );
  }

  List<Widget> _actions(OrderDto o, dynamic api) {
    switch (widget.kind) {
      case _Kind.available:
        return [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _run(() => api.courierTake(o.id),
                  conflictMsg: 'Заказ уже взят другим курьером'),
              child: const Text('Взять'),
            ),
          ),
        ];
      case _Kind.mine:
        return [
          Row(
            children: [
              if (o.status != 'in_transit')
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _run(() => api.courierSetStatus(o.id, 'in_transit')),
                    child: const Text('В пути'),
                  ),
                ),
              if (o.status != 'in_transit') const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _run(() => api.courierSetStatus(o.id, 'delivered')),
                  child: const Text('Доставлен'),
                ),
              ),
            ],
          ),
        ];
      case _Kind.done:
        return const [];
    }
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text, style: AppTypography.body(AppColors.textPrimary)),
            ),
          ],
        ),
      );
}
