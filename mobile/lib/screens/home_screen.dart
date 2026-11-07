import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../models/enums.dart';
import '../models/offer.dart';
import '../models/parsed_query.dart';
import '../models/search_query.dart';
import '../services/voice_service.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_view.dart';
import '../widgets/route_picker.dart';
import '../widgets/selectable_chip.dart';
import '../widgets/transport_type_chips.dart';
import '../widgets/voice_button.dart';
import 'booking_checkout_placeholder_removed.dart';
import 'my_bookings_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'results_screen.dart';

/// Top level shell: search / bookings / profile plus the notifications bell.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _titles = <String>[
    'টিকেটলি',
    'আমার বুকিং',
    'প্রোফাইল',
  ];

  int _index = 0;

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<AppState, int>((state) => state.unreadCount);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          IconButton(
            tooltip: 'নোটিফিকেশন',
            onPressed: _openNotifications,
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          _HomeTab(),
          MyBookingsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'খুঁজুন',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'বুকিং',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'প্রোফাইল',
          ),
        ],
      ),
    );
  }
}

/// Voice-first search plus the manual form and the offers strip.
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final TextEditingController _source = TextEditingController();
  final TextEditingController _destination = TextEditingController();
  final TextEditingController _budget = TextEditingController();
  final FocusNode _sourceFocus = FocusNode();
  final FocusNode _destinationFocus = FocusNode();

  VoiceButtonState _voiceState = VoiceButtonState.idle;
  ParsedQuery? _parsed;
  String? _sessionId;

  String _sourceValue = '';
  String _destinationValue = '';
  DateTime _travelDate = DateTime.now();
  TransportType _transportType = TransportType.all;
  SearchPriority _priority = SearchPriority.balanced;
  bool _searching = false;

  @override
  void dispose() {
    _source.dispose();
    _destination.dispose();
    _budget.dispose();
    _sourceFocus.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  double? get _budgetLimit {
    final text = _budget.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  // ---------------------------------------------------------------- voice ---

  Future<void> _startVoice() async {
    if (_voiceState != VoiceButtonState.idle) return;
    setState(() => _voiceState = VoiceButtonState.recording);
    final app = context.read<AppState>();
    try {
      await app.voiceService.startRecording();
    } catch (error) {
      if (!mounted) return;
      setState(() => _voiceState = VoiceButtonState.idle);
      showErrorSnack(context, error);
    }
  }

  Future<void> _stopVoice() async {
    if (_voiceState != VoiceButtonState.recording) return;
    setState(() => _voiceState = VoiceButtonState.processing);

    final app = context.read<AppState>();
    String? audio;
    try {
      audio = await app.voiceService.stopRecording();
    } catch (error) {
      if (!mounted) return;
      setState(() => _voiceState = VoiceButtonState.idle);
      showErrorSnack(context, error);
      return;
    }

    if (audio == null) {
      if (!mounted) return;
      setState(() => _voiceState = VoiceButtonState.idle);
      showInfoSnack(context, 'কোনো কথা শোনা যায়নি — আবার ধরে রেখে বলুন।');
      return;
    }

    try {
      final parsed = await app.searchService.parse(
        audioBase64: audio,
        contentType: VoiceService.contentType,
        sessionId: _sessionId,
      );
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _voiceState = VoiceButtonState.idle;
        _parsed = parsed;
        _sessionId = parsed.sessionId ?? _sessionId;
      });
      _applyParsedQuery(parsed);
      if (_sourceValue.isNotEmpty && _destinationValue.isNotEmpty) {
        await _runSearch();
      } else {
        showInfoSnack(
          context,
          'শুনতে পেরেছি, তবে শহর বুঝতে পারিনি — নিচে হাতে লিখুন।',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _voiceState = VoiceButtonState.idle);
      showErrorSnack(context, error);
    }
  }

  void _applyParsedQuery(ParsedQuery parsed) {
    if (parsed.source != null) {
      _sourceValue = parsed.source!;
      _source.text = parsed.source!;
    }
    if (parsed.destination != null) {
      _destinationValue = parsed.destination!;
      _destination.text = parsed.destination!;
    }
    if (parsed.travelDate != null) _travelDate = parsed.travelDate!;
    _transportType = parsed.transportType;
    _priority = parsed.priority;
    if (parsed.budgetLimit != null) {
      _budget.text = formatNumber(parsed.budgetLimit!);
    }
    setState(() {});
  }

  // ---------------------------------------------------------------- form ---

  void _swapRoute() {
    setState(() {
      final from = _sourceValue;
      _sourceValue = _destinationValue;
      _destinationValue = from;
      _source.text = _destination.text;
      _destination.text = from == '' ? _source.text : from;
      _source.text = _sourceValue;
      _destination.text = _destinationValue;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _travelDate.isBefore(today) ? today : _travelDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
    );
    if (picked == null || !mounted) return;
    setState(() => _travelDate = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _runSearch() async {
    final source = _sourceValue.trim();
    final destination = _destinationValue.trim();
    if (source.isEmpty || destination.isEmpty) {
      showInfoSnack(context, 'যাত্রার শুরু ও গন্তব্য — দুটি শহরই দিন।');
      return;
    }
    if (source == destination) {
      showInfoSnack(context, 'শুরু ও গন্তব্য এক হতে পারে না।');
      return;
    }

    final query = SearchQuery(
      source: source,
      destination: destination,
      travelDate: _travelDate,
      transportType: _transportType,
      priority: _priority,
      budgetLimit: _budgetLimit,
      sessionId: _sessionId,
    );

    setState(() => _searching = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ResultsScreen(query: query),
        ),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // -------------------------------------------------------------- widgets ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppState>();

    return RefreshIndicator(
      onRefresh: () => app.refreshOffers(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildVoiceCard(theme),
            if (_parsed != null) ...<Widget>[
              const SizedBox(height: 14),
              _buildParsedSummary(theme, _parsed!),
            ],
            const SizedBox(height: 18),
            _buildFormCard(theme),
            const SizedBox(height: 20),
            _buildOffersSection(theme, app),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Column(
          children: <Widget>[
            Text(
              'কীভাবে যেতে চান বলুন',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'যেমন: “আগামী শুক্রবার ঢাকা থেকে খুলনার সবচেয়ে কম ভাড়ার টিকিট দেখাও”',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFF6B726B)),
            ),
            const SizedBox(height: 18),
            VoiceButton(
              state: _voiceState,
              onStart: _startVoice,
              onStop: _stopVoice,
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _voiceState == VoiceButtonState.idle
                  ? () => setState(() => _parsed = null)
                  : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('কিছু লিখেই খুঁজতে পারেন'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParsedSummary(ThemeData theme, ParsedQuery parsed) {
    final heard = parsed.transcript ?? parsed.text;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.graphic_eq, size: 18, color: kBrandGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'শোনা হয়েছে: “${heard ?? '—'}”',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${formatNumber(parsed.confidence * 100)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kBrandGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    parsed.intent.labelBn,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                for (final term in parsed.detectedTerms)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(term, style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'নিজে খুঁজে দেখুন',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            RoutePicker(
              sourceController: _source,
              sourceFocusNode: _sourceFocus,
              destinationController: _destination,
              destinationFocusNode: _destinationFocus,
              onSourceChanged: (value) => _sourceValue = value,
              onDestinationChanged: (value) => _destinationValue = value,
              onSwap: _swapRoute,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'যাত্রার তারিখ',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(formatDateWithWeekday(_travelDate)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'যানবাহন',
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF4A524A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TransportTypeChips(
              selected: _transportType,
              onChanged: (value) => setState(() => _transportType = value),
            ),
            const SizedBox(height: 16),
            Text(
              'অগ্রাধিকার',
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF4A524A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final priority in SearchPriority.values)
                  SelectableChip(
                    label: priority.labelBn,
                    selected: priority == _priority,
                    onTap: () => setState(() => _priority = priority),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _budget,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'বাজেট (ঐচ্ছিক)',
                hintText: 'সর্বোচ্চ কত টাকা',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _searching || _voiceState != VoiceButtonState.idle
                  ? null
                  : _runSearch,
              icon: _searching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: const Text('টিকিট খুঁজুন'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection(ThemeData theme, AppState app) {
    final offers = app.offers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'চলতি অফার ও ক্যাশব্যাক',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (app.offersLoading && offers.isEmpty)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (offers.isEmpty && app.offersError != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.cloud_off_outlined,
                      size: 20, color: Color(0xFF6B726B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      app.offersError!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B726B),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'আবার চেষ্টা করুন',
                    onPressed: () => app.refreshOffers(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          )
        else if (offers.isEmpty && !app.offersLoading)
          const EmptyView(
            icon: Icons.local_offer_outlined,
            title: 'এখন কোনো অফার নেই',
            subtitle: 'নতুন অফার এলে এখানে দেখাবে।',
          )
        else
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: offers.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _OfferCard(
                offer: offers[index],
              ),
            ),
          ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({super.key, required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payments = offer.paymentMethods.join(', ');
    return SizedBox(
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.savings_outlined,
                      size: 18, color: kSavingsColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: kSavingsColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer.cashbackLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: kSavingsColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                offer.provider == null
                    ? 'টিকেটলি'
                    : 'প্রোভাইডার: ${offer.provider}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF6B726B)),
              ),
              const Spacer(),
              Text(
                payments.isEmpty ? 'সব পেমেন্ট' : payments,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF6B726B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
