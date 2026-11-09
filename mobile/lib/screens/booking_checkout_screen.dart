import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../models/booking.dart';
import '../models/enums.dart';
import '../models/optimized_fare.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../utils/ui.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/booking_status_chip.dart';
import '../widgets/selectable_chip.dart';
import 'home_screen.dart';

/// Collects the passenger, payment and promo details for one fare and books
/// it through `POST /api/v1/bookings`.
class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({
    super.key,
    required this.searchId,
    required this.item,
  });

  /// Reference of the search that produced [item].
  final String searchId;

  final OptimizedFare item;

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  static const Color _muted = Color(0xFF6B726B);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passengerName = TextEditingController();
  final TextEditingController _passengerPhone = TextEditingController();
  final TextEditingController _cardLast4 = TextEditingController();
  final TextEditingController _promoCode = TextEditingController();

  PaymentMethod _method = PaymentMethod.mfs;
  String _mfsProvider = mfsProviders.first;
  int _quantity = 1;
  bool _submitting = false;

  /// Set once `POST /api/v1/bookings` answered; the screen then switches to
  /// the confirmation view.
  Booking? _booking;

  @override
  void initState() {
    super.initState();
    // The signed-in passenger is the default traveller.
    final user = context.read<AppState>().user;
    if (user != null) {
      if (user.name.isNotEmpty) _passengerName.text = user.name;
      if (user.phone.isNotEmpty) _passengerPhone.text = user.phone;
    }
  }

  @override
  void dispose() {
    _passengerName.dispose();
    _passengerPhone.dispose();
    _cardLast4.dispose();
    _promoCode.dispose();
    super.dispose();
  }

  double get _unitPrice => widget.item.price.effectivePrice;

  double get _total => _unitPrice * _quantity;

  /// Never ask for more seats than the provider says are available.
  int get _maxQuantity {
    final seats = widget.item.fare.seatsAvailable;
    if (seats <= 0) return 10;
    return seats < 10 ? seats : 10;
  }

  // ----------------------------------------------------------- validation ---

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'যাত্রীর নাম দিন';
    return null;
  }

  String? _validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (!RegExp(r'^01\d{9}$').hasMatch(text)) {
      return '১১ সংখ্যার মোবাইল নম্বর দিন (শুরু 01)';
    }
    return null;
  }

  String? _validateCard(String? value) {
    if (!RegExp(r'^\d{4}$').hasMatch((value ?? '').trim())) {
      return 'কার্ডের শেষ ৪ সংখ্যা দিন';
    }
    return null;
  }

  // -------------------------------------------------------------- booking ---

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final app = context.read<AppState>();
    try {
      final booking = await app.bookingService.create(
        searchId: widget.searchId,
        fare: widget.item.fare,
        passengerName: _passengerName.text.trim(),
        passengerPhone: _passengerPhone.text.trim(),
        quantity: _quantity,
        paymentMethod: _method.wire,
        mfsProvider: _method == PaymentMethod.mfs ? _mfsProvider : null,
        cardLast4: _method == PaymentMethod.card
            ? _cardLast4.text.trim()
            : null,
        promoCode: _promoCode.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _submitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showErrorSnack(context, error);
    }
  }

  void _goHome(int tab) {
    homeTabIndex.value = tab;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // -------------------------------------------------------------- widgets ---

  Widget _buildJourneyCard(ThemeData theme) {
    final fare = widget.item.fare;
    final price = widget.item.price;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                    fare.provider.isEmpty
                        ? fare.transportType.labelBn
                        : fare.provider,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (widget.item.badge != null && widget.item.badge!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kSavingsColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.item.badge!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: kSavingsColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${fare.source} → ${fare.destination}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232823),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${fare.travelDate == null ? '' : '${formatDateWithWeekday(fare.travelDate!)} · '}'
              '${fare.departTime ?? '--:--'} → ${fare.arriveTime ?? '--:--'}'
              '${fare.vehicleClass == null ? '' : ' · ${fare.vehicleClass}'}',
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'কার্যকর ভাড়া',
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ),
                Text(
                  formatBdt(price.effectivePrice),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: kBrandGreen,
                  ),
                ),
              ],
            ),
            if (price.hasSavings)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${formatBdt(price.computedSavedAmount)} সাশ্রয় হচ্ছে',
                  style: const TextStyle(
                    fontSize: 12.5,
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

  Widget _buildSectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildPassengerCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSectionTitle(theme, 'যাত্রীর তথ্য'),
            TextFormField(
              controller: _passengerName,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'নাম',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passengerPhone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'মোবাইল নম্বর',
                hintText: '01XXXXXXXXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: _validatePhone,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'যাত্রী সংখ্যা',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A524A),
                    ),
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'কমান',
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity -= 1)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'বাড়ান',
                  onPressed: _quantity < _maxQuantity
                      ? () => setState(() => _quantity += 1)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (widget.item.fare.seatsAvailable > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'সর্বোচ্চ ${widget.item.fare.seatsAvailable} টি আসন আছে',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSectionTitle(theme, 'পেমেন্ট'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final method in PaymentMethod.values)
                  SelectableChip(
                    label: method.labelBn,
                    selected: _method == method,
                    onTap: () => setState(() => _method = method),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (_method == PaymentMethod.mfs) ...<Widget>[
              const Text(
                'কোন ওয়ালেট দিয়ে পরিশোধ করবেন?',
                style: TextStyle(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final provider in mfsProviders)
                    SelectableChip(
                      label: provider,
                      selected: _mfsProvider == provider,
                      onTap: () => setState(() => _mfsProvider = provider),
                    ),
                ],
              ),
            ] else ...<Widget>[
              TextFormField(
                controller: _cardLast4,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  labelText: 'কার্ডের শেষ ৪ সংখ্যা',
                  hintText: '1234',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: _validateCard,
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _promoCode,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'প্রোমো কোড (ঐচ্ছিক)',
                hintText: 'যেমন: EIDSALE',
                prefixIcon: Icon(Icons.local_offer_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSectionTitle(theme, 'মূল্য'),
            _summaryLine(
              'কার্যকর ভাড়া × $_quantity',
              formatBdt(_unitPrice * _quantity),
            ),
            if (widget.item.price.convenienceFee > 0)
              _summaryLine(
                'সুবিধা ফি (প্রতি টিকিট)',
                '+ ${formatBdt(widget.item.price.convenienceFee)}',
              ),
            const Divider(height: 18),
            _summaryLine('সর্বমোট', formatBdt(_total), emphasised: true),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(
                _submitting ? 'পেমেন্ট হচ্ছে...' : 'পেমেন্ট করে বুক করুন',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'নিশ্চিত হলে বুকিংয়ের PNR পাবেন। এটি একটি ডেমো পেমেন্ট গেটওয়ে।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(String label, String value, {bool emphasised = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasised ? 16 : 14,
                fontWeight: emphasised ? FontWeight.w800 : FontWeight.w500,
                color: emphasised
                    ? const Color(0xFF101410)
                    : const Color(0xFF232823),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasised ? 21 : 14,
              fontWeight: FontWeight.w800,
              color: emphasised ? kBrandGreen : const Color(0xFF232823),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- confirmation ---

  Widget _buildResult(ThemeData theme, Booking booking) {
    final fare = booking.fare;
    final confirmed = booking.isSuccessful;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      children: <Widget>[
        Icon(
          bookingStatusIcon(booking.status),
          size: 64,
          color: bookingStatusColor(booking.status),
        ),
        const SizedBox(height: 12),
        Text(
          confirmed
              ? 'বুকিং সফল হয়েছে'
              : booking.status == BookingStatus.failed
              ? 'পেমেন্ট সম্পন্ন হয়নি'
              : booking.status.labelBn,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (booking.pnr.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            'PNR: ${booking.pnr}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kBrandGreen,
            ),
          ),
        ],
        if (booking.failureReason != null) ...<Widget>[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF0B4B4)),
            ),
            child: Text(
              booking.failureReason!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF8E2020)),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        fare == null
                            ? 'রুট তথ্য নেই'
                            : '${fare.source} → ${fare.destination}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    BookingStatusChip(status: booking.status),
                  ],
                ),
                if (fare?.travelDate != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    formatDateWithWeekday(fare!.travelDate!),
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ],
                const Divider(height: 22),
                _resultRow(
                  'যাত্রী',
                  '${booking.passengerName} · ${booking.quantity} জন',
                ),
                _resultRow('মোবাইল', booking.passengerPhone),
                _resultRow(
                  'পেমেন্ট',
                  booking.paymentMethod == PaymentMethod.mfs
                      ? 'MFS${booking.mfsProvider == null ? '' : ' · ${booking.mfsProvider}'}'
                      : 'কার্ড${booking.transactionId == null ? '' : ' · ${booking.transactionId}'}',
                ),
                _resultRow('মোট পরিশোধিত', formatBdt(booking.totalPaid)),
                if (booking.createdAt != null)
                  _resultRow('সময়', formatDateTime(booking.createdAt!)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        if (confirmed)
          FilledButton.icon(
            onPressed: () => _goHome(1),
            icon: const Icon(Icons.confirmation_number_outlined),
            label: const Text('আমার বুকিং দেখুন'),
          )
        else
          FilledButton.icon(
            onPressed: () => setState(() => _booking = null),
            icon: const Icon(Icons.refresh),
            label: const Text('আবার চেষ্টা করুন'),
          ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => _goHome(0),
          child: const Text('নতুন খোঁজ করুন'),
        ),
      ],
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 116,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = _booking;

    return Scaffold(
      appBar: AppBar(title: const Text('বুকিং নিশ্চিত করুন')),
      body: booking != null
          ? _buildResult(theme, booking)
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: <Widget>[
                  _buildJourneyCard(theme),
                  const SizedBox(height: 14),
                  _buildPassengerCard(theme),
                  const SizedBox(height: 14),
                  _buildPaymentCard(theme),
                  const SizedBox(height: 14),
                  _buildSummary(theme),
                ],
              ),
            ),
    );
  }
}
