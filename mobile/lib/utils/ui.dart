import 'package:flutter/material.dart';

import '../models/enums.dart';

IconData transportTypeIcon(TransportType type) {
  return switch (type) {
    TransportType.train => Icons.train,
    TransportType.bus => Icons.directions_bus,
    TransportType.launch => Icons.directions_boat,
    TransportType.flight => Icons.flight,
    TransportType.all => Icons.alt_route,
  };
}

Color bookingStatusColor(BookingStatus status) {
  return switch (status) {
    BookingStatus.pending => const Color(0xFFB26A00),
    BookingStatus.confirmed => const Color(0xFF1B7F5A),
    BookingStatus.failed => const Color(0xFFC62828),
    BookingStatus.cancelled => const Color(0xFF616161),
  };
}

IconData bookingStatusIcon(BookingStatus status) {
  return switch (status) {
    BookingStatus.pending => Icons.hourglass_top,
    BookingStatus.confirmed => Icons.verified,
    BookingStatus.failed => Icons.error_outline,
    BookingStatus.cancelled => Icons.cancel_outlined,
  };
}

IconData notificationIcon(String? channel) {
  return switch (channel?.toUpperCase()) {
    'EMAIL' => Icons.email_outlined,
    'SMS' => Icons.sms_outlined,
    'PUSH' => Icons.notifications_none,
    'WHATSAPP' => Icons.chat_bubble_outline,
    _ => Icons.notifications_none,
  };
}
