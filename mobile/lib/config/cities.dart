/// A city (or transport hub) that can be used as a search endpoint.
class City {
  const City(this.bn, this.en, {this.aliases = const <String>[]});

  /// Bengali name, e.g. `ঢাকা`.
  final String bn;

  /// English name, e.g. `Dhaka`.
  final String en;

  /// Extra English spellings that should also match this city.
  final List<String> aliases;

  /// Label shown in the suggestion list.
  String get label => '$bn · $en';

  /// Whether [query] (already lower-cased) matches this city.
  bool matches(String query) {
    if (query.isEmpty) return true;
    if (bn.contains(query)) return true;
    if (en.toLowerCase().contains(query)) return true;
    for (final alias in aliases) {
      if (alias.toLowerCase().contains(query)) return true;
    }
    return false;
  }
}

/// Districts of Bangladesh plus the terminals people actually depart from.
const List<City> bangladeshiCities = <City>[
  City('ঢাকা', 'Dhaka', aliases: <String>['dhaka', 'dacca']),
  City('কমলাপুর', 'Kamalapur', aliases: <String>['kamalapur']),
  City('মাওয়া', 'Mawa', aliases: <String>['mawa']),
  City('দৌলতদিয়া', 'Daulatdia', aliases: <String>['daulatdia']),
  City('সোনারগাঁও', 'Sonargaon', aliases: <String>['sonargaon']),
  City('গাজীপুর', 'Gazipur', aliases: <String>['gazipur']),
  City('নারায়ণগঞ্জ', 'Narayanganj', aliases: <String>['narayanganj']),
  City('চট্টগ্রাম', 'Chattogram', aliases: <String>['chittagong', 'ctg']),
  City('কক্সবাজার', "Cox's Bazar", aliases: <String>['coxsbazar', 'cox bazar']),
  City('খুলনা', 'Khulna'),
  City('রাজশাহী', 'Rajshahi'),
  City('বরিশাল', 'Barishal', aliases: <String>['barisal']),
  City('সিলেট', 'Sylhet'),
  City('রংপুর', 'Rangpur'),
  City('ময়মনসিংহ', 'Mymensingh'),
  City('বগুড়া', 'Bogura', aliases: <String>['bogra']),
  City('যশোর', 'Jashore', aliases: <String>['jessore']),
  City('দিনাজপুর', 'Dinajpur'),
  City('কুমিল্লা', 'Cumilla', aliases: <String>['comilla']),
  City('নোয়াখালী', 'Noakhali'),
  City('ফেনী', 'Feni'),
  City('টাঙ্গাইল', 'Tangail'),
  City('সিরাজগঞ্চ', 'Sirajganj'),
  City('পাবনা', 'Pabna'),
  City('ঈশ্বরদী', 'Ishwardi', aliases: <String>['ishwardi']),
  City('মুন্সিগঞ্চ', 'Munshiganj'),
  City('মানিকগঞ্জ', 'Manikganj'),
  City('কিশোরগঞ্জ', 'Kishoreganj'),
  City('ফরিদপুর', 'Faridpur'),
  City('গোপালগঞ্জ', 'Gopalganj'),
  City('শরীয়তপুর', 'Shariatpur'),
  City('রাজবাড়ী', 'Rajbari'),
  City('মাদারীপুর', 'Madaripur'),
  City('বরগুনা', 'Barguna'),
  City('পটুয়াখালী', 'Patuakhali'),
  City('ভোলা', 'Bhola'),
  City('ঝালকাঠি', 'Jhalokathi'),
  City('চাঁদপুর', 'Chandpur'),
  City('লক্ষ্মীপুর', 'Lakshmipur'),
  City('ব্রাহ্মণবাড়িয়া', 'Brahmanbaria'),
  City('সাতক্ষীরা', 'Satkhira'),
  City('বাগেরহাট', 'Bagerhat'),
  City('কুষ্টিয়া', 'Kushtia'),
  City('মেহেরপুর', 'Meherpur'),
  City('চুয়াডাঙ্গা', 'Chuadanga'),
  City('ঝিনাইদহ', 'Jhenaidah'),
  City('মাগুরা', 'Magura'),
  City('নড়াইল', 'Narail'),
  City('নাটোর', 'Natore'),
  City('চাঁপাইনবাবগঞ্জ', 'Chapainawabganj'),
  City('নওগাঁ', 'Naogaon'),
  City('জয়পুরহাট', 'Joypurhat'),
  City('পঞ্চগড়', 'Panchagarh'),
  City('ঠাকুরগাঁও', 'Thakurgaon'),
  City('নীলফামারী', 'Nilphamari'),
  City('লালমনিরহাট', 'Lalmonirhat'),
  City('কুড়িগ্রাম', 'Kurigram'),
  City('গাইবান্ধা', 'Gaibandha'),
  City('নেত্রকোণা', 'Netrokona'),
  City('শেরপুর', 'Sherpur'),
  City('জামালপুর', 'Jamalpur'),
  City('সুনামগঞ্জ', 'Sunamganj'),
  City('হবিগঞ্জ', 'Habiganj'),
  City('মৌলভীবাজার', 'Moulvibazar'),
];

/// Suggestions for the route picker: every city on an empty query, otherwise
/// the cities whose Bengali name, English name or alias contains [query].
List<City> citySuggestions(String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return bangladeshiCities;
  return bangladeshiCities.where((city) => city.matches(normalized)).toList();
}
