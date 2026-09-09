import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/performance_ring.dart';
import '../../blocs/team/team_bloc.dart';

class MemberDetailPage extends StatefulWidget {
  final String profileId;
  const MemberDetailPage({super.key, required this.profileId});

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<TeamBloc>().add(LoadMemberDetail(widget.profileId));
    context.read<TeamBloc>().add(LoadMemberPerformance(widget.profileId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Profile')),
      body: BlocBuilder<TeamBloc, TeamState>(
        builder: (context, teamState) {
          if (teamState is! MemberDetailLoaded) {
            if (teamState is TeamLoading) {
              return const LoadingState(message: 'Loading member...');
            }
            if (teamState is TeamError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load',
                subtitle: teamState.message,
              );
            }
            return const SizedBox.shrink();
          }

          final member = teamState.member;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          member.initials,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        member.fullName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RoleBadge(role: member.role),
                          const SizedBox(width: 8),
                          _DepartmentBadge(department: member.department),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Joined ${AppFormatters.formatDate(member.joinedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Real performance for the current month
              Text(
                'Performance (This Month)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const _PerformanceSection(),
            ],
          );
        },
      ),
    );
  }
}

class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeamBloc, TeamState>(
      builder: (context, state) {
        if (state is TeamLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (state is! MemberPerformanceLoaded) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No performance data yet.')),
            ),
          );
        }

        final p = state.performance;
        final overall = ((p['overall'] as num?) ?? 0).toDouble();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PerformanceRing(
                      percentage: overall,
                      size: 80,
                      label: 'Overall',
                      strokeWidth: 8,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PerformanceMetric(
                            label: 'Tasks (${(p['completed'] as num?) ?? 0}/${(p['assigned'] as num?) ?? 0})',
                            value: '${_fmt(p['task_completion'])}%',
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 4),
                          _PerformanceMetric(
                            label: 'Target Achievement',
                            value: '${_fmt(p['target_achievement'])}%',
                            color: AppColors.info,
                          ),
                          const SizedBox(height: 4),
                          _PerformanceMetric(
                            label: 'On-time Rate',
                            value: '${_fmt(p['on_time_rate'])}%',
                            color: AppColors.success,
                          ),
                          const SizedBox(height: 8),
                          StatusBadge(status: p['band']?.toString() ?? 'AVERAGE'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Target: ${AppFormatters.formatCurrency(((p['target_total'] as num?) ?? 0).toDouble())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      'Achieved: ${AppFormatters.formatCurrency(((p['target_achieved'] as num?) ?? 0).toDouble())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmt(Object? value) {
    final n = (value as num?)?.toDouble() ?? 0;
    return n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'OWNER' => AppColors.primary,
      'ADMIN' => AppColors.info,
      'MANAGER' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(role, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _DepartmentBadge extends StatelessWidget {
  final String department;
  const _DepartmentBadge({required this.department});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(department, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PerformanceMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}