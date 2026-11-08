import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/enums.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/booking_card.dart';
import '../widgets/booking_status_chip.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

/// Everything the signed-in passenger has booked, newest first.
///
/// Lives as the middle tab of the home shell and keeps its own loading, error
/// and empty states.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Booking> _bookings = const <Booking>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Post-frame so the very first (loading) frame can render before the
    // request notifies listeners.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bookings = await app.bookingService.list();
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = errorMessageOf(error);
        _loading = false;
      });
    }
  }

  Future<void> _openDetail(Booking booking) async {
    final updated = await showModalBottomSheet<Booking>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _BookingDetailSheet(booking: booking),
    );
    if (updated == null || !mounted) return;

    setState(() {
      _bookings = _bookings
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
    });
    showSuccessSnack(
      context,
      updated.status == BookingStatus.cancelled
          ? 'বুকিং বাতিল করা হয়েছে।'
          : 'বুকিং আপডেট হয়েছে।',
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_loading) {
      body = const LoadingView(message: 'বুকিং আনা হচ্ছে...');
    } else if (_error != null) {
      body = ErrorView(message: _error!, onRetry: _load);
    } else if (_bookings.isEmpty) {
      body = const EmptyView(
        icon: Icons.confirmation_number_outlined,
        title: 'এখনো কোনো বুকিং করা হয়নি',
        subtitle: 'খুঁজে টিকিট বুক করলে সব এখানে জমা হবে।',
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: _bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return BookingCard(
            booking: booking,
            onTap: () => _openDetail(booking),
          );
        },
      );
    }

    return RefreshIndicator(onRefresh: _load, child: body);
  }
}

/// Bottom sheet with the full booking and – while the status allows it – the
/// cancellation flow.
class _BookingDetailSheet extends StatefulWidget {
  const _BookingDetailSheet({required this.booking});

  final Booking booking;

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  static const Color _muted = Color(0xFF6B726B);

  bool _cancelling = false;

  Future<void> _cancel() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _CancelReasonDialog(),
    );
    if (reason == null || reason.isEmpty || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final updated = await context.read<AppState>().bookingService.cancel(
        widget.booking.id,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showErrorSnack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = widget.booking;
    final fare = booking.fare;
    final price = booking.price;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'PNR: ${booking.pnr.isEmpty ? '—' : booking.pnr}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  BookingStatusChip(status: booking.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                fare == null
                    ? 'রুট তথ্য নেই'
                    : '${fare.source} → ${fare.destination}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (fare != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  '${fare.travelDate == null ? '' : '${formatDateWithWeekday(fare.travelDate!)} · '}'
                  '${fare.departTime ?? '--:--'} → ${fare.arriveTime ?? '--:--'}'
                  '${fare.provider.isEmpty ? '' : ' · ${fare.provider}'}',
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(height: 1),
              _row(
                'যাত্রী',
                '${booking.passengerName} · ${booking.quantity} জন',
              ),
              _row('মোবাইল', booking.passengerPhone),
              _row(
                'পেমেন্ট',
                booking.paymentMethod.labelBn +
                    (booking.mfsProvider == null
                        ? ''
                        : ' · ${booking.mfsProvider}') +
                    (booking.transactionId == null
                        ? ''
                        : ' · ${booking.transactionId}'),
              ),
              if (price != null) ...<Widget>[
                _row('আসল ভাড়া', formatBdt(price.baseFare)),
                if (price.mfsCashback > 0)
                  _row('MFS ক্যাশব্যাক', '- ${formatBdt(price.mfsCashback)}'),
                if (price.promoDiscount > 0)
                  _row('প্রোমো ছাড়', '- ${formatBdt(price.promoDiscount)}'),
                if (price.convenienceFee > 0)
                  _row('সুবিধা ফি', '+ ${formatBdt(price.convenienceFee)}'),
                _row('মোট পরিশোধিত', formatBdt(booking.totalPaid)),
              ],
              if (booking.failureReason != null)
                _row('কারণ', booking.failureReason!),
              if (booking.createdAt != null)
                _row('বুক করা হয়েছে', formatDateTime(booking.createdAt!)),
              if (booking.updatedAt != null)
                _row('সর্বশেষ আপডেট', formatDateTime(booking.updatedAt!)),
              if (fare?.cancellationPolicy != null) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.rule_outlined, size: 16, color: _muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'বাতিলের শর্ত: ${fare!.cancellationPolicy}',
                        style: const TextStyle(fontSize: 13, color: _muted),
                      ),
                    ),
                  ],
                ),
              ],
              if (booking.canBeCancelled) ...<Widget>[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _cancelling ? null : _cancel,
                  icon: _cancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('বুকিং বাতিল করুন'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, color: _muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232823),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reason prompt shown before a booking is cancelled.
class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog();

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('বাতিলের কারণ'),
      content: TextField(
        controller: _reason,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'যেমন: পরিকল্পনা বদলে গেছে',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ফিরে যান'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
          child: const Text('বাতিল করুন'),
        ),
      ],
    );
  }
}
