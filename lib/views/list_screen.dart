import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/country.dart';
import '../bloc/country_bloc.dart';
import '../bloc/country_event.dart';
import '../l10n/app_localizations.dart';

class ListScreen extends StatefulWidget {
  final List<Country> countries;
  final bool isFetchingMore;

  const ListScreen({
    super.key,
    required this.countries,
    required this.isFetchingMore,
  });

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.countryList)),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: widget.countries.length + (widget.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= widget.countries.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final c = widget.countries[index];
          return ListTile(
            title: Text(c.name),
            onTap: () => context.read<CountryBloc>().add(SelectCountry(c)),
          );
        },
      ),
    );
  }
}