import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/activity_bar_chart.dart';
import '../../../core/widgets/dashboard_header.dart';
import '../../../core/widgets/leaderboard_card.dart';
import '../../../core/widgets/performance_ring.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/task_status_donut.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/standup/standup_bloc.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DashboardError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<DashboardBloc>().add(LoadDashboard()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is DashboardLoaded) {
            final stats = state.stats;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(LoadDashboard());
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DashboardHeader(
                          userName: stats.fullName,
                          companyName: stats.companyName,
                          role: stats.role,
                          unreadCount: state.unreadCount,
                          onRefresh: () =>
                              context.read<DashboardBloc>().add(LoadDashboard()),
                          onNotifications: () =>
                              Navigator.pushNamed(context, '/notifications'),
                          onProfile: () {
                            if (stats.myProfileId.isNotEmpty) {
                              Navigator.pushNamed(
                                context,
                                '/member-detail',
                                arguments: stats.myProfileId,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // KPI grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 760;
                            final cards = [
                              StatCard(
                                label: 'Team Members',
                                value: '${stats.totalTeam}',
                                icon: Icons.people_outline,
                                iconColor: AppColors.primary,
                                subtitle: '${stats.totalTeams} active teams',
                              ),
                              StatCard(
                                label: 'Total Tasks',
                                value: '${stats.totalTasks}',
                                icon: Icons.task_outlined,
                                iconColor: AppColors.info,
                                subtitle: 'Due today & overdue',
                              ),
                              StatCard(
                                label: 'Completed',
                                value: '${stats.completed}',
                                icon: Icons.check_circle_outline,
                                iconColor: AppColors.success,
                                valueColor: AppColors.success,
                                subtitle:
                                    '${stats.completionRate.toStringAsFixed(1)}% completion',
                                progress: stats.completionRate / 100,
                              ),
                              StatCard(
                                label: 'Overdue',
                                value: '${stats.overdue}',
                                icon: Icons.warning_amber_rounded,
                                iconColor: AppColors.error,
                                valueColor: AppColors.error,
                                subtitle: 'Need attention',
                              ),
                            ];

                            if (wide) {
                              return Row(
                                children: [
                                  for (final c in cards) ...[
                                    Expanded(child: c),
                                    if (c != cards.last) const SizedBox(width: 12),
                                  ],
                                ],
                              );
                            }
                            return GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 1.5,
                              children: cards,
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Charts row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 760;
                            final donut = _ChartCard(
                              title: 'Task Status',
                              subtitle: 'All company tasks',
                              icon: Icons.donut_small,
                              color: AppColors.primary,
                              child: TaskStatusDonut(
                                todo: stats.allTodo,
                                inProgress: stats.allInProgress,
                                completed: stats.allCompleted,
                              ),
                            );
                            final activity = _ChartCard(
                              title: 'Weekly Activity',
                              subtitle: 'Tasks completed in last 7 days',
                              icon: Icons.bar_chart,
                              color: AppColors.info,
                              child: ActivityBarChart(
                                data: stats.weeklyActivity,
                              ),
                            );
                            if (wide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: donut),
                                  const SizedBox(width: 12),
                                  Expanded(child: activity),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                donut,
                                const SizedBox(height: 12),
                                activity,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Target achievement
                        _TargetCard(stats: stats),
                        const SizedBox(height: 20),

                        // Leaderboard
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(
                                    icon: Icons.emoji_events_outlined,
                                    title: 'Top Performers',
                                    subtitle: 'This month · 35% tasks + 40% targets + 25% on-time',
                                  ),
                                  const SizedBox(height: 12),
                                  LeaderboardCard(entries: stats.leaderboard),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Stand-up
                        const _StandupSection(),
                        const SizedBox(height: 20),

                        // Quick actions
                        const _SectionTitle(
                          icon: Icons.bolt_outlined,
                          title: 'Quick Actions',
                          subtitle: null,
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 600;
                            final actions = [
                              _QuickAction(
                                icon: Icons.add_task,
                                label: 'Assign Task',
                                gradient: AppGradients.info,
                                onTap: () =>
                                    Navigator.pushNamed(context, '/assign-task'),
                              ),
                              _QuickAction(
                                icon: Icons.flag_outlined,
                                label: 'Set Target',
                                gradient: AppGradients.warning,
                                onTap: () =>
                                    Navigator.pushNamed(context, '/set-target'),
                              ),
                              _QuickAction(
                                icon: Icons.person_add_outlined,
                                label: 'Add Member',
                                gradient: AppGradients.success,
                                onTap: () =>
                                    Navigator.pushNamed(context, '/invite-member'),
                              ),
                              _QuickAction(
                                icon: Icons.rule_outlined,
                                label: 'Overdue Tasks',
                                gradient: AppGradients.error,
                                onTap: () =>
                                    Navigator.pushNamed(context, '/overdue-tasks'),
                              ),
                            ];
                            if (wide) {
                              return Row(
                                children: [
                                  for (final a in actions) ...[
                                    Expanded(child: a),
                                    if (a != actions.last)
                                      const SizedBox(width: 12),
                                  ],
                                ],
                              );
                            }
                            return GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 1.3,
                              children: actions,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section headers
// ---------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionTitle({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(child: child),
        ],
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final dynamic stats;

  const _TargetCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pct = stats.targetAchievement;
    final total = stats.targetTotal;
    final achieved = stats.targetAchieved;
    final remaining = ((total - achieved).clamp(0.0, double.infinity)).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          PerformanceRing(
            percentage: pct,
            size: 92,
            strokeWidth: 8,
            ringColor: Colors.white,
            trackColor: Colors.white24,
            labelColor: Colors.white,
            centerBackground: Colors.transparent,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Target Achievement',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${pct.toStringAsFixed(1)}% of goal achieved',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 6,
                  children: [
                    _TargetStat(
                      label: 'Achieved',
                      value: AppFormatters.formatCurrency(achieved),
                      icon: Icons.trending_up,
                    ),
                    _TargetStat(
                      label: 'Goal',
                      value: AppFormatters.formatCurrency(total),
                      icon: Icons.flag_outlined,
                    ),
                    _TargetStat(
                      label: 'Remaining',
                      value: AppFormatters.formatCurrency(remaining),
                      icon: Icons.hourglass_bottom,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TargetStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandupSection extends StatefulWidget {
  const _StandupSection();

  @override
  State<_StandupSection> createState() => _StandupSectionState();
}

class _StandupSectionState extends State<_StandupSection> {
  @override
  void initState() {
    super.initState();
    context.read<StandupBloc>().add(LoadCompanyStandups());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wb_sunny_outlined, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Daily Stand-Up',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/morning-plan'),
                  icon: const Icon(Icons.wb_sunny, size: 18),
                  label: const Text('Morning Plan'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/evening-report'),
                  icon: const Icon(Icons.nights_stay, size: 18),
                  label: const Text('Evening Report'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BlocBuilder<StandupBloc, StandupState>(
            builder: (context, state) {
              if (state is StandupLoading) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              if (state is! CompanyStandupsLoaded || state.standups.isEmpty) {
                return Text(
                  'No team members yet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                );
              }

              final done = state.standups
                  .where((s) => (s.hasPlan || s.hasReport) && s.status == 'SUBMITTED')
                  .length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$done of ${state.standups.length} submitted today',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...state.standups.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.fullName,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _StandupDot(
                              label: 'Plan',
                              done: s.hasPlan,
                              submitted: s.status == 'SUBMITTED',
                            ),
                            const SizedBox(width: 12),
                            _StandupDot(
                              label: 'Report',
                              done: s.hasReport,
                              submitted: s.status == 'SUBMITTED',
                            ),
                          ],
                        ),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StandupDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool submitted;

  const _StandupDot({required this.label, required this.done, required this.submitted});

  @override
  Widget build(BuildContext context) {
    final color = done
        ? (submitted ? AppColors.success : AppColors.warning)
        : AppColors.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}