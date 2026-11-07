/// Transport modes supported by the Ticketly platform.
///
/// The `wire` value is what travels to and from the backend.
enum TransportType {
  train('TRAIN', 'ট্রেন', 'Train'),
  bus('BUS', 'বাস', 'Bus'),
  launch('LAUNCH', 'লঞ্চ', 'Launch'),
  flight('FLIGHT', 'ফ্লাইট', 'Flight'),
  all('ALL', 'সব', 'All');

  const TransportType(this.wire, this.labelBn, this.labelEn);

  final String wire;
  final String labelBn;
  final String labelEn;

  static TransportType fromWire(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final type in TransportType.values) {
      if (type.wire == normalized) return type;
    }
    return TransportType.all;
  }
}

/// How the backend should rank the results.
enum SearchPriority {
  cheapest('CHEAPEST', 'সবচেয়ে কম ভাড়া', 'Cheapest'),
  fastest('FASTEST', 'সবচেয়ে দ্রুত', 'Fastest'),
  balanced('BALANCED', 'ভারসাম্য', 'Balanced');

  const SearchPriority(this.wire, this.labelBn, this.labelEn);

  final String wire;
  final String labelBn;
  final String labelEn;

  static SearchPriority fromWire(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final priority in SearchPriority.values) {
      if (priority.wire == normalized) return priority;
    }
    return SearchPriority.balanced;
  }
}

/// What the NLP pipeline understood from the passenger's query.
enum TicketIntent {
  searchTicket('SEARCH_TICKET', 'টিকিট খোঁজা'),
  bookTicket('BOOK_TICKET', 'টিকিট বুক করা'),
  checkStatus('CHECK_STATUS', 'স্ট্যাটাস দেখা'),
  unknown('UNKNOWN', 'অনিশ্চিত');

  const TicketIntent(this.wire, this.labelBn);

  final String wire;
  final String labelBn;

  static TicketIntent fromWire(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final intent in TicketIntent.values) {
      if (intent.wire == normalized) return intent;
    }
    return TicketIntent.unknown;
  }
}

/// Lifecycle of a booking.
enum BookingStatus {
  pending('PENDING', 'অপেক্ষমাণ', 'Pending'),
  confirmed('CONFIRMED', 'নিশ্চিত', 'Confirmed'),
  failed('FAILED', 'ব্যর্থ', 'Failed'),
  cancelled('CANCELLED', 'বাতিল', 'Cancelled');

  const BookingStatus(this.wire, this.labelBn, this.labelEn);

  final String wire;
  final String labelBn;
  final String labelEn;

  static BookingStatus fromWire(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final status in BookingStatus.values) {
      if (status.wire == normalized) return status;
    }
    return BookingStatus.pending;
  }
}

/// How the passenger pays for a booking.
enum PaymentMethod {
  mfs('MFS', 'মোবাইল ফাইন্যান্স'),
  card('CARD', 'কার্ড');

  const PaymentMethod(this.wire, this.labelBn);

  final String wire;
  final String labelBn;

  static PaymentMethod fromWire(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final method in PaymentMethod.values) {
      if (method.wire == normalized) return method;
    }
    return PaymentMethod.mfs;
  }
}

/// Mobile financial services supported at checkout.
const List<String> mfsProviders = <String>['bKash', 'Nagad', 'Rocket'];

/// How the result list should be ordered on the results screen.
enum ResultSort {
  effectivePrice('সর্বনিম্ন মূল্য'),
  duration('স্বল্প সময়');

  const ResultSort(this.labelBn);

  final String labelBn;
}
