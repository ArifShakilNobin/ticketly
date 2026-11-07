import '../utils/json_read.dart';

/// Effective price = base fare - MFS cashback - promo discount + convenience
/// fee. All amounts are in Bangladeshi Taka.
class PriceBreakdown {
  const PriceBreakdown({
    this.baseFare = 0,
    this.mfsCashback = 0,
    this.promoDiscount = 0,
    this.convenienceFee = 0,
    this.effectivePrice = 0,
    this.savedAmount = 0,
  });

  final double baseFare;
  final double mfsCashback;
  final double promoDiscount;
  final double convenienceFee;
  final double effectivePrice;
  final double savedAmount;

  factory PriceBreakdown.fromJson(Map<String, dynamic>? json) {
    final data = asMap(json);
    final base = doubleOr(data['baseFare'], 0);
    final saved = doubleOr(data['savedAmount'], 0);
    return PriceBreakdown(
      baseFare: base,
      mfsCashback: doubleOr(data['mfsCashback'], 0),
      promoDiscount: doubleOr(data['promoDiscount'], 0),
      convenienceFee: doubleOr(data['convenienceFee'], 0),
      effectivePrice: doubleOr(data['effectivePrice'], base),
      savedAmount: saved,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'baseFare': baseFare,
        'mfsCashback': mfsCashback,
        'promoDiscount': promoDiscount,
        'convenienceFee': convenienceFee,
        'effectivePrice': effectivePrice,
        'savedAmount': savedAmount,
      };

  /// Total of every discount line, whether or not the backend computed
  /// [savedAmount] for us.
  double get totalDiscount => mfsCashback + promoDiscount;

  double get computedSavedAmount {
    if (savedAmount > 0) return savedAmount;
    final byFormula = baseFare + convenienceFee - effectivePrice;
    return byFormula > 0 ? byFormula : 0;
  }

  bool get hasSavings => computedSavedAmount > 0;
}
