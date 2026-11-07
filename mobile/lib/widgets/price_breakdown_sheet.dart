import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/optimized_fare.dart';
import '../utils/format.dart';

/// Bottom sheet that expands a fare into: base - cashback - promo + fee.
///
/// Pops with the [OptimizedFare] when the passenger taps "বুক করুন".
class PriceBreakdownSheet extends StatelessWidget {
  const PriceBreakdownSheet({super.key, required this.item});

  final OptimizedFare item;

  static Future<OptimizedFare?> show(BuildContext context, OptimizedFare fare) {
    return showModalBottomSheet<OptimizedFare>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PriceBreakdownSheet(item: fare),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fare = item.fare;
    final price = item.price;
    final badge = item.badge;

    Widget line(
      String label,
      String value, {
      Color? valueColor,
      bool striked = false,
      bool emphasised = false,
    }) {
      final style = emphasised
          ? const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101410),
            )
          : TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color:
                  striked ? const Color(0xFF6B726B) : const Color(0xFF232823),
              decoration: striked ? TextDecoration.lineThrough : null,
            );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: Text(label, style: style)),
            Text(
              value,
              style: style.copyWith(color: valueColor ?? style.color),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                      'ভাড়ার বিস্তারিত',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (badge != null && badge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kSavingsColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kSavingsColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${fare.source} → ${fare.destination} · ${fare.transportType.labelBn}'
                '${fare.travelDate == null ? '' : ' · ${formatDate(fare.travelDate!)}'}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: const Color(0xFF6B726B)),
              ),
              const SizedBox(height: 12),
              Text(
                fare.provider.isEmpty
                    ? fare.transportType.labelBn
                    : fare.provider,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${fare.departTime ?? '--:--'} → ${fare.arriveTime ?? '--:--'}'
                ' · ${formatDuration(fare.durationMins)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: const Color(0xFF6B726B)),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              line('আসল ভাড়া', formatBdt(price.baseFare)),
              line(
                'MFS ক্যাশব্যাক',
                '- ${formatBdt(price.mfsCashback)}',
                valueColor: kSavingsColor,
              ),
              line(
                'প্রোমো ছাড়',
                '- ${formatBdt(price.promoDiscount)}',
                valueColor: kSavingsColor,
              ),
              line('সুবিধা ফি', '+ ${formatBdt(price.convenienceFee)}'),
              const Divider(height: 1),
              line(
                'কার্যকর মূল্য',
                formatBdt(price.effectivePrice),
                emphasised: true,
              ),
              if (price.hasSavings)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kSavingsColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'আপনি সাশ্রয় করছেন ${formatBdt(price.computedSavedAmount)}',
                    style: const TextStyle(
                      color: kSavingsColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (item.appliedOffers.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                Text(
                  'প্রযোজ্য অফার',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final offer in item.appliedOffers)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(offer, style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
              if (fare.cancellationPolicy != null) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.rule_outlined,
                      size: 16,
                      color: Color(0xFF6B726B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'বাতিলের শর্ত: ${fare.cancellationPolicy}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B726B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(item),
                icon: const Icon(Icons.confirmation_number_outlined),
                label: const Text('বুক করুন / Book now'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
