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
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/fare_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/price_breakdown_sheet.dart';
import 'booking_checkout_screen.dart';

/// Search results for one [SearchQuery]: ranked fares, sorting and the
/// breakdown → checkout flow.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.query});

  final SearchQuery query;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  SearchResponse? _response;
  String? _error;
  bool _loading = true;
  ResultSort _sort = ResultSort.effectivePrice;

  /// Keeps the fares as they arrived so switching the sort never re-fetches.
  List<OptimizedFare> _items = const <OptimizedFare>[];

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final app = context.read<AppState>();
      final response = await app.searchService.search(widget.query);
      if (!mounted) return;
      setState(() {
        _response = response;
        _items = response.items;
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

  void _changeSort(ResultSort sort) {
    if (sort == _sort) return;
    setState(() {
      _sort = sort;
      _items = List<OptimizedFare>.of(_items)
        ..sort((a, b) {
          if (sort == ResultSort.duration) {
            return a.fare.durationMins.compareTo(b.fare.durationMins);
          }
          return a.price.effectivePrice.compareTo(b.price.effectivePrice);
        });
    });
  }

  Future<void> _openFare(OptimizedFare item) async {
    final selected = await PriceBreakdownSheet.show(context, item);
    if (selected == null || !mounted) return;
    final response = _response;
    if (response == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BookingCheckoutScreen(
          searchId: response.searchId,
          item: selected,
        ),
      ),
    );
  }

  String get _routeLabel =>
      '${widget.query.source} → ${widget.query.destination}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ফলাফল')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildHeader(theme),
            if (!_loading && _error == null) _buildSortBar(theme),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final cached = _response?.cached ?? false;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.route_outlined, size: 18, color: kBrandGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _routeLabel,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (cached)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kBrandGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ক্যাশ থেকে',
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
            '${formatDateWithWeekday(widget.query.travelDate)}'
            ' · ${widget.query.transportType.labelBn}'
            ' · ${widget.query.priority.labelBn}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B726B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar(ThemeData theme) {
    final count = _items.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              count == 0
                  ? 'কোনো ফলাফল নেই'
                  : '$count টি যাত্রা পাওয়া গেছে',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final sort in ResultSort.values)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: Text(sort.labelBn, style: const TextStyle(fontSize: 12.5)),
                selected: sort == _sort,
                onSelected: (_) => _changeSort(sort),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const LoadingView(message: 'সেরা ভাড়া খোঁজা হচ্ছে...');
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _search);
    }
    if (_items.isEmpty) {
      return const EmptyView(
        icon: Icons.search_off_outlined,
        title: 'এই রুটে কোনো টিকিট পাওয়া যায়নি',
        subtitle: 'তারিখ বা যানবাহন বদলে আবার চেষ্টা করুন।',
      );
    }
    return RefreshIndicator(
      onRefresh: _search,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return FareCard(item: item, onTap: () => _openFare(item));
        },
      ),
    );
  }
}
