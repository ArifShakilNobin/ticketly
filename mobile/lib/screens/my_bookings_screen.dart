import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/booking_card.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import 'booking_detail_screen.dart';

/// The passenger's bookings, newest first. Embedded in the home shell, so it
/// renders no Scaffold of its own.
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final app = context.read<AppState>();
      final items = await app.bookingService.list();
      if (!mounted) return;
      setState(() {
        _bookings = items;
        _loading = false;
      });
    } catch (caught) {
      if (!mounted) return;
      setState(() {
        _error = errorMessageOf(caught);
        _loading = false;
      });
    }
  }

  Future<void> _open(Booking booking) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BookingDetailScreen(booking: booking),
      ),
    );
    // Returning from a cancellation should show the new status.
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _bookings.isEmpty) {
      return const LoadingView(message: 'বুকিং খোঁজা হচ্ছে...');
    }
    if (_error != null && _bookings.isEmpty) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_bookings.isEmpty) {
      return const EmptyView(
        icon: Icons.confirmation_number_outlined,
        title: 'এখনো কোনো বুকিং নেই',
        subtitle: 'খুঁজে টিকিট বুক করলে এখানে দেখা যাবে।',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return BookingCard(
            booking: booking,
            onTap: () => _open(booking),
          );
        },
      ),
    );
  }
}
