import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../blocs/targets/targets_bloc.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/target.dart';

class TargetsPage extends StatefulWidget {
  const TargetsPage({super.key});

  @override
  State<TargetsPage> createState() => _TargetsPageState();
}

class _TargetsPageState extends State<TargetsPage> {
  @override
  void initState() {
    super.initState();
    context.read<TargetsBloc>().add(LoadTargets());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Targets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TargetsBloc>().add(LoadTargets()),
          ),
        ],
      ),
      body: BlocBuilder<TargetsBloc, TargetsState>(
        builder: (context, state) {
          if (state is TargetsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TargetsError) {
            return Center(child: Text(state.message));
          }

          if (state is TargetsLoaded) {
            if (state.targets.isEmpty) {
              return EmptyState(
                icon: Icons.flag_outlined,
                title: 'No Targets',
                subtitle: 'Set targets for your team members to track performance.',
                action: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/set-target'),
                  icon: const Icon(Icons.add),
                  label: const Text('Set Target'),
                ),
              );
            }

            // Sort: active first, then by end date
            final sorted = [...state.targets]..sort((a, b) {
              if (a.isAchieved != b.isAchieved) return a.isAchieved ? 1 : -1;
              if (a.isExpired != b.isExpired) return a.isExpired ? 1 : -1;
              return a.periodEnd.compareTo(b.periodEnd);
            });

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final target = sorted[index];
                return _TargetCard(target: target);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/set-target'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final Target target;

  const _TargetCard({required this.target});

  @override
  Widget build(BuildContext context) {
    final percentage = target.achievementPercentage;
    final color = percentage >= 85
        ? AppColors.success
        : percentage >= 50
            ? AppColors.warning
            : AppColors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    target.targetTypeLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (target.isAchieved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '🎉 Achieved',
                      style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (target.profileName != null)
              Text(
                target.profileName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            const SizedBox(height: 4),
            Text(
              '${target.periodType} · ${AppFormatters.formatShortDate(target.periodStart)} – ${AppFormatters.formatShortDate(target.periodEnd)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppFormatters.formatNumber(target.currentValue)} / ${AppFormatters.formatNumber(target.targetValue)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
