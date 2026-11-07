import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../utils/ui.dart';

/// Colour coded status pill for a booking.
class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = bookingStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(bookingStatusIcon(status), size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            status.labelBn,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
