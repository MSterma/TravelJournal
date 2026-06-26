import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flag/flag.dart';
import '../../locator.dart';
import '../../repositories/local_repo.dart';
import '../../models/user_stats.dart';
import '../../services/sync_service.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/countries/stat_item.dart';
import '../widgets/countries/achievement_badge.dart';

enum ChartType { photos, notes, countries }

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  ChartType _selectedChart = ChartType.photos;

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
                Text(
                  '${l10n.loggedAs}\n$email',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 32),
                _buildStatsContent(context, state.userId, l10n, email),
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
                  onPressed: () => _deleteAccount(context, state.userId, l10n),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logOut),
                  onPressed: () =>
                      context.read<AuthBloc>().add(AuthSignOutRequested()),
                ),
              ],
            );
          }
          return Center(child: Text(l10n.noData));
        },
      ),
    );
  }

  Widget _buildStatsContent(
    BuildContext context,
    String userId,
    AppLocalizations l10n,
    String email,
  ) {
    return FutureBuilder<UserStats>(
      future: locator<LocalRepo>().getUserStats(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snapshot.data!;

        final userName = email != l10n.noEmail
            ? email.split('@')[0]
            : 'Użytkownik';
        final displayName = userName.isNotEmpty
            ? userName[0].toUpperCase() + userName.substring(1)
            : 'Użytkownik';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopStatsGrid(context, stats, l10n),
            const SizedBox(height: 24),
            _buildChartSegment(stats, l10n),
            const SizedBox(height: 24),
            _buildCountriesThisMonth(stats.countriesThisMonth, l10n),
            const SizedBox(height: 32),
            _buildAchievements(context, stats, displayName, l10n),
          ],
        );
      },
    );
  }

  Widget _buildTopStatsGrid(
    BuildContext context,
    UserStats stats,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statsToday,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatItem(label: l10n.statsPhotos, value: stats.todayPhotos),
              StatItem(label: l10n.statsNotes, value: stats.todayNotes),
              StatItem(label: l10n.statsCountries, value: stats.todayCountries),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatItem(
                label: l10n.statsPhotos,
                value: stats.totalPhotos,
                isTotal: true,
              ),
              StatItem(
                label: l10n.statsNotes,
                value: stats.totalNotes,
                isTotal: true,
              ),
              StatItem(
                label: l10n.statsCountries,
                value: stats.totalCountries,
                isTotal: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSegment(UserStats stats, AppLocalizations l10n) {
    List<int> data;
    String title;
    String description;
    Color color;

    switch (_selectedChart) {
      case ChartType.photos:
        data = stats.photosActivity;
        title = l10n.chartPhotos;
        description = l10n.chartPhotosDesc;
        color = Colors.blue;
        break;
      case ChartType.notes:
        data = stats.notesActivity;
        title = l10n.chartNotes;
        description = l10n.chartNotesDesc;
        color = Colors.green;
        break;
      case ChartType.countries:
        data = stats.countriesActivity;
        title = l10n.chartCountries;
        description = l10n.chartCountriesDesc;
        color = Colors.orange;
        break;
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DropdownButton<ChartType>(
              value: _selectedChart,
              underline: const SizedBox(),
              icon: const Icon(Icons.insights),
              onChanged: (ChartType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedChart = newValue;
                  });
                }
              },
              items: [
                DropdownMenuItem(
                  value: ChartType.photos,
                  child: Text(l10n.chartPhotos),
                ),
                DropdownMenuItem(
                  value: ChartType.notes,
                  child: Text(l10n.chartNotes),
                ),
                DropdownMenuItem(
                  value: ChartType.countries,
                  child: Text(l10n.chartCountries),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: Padding(
            padding: const EdgeInsets.only(right: 24.0, top: 12.0),
            child: LineChart(
              LineChartData(
                minY: 0,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        l10n.chartAxisDays,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        if (value % 5 != 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: theme.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        l10n.chartAxisCount,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: theme.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                    left: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.toDouble());
                    }).toList(),
                    isCurved: false,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => color.withValues(alpha: 0.8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          barSpot.y.toInt().toString(),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountriesThisMonth(
    List<String> countries,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.statsCountriesThisMonth,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (countries.isEmpty)
          Text(l10n.noData, style: const TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: countries
                .map(
                  (c) => Flag.fromString(
                    c,
                    height: 25,
                    width: 35,
                    replacement: Container(
                      height: 25,
                      width: 35,
                      color: Colors.grey[700],
                      alignment: Alignment.center,
                      child: Text(
                        c.length >= 2 ? c.substring(0, 2).toUpperCase() : c,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildAchievements(
    BuildContext context,
    UserStats stats,
    String name,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(
            l10n.statsAchievements(name),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AchievementBadge(
                icon: Icons.camera_alt,
                color: Colors.blueGrey,
                label: '100 ${l10n.statsPhotos}',
                progress: stats.totalPhotos,
                target: 100,
              ),
              AchievementBadge(
                icon: Icons.work,
                color: Colors.brown,
                label: '10 ${l10n.statsTrips}',
                progress: stats.totalTrips,
                target: 10,
              ),
              AchievementBadge(
                icon: Icons.local_fire_department,
                color: Colors.orange,
                label: l10n.statsStreak(7),
                progress: stats.currentStreak,
                target: 7,
              ),
              AchievementBadge(
                icon: Icons.map,
                color: Colors.green,
                label: '50 ${l10n.statsCountries}',
                progress: stats.totalCountries,
                target: 50,
              ),
              AchievementBadge(
                icon: Icons.star,
                color: Colors.amber,
                label: '50 ${l10n.statsTrips}',
                progress: stats.totalTrips,
                target: 50,
              ),
              AchievementBadge(
                icon: Icons.photo_library,
                color: Colors.indigo,
                label: '1000 ${l10n.statsPhotos}',
                progress: stats.totalPhotos,
                target: 1000,
                showProgressBar: true,
              ),
            ],
          ),
        ],
      ),
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
                  Text(
                    errorMsg!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: newCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
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
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(l10n.cancel),
              ),
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
                    await locator<FirebaseAuth>().setLanguageCode(
                      l10n.localeName,
                    );
                    await locator<FirebaseAuth>().currentUser?.updatePassword(
                      newCtrl.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(c);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.passwordChanged)),
                      );
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

  void _clearDb(
    BuildContext context,
    String userId,
    AppLocalizations l10n,
  ) async {
    await locator<LocalRepo>().clearUserData(userId);
    await locator<SyncService>().clearCloudData(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.databaseFlushed)));
    }
  }

  void _deleteAccount(
    BuildContext context,
    String userId,
    AppLocalizations l10n,
  ) async {
    try {
      await locator<FirebaseAuth>().setLanguageCode(l10n.localeName);
      await locator<LocalRepo>().clearUserData(userId);
      await locator<SyncService>().clearCloudData(userId);

      await locator<FirebaseAuth>().currentUser?.delete();
      if (context.mounted) context.read<AuthBloc>().add(AuthSignOutRequested());
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.requiresRecentLogin),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.cloudError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }
}
