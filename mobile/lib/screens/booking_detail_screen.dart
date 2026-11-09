import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../models/booking.dart';
import '../models/fare_item.dart';
import '../models/price_breakdown.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../utils/ui.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/booking_status_chip.dart';
import 'login_screen.dart';

/// One booking: PNR, ticket details, price breakdown and cancellation.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late Booking _booking;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Future<void> _refresh() async {
    final app = context.read<AppState>();
    try {
      final updated = await app.bookingService.get(_booking.id);
      if (!mounted) return;
      setState(() => _booking = updated);
    } catch (_) {
      // Stale data is still better than an error page on a ticket.
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('বুকিং বাতিল করবেন?'),
        content: const Text(
          'টিকিট বাতিল করলে আর ফিরিয়ে নেওয়া যাবে না।',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('না, থাক'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kBrandRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('হ্যাঁ, বাতিল করুন'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final app = context.read<AppState>();
    try {
      final updated = await app.bookingService.cancel(
        _booking.id,
        reason: 'যাত্রী নিজে বাতিল করেছেন',
      );
      if (!mounted) return;
      setState(() => _booking = updated);
      showSuccessSnack(context, 'বুকিং বাতিল হয়েছে।');
    } catch (caught) {
      if (!mounted) return;
      showErrorSnack(context, caught);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _logout() async {
    final app = context.read<AppState>();
    await app.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = _booking;
    final fare = booking.fare;
    final price = booking.price;

    return Scaffold(
      appBar: AppBar(title: const Text('বুকিং বিস্তারিত')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildPnrCard(theme, booking),
                const SizedBox(height: 14),
                if (fare != null) ...<Widget>[
                  _buildJourneyCard(theme, booking, fare),
                  const SizedBox(height: 14),
                ],
                if (price != null) ...<Widget>[
                  _buildPriceCard(theme, booking, price),
                  const SizedBox(height: 14),
                ],
                _buildPassengerCard(theme, booking),
                const SizedBox(height: 14),
                _buildStatusCard(theme, booking),
                if (booking.canBeCancelled) ...<Widget>[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _cancelling ? null : _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kBrandRed,
                      side: const BorderSide(color: kBrandRed),
                    ),
                    icon: _cancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_outlined),
                    label: const Text('বুকিং বাতিল করুন'),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _logout,
                  child: const Text('লগআউট'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPnrCard(ThemeData theme, Booking booking) {
    final color = bookingStatusColor(booking.status);
    return Card(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'PNR',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: const Color(0xFF6B726B)),
                ),
                BookingStatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                booking.pnr.isEmpty ? '—' : booking.pnr,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            if (booking.createdAt != null) ...<Widget>[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'বুকিং: ${formatDateTime(booking.createdAt!)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B726B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyCard(
    ThemeData theme,
    Booking booking,
    FareItem fare,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  transportTypeIcon(fare.transportType),
                  size: 20,
                  color: kBrandGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${fare.source} → ${fare.destination}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _row('প্রোভাইডার',
                fare.provider.isEmpty ? fare.transportType.labelBn : fare.provider),
            if (fare.travelDate != null)
              _row('তারিখ', formatDate(fare.travelDate!)),
            _row(
              'সময়',
              '${fare.departTime ?? '--:--'} → ${fare.arriveTime ?? '--:--'}'
              ' · ${formatDuration(fare.durationMins)}',
            ),
            if (fare.vehicleClass != null)
              _row('শ্রেণি', fare.vehicleClass!),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(
    ThemeData theme,
    Booking booking,
    PriceBreakdown price,
  ) {
    Widget line(String label, String value, {bool emphasised = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: emphasised ? 16 : 14,
                fontWeight: emphasised ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: emphasised ? 19 : 14.5,
                fontWeight: emphasised ? FontWeight.w800 : FontWeight.w600,
                color: emphasised ? kBrandGreen : const Color(0xFF232823),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'ভাড়ার হিসাব',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            line('আসল ভাড়া', formatBdt(price.baseFare)),
            if (price.mfsCashback > 0)
              line('MFS ক্যাশব্যাক', '- ${formatBdt(price.mfsCashback)}'),
            if (price.promoDiscount > 0)
              line('প্রোমো ছাড়', '- ${formatBdt(price.promoDiscount)}'),
            line('সুবিধা ফি', '+ ${formatBdt(price.convenienceFee)}'),
            const Divider(height: 18),
            line(
              'কার্যকর মূল্য × ${booking.quantity}',
              formatBdt(booking.totalPaid),
              emphasised: true,
            ),
            if (price.hasSavings)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'মোট সাশ্রয় ${formatBdt(price.computedSavedAmount * booking.quantity)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kSavingsColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCard(ThemeData theme, Booking booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'যাত্রী',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _row('নাম', booking.passengerName),
            _row('মোবাইল', booking.passengerPhone),
            _row('সংখ্যা', '${booking.quantity} জন'),
            _row(
              'পেমেন্ট',
              booking.paymentMethod.labelBn +
                  (booking.mfsProvider == null
                      ? ''
                      : ' · ${booking.mfsProvider}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, Booking booking) {
    final status = booking.status;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(bookingStatusIcon(status), size: 18, color: bookingStatusColor(status)),
                const SizedBox(width: 8),
                Text(
                  'স্ট্যাটাস: ${status.labelBn}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (booking.transactionId != null) ...<Widget>[
              const SizedBox(height: 8),
              _row('ট্রানজেকশন', booking.transactionId!),
            ],
            if (booking.failureReason != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                booking.failureReason!,
                style: const TextStyle(fontSize: 13, color: kBrandRed),
              ),
            ],
            if (booking.updatedAt != null) ...<Widget>[
              const SizedBox(height: 8),
              _row('সর্বশেষ আপডেট', formatDateTime(booking.updatedAt!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B726B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF232823)),
            ),
          ),
        ],
      ),
    );
  }
}
