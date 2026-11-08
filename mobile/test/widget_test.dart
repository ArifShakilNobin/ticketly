import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ticketly/models/enums.dart';
import 'package:ticketly/models/price_breakdown.dart';
import 'package:ticketly/utils/format.dart';
import 'package:ticketly/utils/ui.dart';

void main() {
  group('BookingStatus', () {
    test('reads the value the backend sends', () {
      expect(BookingStatus.fromWire('CONFIRMED'), BookingStatus.confirmed);
      expect(BookingStatus.fromWire('cancelled'), BookingStatus.cancelled);
    });

    test('falls back to pending for anything unknown', () {
      expect(BookingStatus.fromWire('SOMETHING_ELSE'), BookingStatus.pending);
      expect(BookingStatus.fromWire(null), BookingStatus.pending);
      expect(BookingStatus.fromWire('  '), BookingStatus.pending);
    });
  });

  group('PaymentMethod', () {
    test('maps the wire values', () {
      expect(PaymentMethod.fromWire('MFS'), PaymentMethod.mfs);
      expect(PaymentMethod.fromWire('CARD'), PaymentMethod.card);
      expect(PaymentMethod.fromWire('cash'), PaymentMethod.mfs);
    });
  });

  group('transportTypeIcon', () {
    test('gives every transport mode its own icon', () {
      expect(transportTypeIcon(TransportType.train), Icons.train);
      expect(transportTypeIcon(TransportType.bus), Icons.directions_bus);
      expect(transportTypeIcon(TransportType.launch), Icons.directions_boat);
      expect(transportTypeIcon(TransportType.flight), Icons.flight);
      expect(transportTypeIcon(TransportType.all), Icons.alt_route);
    });
  });

  group('PriceBreakdown', () {
    test('computes the saving from the formula when the server sent none', () {
      const price = PriceBreakdown(
        baseFare: 750,
        convenienceFee: 20,
        effectivePrice: 732.50,
      );
      expect(price.computedSavedAmount, closeTo(37.50, 0.001));
      expect(price.hasSavings, isTrue);
      expect(price.totalDiscount, 0);
    });

    test('prefers the amount the backend computed', () {
      const price = PriceBreakdown(
        baseFare: 100,
        effectivePrice: 90,
        savedAmount: 10,
      );
      expect(price.computedSavedAmount, 10);
      expect(price.hasSavings, isTrue);
    });

    test('reports no saving when nothing was discounted', () {
      const price = PriceBreakdown(
        baseFare: 750,
        convenienceFee: 20,
        effectivePrice: 770,
      );
      expect(price.hasSavings, isFalse);
      expect(price.computedSavedAmount, 0);
    });
  });

  group('formatDuration', () {
    test('renders Bengali durations', () {
      expect(formatDuration(0), '—');
      expect(formatDuration(45), '45 মিনিট');
      expect(formatDuration(120), '2 ঘণ্টা');
      expect(formatDuration(375), '6 ঘ 15 মিনিট');
    });
  });

  group('formatBdt', () {
    test('always writes the Taka symbol', () {
      expect(formatBdt(750), contains('৳'));
      expect(formatBdt(732.5), contains('৳'));
    });
  });
}
