import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/booking.dart';
import '../utils/format.dart';
import 'booking_status_chip.dart';

/// Summary row for a booking in the "my bookings" list.
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, this.onTap});

  final Booking booking;
  final VoidCallback? onTap;

  static const Color _muted = Color(0xFF6B726B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fare = booking.fare;
    final route = fare == null
        ? 'রুট তথ্য নেই'
        : '${fare.source} → ${fare.destination}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'PNR: ${booking.pnr.isEmpty ? '—' : booking.pnr}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  BookingStatusChip(status: booking.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                route,
                style: const TextStyle(fontSize: 15, color: Color(0xFF232823)),
              ),
              if (fare?.travelDate != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  formatDate(fare!.travelDate!),
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Icon(Icons.person_outline, size: 15, color: _muted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${booking.passengerName} · ${booking.quantity} জন',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                  ),
                  Text(
                    formatBdt(booking.totalPaid),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: kBrandGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
