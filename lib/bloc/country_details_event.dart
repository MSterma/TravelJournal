abstract class CountryDetailsEvent {}

class LoadDetails extends CountryDetailsEvent {
  LoadDetails(this.countryName);
  final String countryName;
}

class MarkCountryVisited extends CountryDetailsEvent {
  MarkCountryVisited(this.countryName);
  final String countryName;
}

class AddCountryPhoto extends CountryDetailsEvent {
  AddCountryPhoto(this.countryName, this.imagePath);
  final String countryName;
  final String imagePath;
}