import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/country.dart';
import '../../bloc/countries/country_bloc.dart';
import '../../bloc/countries/country_event.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/countries/country_list_item.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
    required this.countries,
    required this.isFetchingMore,
    required this.isSearching,
  });
  final List<Country> countries;
  final bool isFetchingMore;
  final bool isSearching;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CountryBloc>().add(LoadMoreCountries());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 200);
  }

  void _onSearchSubmit(String query) {
    context.read<CountryBloc>().add(SearchCountries(query));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.countryList)),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            hintText: l10n.search,
            onSubmitted: _onSearchSubmit,
            onClear: () {
              _searchController.clear();
              context.read<CountryBloc>().add(LoadCountries());
            },
          ),
          Expanded(
            child: widget.isSearching
                ? const LoadingIndicator()
                : widget.countries.isEmpty
                ? Center(child: Text(l10n.noResults))
                : ListView.builder(
              controller: _scrollController,
              itemCount: widget.countries.length + (widget.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= widget.countries.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LoadingIndicator(),
                  );
                }

                return CountryListItem(country: widget.countries[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClear,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}
