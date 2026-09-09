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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Profile')),
      body: BlocBuilder<TeamBloc, TeamState>(
        builder: (context, teamState) {
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

          if (teamState is! MemberDetailLoaded) {
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

              // This month performance
              Text(
                'Performance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // Placeholder for performance overview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const PerformanceRing(percentage: 82, size: 80, label: 'Overall'),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PerformanceMetric(label: 'Task Completion', value: '88%', color: AppColors.success),
                                const SizedBox(height: 4),
                                _PerformanceMetric(label: 'Target Achievement', value: '76%', color: AppColors.info),
                                const SizedBox(height: 4),
                                _PerformanceMetric(label: 'On-time Rate', value: '90%', color: AppColors.success),
                                const SizedBox(height: 8),
                                const StatusBadge(status: 'EXCELLENT'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact info
              Text(
                'Contact',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    if (member.phone != null)
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: Text(member.phone!),
                      ),
                    if (member.avatarUrl != null)
                      ListTile(
                        leading: const Icon(Icons.image_outlined),
                        title: Text('Avatar available'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
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
