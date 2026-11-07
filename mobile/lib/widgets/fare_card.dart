import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/optimized_fare.dart';
import '../utils/format.dart';
import '../utils/ui.dart';

/// One search result. The effective price is the hero: the original fare is
/// shown struck through, the saving is called out and the discount breakdown
/// is one tap away.
class FareCard extends StatelessWidget {
  const FareCard({super.key, required this.item, this.onTap});

  final OptimizedFare item;
  final VoidCallback? onTap;

  static const Color _muted = Color(0xFF6B726B);

  @override
  Widget build(BuildContext context) {
    final fare = item.fare;
    final price = item.price;
    final badge = item.badge;
    final theme = Theme.of(context);

    Widget timeBlock(String? time, String caption, CrossAxisAlignment align) {
      return Column(
        crossAxisAlignment: align,
        children: <Widget>[
          Text(
            time ?? '--:--',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(
            caption,
            style: const TextStyle(fontSize: 11.5, color: _muted),
          ),
        ],
      );
    }

    Widget metaLine(IconData icon, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ),
        ],
      );
    }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kBrandGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      transportTypeIcon(fare.transportType),
                      color: kBrandGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                fare.provider.isEmpty
                                    ? fare.transportType.labelBn
                                    : fare.provider,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (fare.vehicleClass != null) ...<Widget>[
                              const SizedBox(width: 6),
                              Text(
                                fare.vehicleClass!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fare.source} → ${fare.destination}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null && badge.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 8),
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
                        badge,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: kSavingsColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  timeBlock(
                    fare.departTime,
                    'ছাড়',
                    CrossAxisAlignment.start,
                  ),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Expanded(
                              child: SizedBox(
                                height: 1,
                                child: ColoredBox(color: Color(0xFFDDE2DC)),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.arrow_right_alt,
                                size: 18,
                                color: _muted,
                              ),
                            ),
                            const Expanded(
                              child: SizedBox(
                                height: 1,
                                child: ColoredBox(color: Color(0xFFDDE2DC)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDuration(fare.durationMins),
                          style: const TextStyle(
                            fontSize: 12,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  timeBlock(
                    fare.arriveTime,
                    'পৌঁছা',
                    CrossAxisAlignment.end,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: <Widget>[
                  if (fare.seatsAvailable > 0)
                    metaLine(
                      Icons.event_seat_outlined,
                      '${fare.seatsAvailable} টি আসন আছে',
                    ),
                  if (fare.cancellationPolicy != null)
                    metaLine(Icons.rule_outlined, fare.cancellationPolicy!),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (price.hasSavings)
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
                              '${formatBdt(price.computedSavedAmount)} সাশ্রয়',
                              style: const TextStyle(
                                fontSize: 13,
                                color: kSavingsColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (item.appliedOffers.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            'অফার: ${item.appliedOffers.join(', ')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      if (price.baseFare > price.effectivePrice)
                        Text(
                          formatBdt(price.baseFare),
                          style: const TextStyle(
                            fontSize: 14,
                            color: _muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        formatBdt(price.effectivePrice),
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: kBrandGreen,
                        ),
                      ),
                      const Text(
                        'কার্যকর ভাড়া',
                        style: TextStyle(fontSize: 11.5, color: _muted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'ভাড়ার বিস্তারিত দেখুন',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: kBrandGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.expand_more, size: 20, color: kBrandGreen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
