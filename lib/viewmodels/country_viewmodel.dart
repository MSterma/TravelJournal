import 'package:flutter/material.dart';
import '../main.dart';
import '../models/country.dart';
import '../repositories/country_repo.dart';

class CountryViewModel extends ChangeNotifier {
  final CountryRepo _repo = CountryRepo();

  List<Country> countries = [];
  Country? selected;

  CountryViewModel() {
    loadCountries();
  }

  void loadCountries() {
    countries = _repo.getCountries();
    notifyListeners();
  }

  void select(Country c) {
    selected = c;
    notifyListeners();
  }

  void clear() {
    selected = null;
    notifyListeners();
  }
}