import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../locator.dart';
import '../repositories/local_repo.dart';
import '../services/sync_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../l10n/app_localizations.dart';
import '../database/app_database.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccount)),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = locator<FirebaseAuth>().currentUser;
            final email = user?.email ?? l10n.noEmail;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text('${l10n.loggedAs}\n$email', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 32),

                _buildChart(state.userId),
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  icon: const Icon(Icons.lock),
                  label: Text(l10n.changePassword),
                  onPressed: () => _changePassword(context, l10n),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_sweep),
                  label: Text(l10n.flushDatabase),
                  onPressed: () => _clearDb(context, state.userId, l10n),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: Text(l10n.deleteAccount),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _deleteAccount(context, state.userId),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logOut),
                  onPressed: () => context.read<AuthBloc>().add(AuthSignOutRequested()),
                ),
              ],
            );
          }
          return Center(child: Text(l10n.noData));
        },
      ),
    );
  }

  Widget _buildChart(String userId) {
    return FutureBuilder<List<VisitedCountry>>(
      future: locator<LocalRepo>().getVisitedWithCoords(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));

        final visits = snapshot.data!;
        if (visits.isEmpty) return const SizedBox.shrink();

        final Map<int, int> monthly = {for (var i = 1; i <= 12; i++) i: 0};
        for (var v in visits) {
          monthly[v.visitedAt.month] = (monthly[v.visitedAt.month] ?? 0) + 1;
        }

        double maxVal = 1;
        for (var val in monthly.values) {
          if (val > maxVal) maxVal = val.toDouble();
        }

        return Column(
          children: [
            const Text('Wizyty (miesiące)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal + 1,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: monthly.entries.map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(toY: e.value.toDouble(), color: Colors.blue, width: 16)],
                  )).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _changePassword(BuildContext context, AppLocalizations l10n) {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.changePassword),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMsg != null) ...[
                  Text(errorMsg!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: newCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () async {
                  if (newCtrl.text.length < 6) {
                    setState(() => errorMsg = l10n.min6Chars);
                    return;
                  }
                  if (newCtrl.text != confirmCtrl.text) {
                    setState(() => errorMsg = l10n.passwordsNotMatch);
                    return;
                  }

                  setState(() => errorMsg = null);

                  try {
                    await locator<FirebaseAuth>().currentUser?.updatePassword(newCtrl.text);
                    if (context.mounted) {
                      Navigator.pop(c);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
                    }
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'requires-recent-login') {
                      setState(() => errorMsg = l10n.requiresRecentLogin);
                    } else {
                      setState(() => errorMsg = l10n.cloudError);
                    }
                  } catch (e) {
                    setState(() => errorMsg = l10n.errorMsg);
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _clearDb(BuildContext context, String userId, AppLocalizations l10n) async {
    await locator<LocalRepo>().clearUserData(userId);
    await locator<SyncService>().clearCloudData(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.databaseFlushed)));
    }
  }

  void _deleteAccount(BuildContext context, String userId) async {
    try {
      await locator<LocalRepo>().clearUserData(userId);
      await locator<SyncService>().clearCloudData(userId);

      await locator<FirebaseAuth>().currentUser?.delete();
      if (context.mounted) context.read<AuthBloc>().add(AuthSignOutRequested());
    } catch (e) {
    }
  }
}