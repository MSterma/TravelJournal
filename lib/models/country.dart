class Country {
  final String name;
  final String capital;
  final String flagUrl;
  final int population;
  final String region;
  final double lat;
  final double lng;

  Country({
    required this.name,
    required this.capital,
    required this.flagUrl,
    required this.population,
    required this.region,
    required this.lat,
    required this.lng,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    final name = json['names']?['common'] ?? 'Brak nazwy';

    final capitalsList = json['capitals'] as List?;
    final capital = (capitalsList != null && capitalsList.isNotEmpty)
        ? capitalsList[0]['name'] ?? 'Brak stolicy'
        : 'Brak stolicy';

    final flagUrl = json['flag']?['url_png'] ?? '';

    final population = json['population'] ?? 0;
    final region = json['region'] ?? 'Brak regionu';

    final coords = json['coordinates'];
    final lat = coords?['lat']?.toDouble() ?? 0.0;
    final lng = coords?['lng']?.toDouble() ?? 0.0;

    return Country(
      name: name,
      capital: capital,
      flagUrl: flagUrl,
      population: population,
      region: region,
      lat: lat,
      lng: lng,
    );
  }
}