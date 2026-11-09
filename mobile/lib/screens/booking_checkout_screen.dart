import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../models/enums.dart';
import '../models/optimized_fare.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/app_snackbar.dart';
import 'booking_detail_screen.dart';

/// Passenger details + payment: turns one fare into a booking.
class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({
    super.key,
    required this.searchId,
    required this.item,
  });

  final String searchId;
  final OptimizedFare item;

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _promo = TextEditingController();
  final TextEditingController _cardLast4 = TextEditingController();

  int _quantity = 1;
  PaymentMethod _paymentMethod = PaymentMethod.mfs;
  String _mfsProvider = mfsProviders.first;
  bool _submitting = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    // Prefill from the profile so most bookings are two taps.
    final user = context.read<AppState>().user;
    if (user != null) {
      _name.text = user.name;
      _phone.text = user.phone;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _promo.dispose();
    _cardLast4.dispose();
    super.dispose();
  }

  double get _unitPrice => widget.item.price.effectivePrice;

  double get _total => _unitPrice * _quantity;

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_paymentMethod == PaymentMethod.card &&
        _cardLast4.text.trim().length != 4) {
      setState(() => _formError = 'কার্ডের শেষ ৪ সংখ্যা দিন।');
      return;
    }

    setState(() => _submitting = true);
    final app = context.read<AppState>();
    try {
      final booking = await app.bookingService.create(
        searchId: widget.searchId,
        fare: widget.item.fare,
        passengerName: _name.text,
        passengerPhone: _phone.text,
        quantity: _quantity,
        paymentMethod: _paymentMethod.wire,
        mfsProvider:
            _paymentMethod == PaymentMethod.mfs ? _mfsProvider : null,
        cardLast4:
            _paymentMethod == PaymentMethod.card ? _cardLast4.text.trim() : null,
        promoCode: _promo.text,
      );
      if (!mounted) return;
      showSuccessSnack(context, 'বুকিং হয়ে গেছে — PNR ${booking.pnr}');
      // Show the ticket, dropping the checkout and results off the stack.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (context) => BookingDetailScreen(booking: booking),
        ),
        (route) => route.isFirst,
      );
    } catch (caught) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _formError = errorMessageOf(caught);
      });
    }
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'যাত্রীর নাম দিন';
    return null;
  }

  String? _validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'মোবাইল নম্বর দিন';
    if (!RegExp(r'^01\d{9}$').hasMatch(text)) {
      return '১১ সংখ্যার মোবাইল নম্বর দিন (শুরু 01)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('বুকিং নিশ্চিত করুন')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildFareSummary(theme),
                const SizedBox(height: 16),
                _buildPassengerCard(theme),
                const SizedBox(height: 16),
                _buildPaymentCard(theme),
                if (_formError != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _buildFormError(),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(
                    _submitting
                        ? 'পেমেন্ট হচ্ছে...'
                        : '৳${formatNumber(_total)} পে করে বুক করুন',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'ডেমো পেমেন্ট গেটওয়ে — কোনো আসল টাকা কাটা হবে না।',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF6B726B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFareSummary(ThemeData theme) {
    final fare = widget.item.fare;
    final price = widget.item.price;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.directions_transit,
                    size: 18, color: kBrandGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${fare.source} → ${fare.destination}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (widget.item.badge != null &&
                    widget.item.badge!.isNotEmpty)
                  Text(
                    widget.item.badge!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kSavingsColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${fare.provider} · ${fare.departTime ?? '--:--'} → '
              '${fare.arriveTime ?? '--:--'} · ${formatDuration(fare.durationMins)}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B726B)),
            ),
            if (fare.travelDate != null)
              Text(
                formatDate(fare.travelDate!),
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B726B)),
              ),
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('কার্যকর ভাড়া (প্রতি জন)',
                    style: TextStyle(fontSize: 14)),
                Text(
                  formatBdt(price.effectivePrice),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kBrandGreen,
                  ),
                ),
              ],
            ),
            if (price.hasSavings) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'আপনি সাশ্রয় করছেন '
                '${formatBdt(price.computedSavedAmount * _quantity)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kSavingsColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'যাত্রীর তথ্য',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'পুরো নাম',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: const InputDecoration(
                labelText: 'মোবাইল নম্বর',
                hintText: '01XXXXXXXXX',
                prefixIcon: Icon(Icons.phone_iphone),
                counterText: '',
              ),
              validator: _validatePhone,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text('কতজনের টিকিট',
                      style: TextStyle(fontSize: 14.5)),
                ),
                IconButton(
                  tooltip: 'কমান',
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  tooltip: 'বাড়ান',
                  onPressed: _quantity < 6
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'পেমেন্ট',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SegmentedButton<PaymentMethod>(
              segments: <ButtonSegment<PaymentMethod>>[
                for (final method in PaymentMethod.values)
                  ButtonSegment<PaymentMethod>(
                    value: method,
                    label: Text(method.labelBn),
                    icon: Icon(method == PaymentMethod.mfs
                        ? Icons.account_balance_wallet_outlined
                        : Icons.credit_card),
                  ),
              ],
              selected: <PaymentMethod>{_paymentMethod},
              onSelectionChanged: (selection) =>
                  setState(() => _paymentMethod = selection.first),
            ),
            const SizedBox(height: 14),
            if (_paymentMethod == PaymentMethod.mfs) ...<Widget>[
              Text(
                'কোন MFS দিয়ে পে করবেন?',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: const Color(0xFF4A524A)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final provider in mfsProviders)
                    ChoiceChip(
                      label: Text(provider),
                      selected: provider == _mfsProvider,
                      onSelected: (_) =>
                          setState(() => _mfsProvider = provider),
                    ),
                ],
              ),
            ] else ...<Widget>[
              TextFormField(
                controller: _cardLast4,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'কার্ডের শেষ ৪ সংখ্যা',
                  hintText: '1234',
                  prefixIcon: Icon(Icons.credit_card),
                  counterText: '',
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _promo,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'প্রোমো কোড (ঐচ্ছিক)',
                hintText: 'যেমন SAVE10',
                prefixIcon: Icon(Icons.local_offer_outlined),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'সর্বমোট ($_quantity জন)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatBdt(_total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kBrandGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0B4B4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 18, color: kBrandRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formError!,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF8C1D18)),
            ),
          ),
        ],
      ),
    );
  }
}
