import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Russian labels + display colors for backend order statuses.
class OrderStatusInfo {
  const OrderStatusInfo(this.label, this.color);
  final String label;
  final Color color;
}

OrderStatusInfo orderStatusInfo(String status) {
  return switch (status) {
    'pending' => const OrderStatusInfo('Новый', AppColors.textSecondary),
    'confirmed' => const OrderStatusInfo('Подтверждён', AppColors.gold),
    'preparing' => const OrderStatusInfo('Готовится', AppColors.gold),
    'courier_assigned' => const OrderStatusInfo('Курьер назначен', AppColors.gold),
    'in_transit' => const OrderStatusInfo('В пути', AppColors.gold),
    'delivered' => const OrderStatusInfo('Доставлен', AppColors.success),
    'cancelled' => const OrderStatusInfo('Отменён', AppColors.error),
    _ => OrderStatusInfo(status, AppColors.textSecondary),
  };
}

/// Russian labels for payment methods.
String paymentMethodLabel(String method) {
  return switch (method) {
    'cash' => 'Наличные',
    'card_online' => 'Карта онлайн',
    'kaspi' => 'Kaspi',
    'halyk' => 'Halyk',
    'apple_pay' => 'Apple Pay',
    'google_pay' => 'Google Pay',
    _ => method,
  };
}
