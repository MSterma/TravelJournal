import '../models/country.dart';

class CountryRepo {
  List<Country> getCountries() {
    return [
      Country(name: "Polska", areaSqM: 312696000000, population: 38000000),
      Country(name: "Niemcy", areaSqM: 357022000000, population: 83000000),
      Country(name: "Francja", areaSqM: 551695000000, population: 67000000),
    ];
  }
}