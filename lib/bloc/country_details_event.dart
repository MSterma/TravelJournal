abstract class CountryDetailsEvent {}

class LoadDetails extends CountryDetailsEvent {
  LoadDetails(this.countryName);
  final String countryName;
}

class MarkCountryVisited extends CountryDetailsEvent {
  MarkCountryVisited(this.countryName, this.lat, this.lng);
  final String countryName;
  final double lat;
  final double lng;
}

class AddCountryPhoto extends CountryDetailsEvent {
  AddCountryPhoto(this.countryName, this.imagePath);
  final String countryName;
  final String imagePath;
}