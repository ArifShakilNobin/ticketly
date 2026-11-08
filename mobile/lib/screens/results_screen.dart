import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../models/enums.dart';
import '../models/optimized_fare.dart';
import '../models/search_query.dart';
import '../models/search_response.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../utils/ui.dart' show transportTypeIcon;
import '../widgets/app_snackbar.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/fare_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/price_breakdown_sheet.dart';
import '../widgets/selectable_chip.dart';
import 'booking_checkout_screen.dart';

/// Runs `POST /api/v1/search` for [query] and lists the optimised fares.
///
/// Tapping a fare expands the price breakdown; confirming it there hands the
/// fare over to the [BookingCheckoutScreen].
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.query});

  final SearchQuery query;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  SearchResponse? _response;
  bool _loading = true;
  String? _error;
  ResultSort _sort = ResultSort.effectivePrice;

  @override
  void initState() {
    super.initState();
    // The first build has to finish before any state is touched: the search
    // notifies listeners as soon as it starts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _search();
    });
  }

  Future<void> _search() async {
    final app = context.read<AppState>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await app.searchService.search(widget.query);
      if (!mounted) return;
      setState(() {
        _response = response;
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

  /// The current result set in the order the selected [ResultSort] asks for.
  List<OptimizedFare> get _sortedItems {
    final items = List<OptimizedFare>.of(
      _response?.items ?? const <OptimizedFare>[],
    );
    if (_sort == ResultSort.effectivePrice) {
      items.sort(
        (a, b) => a.price.effectivePrice.compareTo(b.price.effectivePrice),
      );
    } else {
      items.sort((a, b) => a.fare.durationMins.compareTo(b.fare.durationMins));
    }
    return items;
  }

  Future<void> _openFare(OptimizedFare item) async {
    final chosen = await PriceBreakdownSheet.show(context, item);
    if (chosen == null || !mounted) return;

    final searchId = _response?.searchId;
    if (searchId == null || searchId.isEmpty) {
      showInfoSnack(context, 'সার্চের রেফারেন্স পাওয়া যায়নি — আবার খুঁজুন।');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            BookingCheckoutScreen(searchId: searchId, item: chosen),
      ),
    );
  }

  // -------------------------------------------------------------- widgets ---

  Widget _buildHeader(ThemeData theme) {
    final response = _response;
    if (response == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  transportTypeIcon(response.transportType),
                  size: 20,
                  color: kBrandGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${response.source} → ${response.destination}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (response.cached)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kBrandGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ক্যাশ',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: kBrandGreen,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${formatDate(response.travelDate ?? widget.query.travelDate)}'
              ' · ${response.totalFound} টি ফলাফল',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B726B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortRow() {
    return Row(
      children: <Widget>[
        for (final sort in ResultSort.values) ...<Widget>[
          SelectableChip(
            label: sort.labelBn,
            selected: _sort == sort,
            onTap: () => setState(() => _sort = sort),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _sortedItems;

    final Widget body;
    if (_loading) {
      body = const LoadingView(message: 'সবচেয়ে কম ভাড়া খোঁজা হচ্ছে...');
    } else if (_error != null) {
      body = ErrorView(message: _error!, onRetry: _search);
    } else if (items.isEmpty) {
      body = const EmptyView(
        icon: Icons.search_off,
        title: 'এই রুটে কোনো টিকিট পাওয়া যায়নি',
        subtitle: 'তারিখ বা যানবাহন বদলে আবার চেষ্টা করুন।',
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          _buildHeader(theme),
          const SizedBox(height: 14),
          _buildSortRow(),
          const SizedBox(height: 12),
          for (final item in items) ...<Widget>[
            FareCard(item: item, onTap: () => _openFare(item)),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.query.source} → ${widget.query.destination}'),
      ),
      body: RefreshIndicator(onRefresh: _search, child: body),
    );
  }
}
