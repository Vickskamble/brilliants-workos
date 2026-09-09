import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../blocs/team/team_bloc.dart';
import '../../../domain/entities/profile.dart';

class TeamListPage extends StatefulWidget {
  const TeamListPage({super.key});

  @override
  State<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends State<TeamListPage> {
  @override
  void initState() {
    super.initState();
    context.read<TeamBloc>().add(LoadTeamData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => Navigator.pushNamed(context, '/invite-member'),
          ),
        ],
      ),
      body: BlocBuilder<TeamBloc, TeamState>(
        builder: (context, state) {
          if (state is TeamLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TeamError) {
            return Center(child: Text(state.message));
          }

          if (state is TeamDataLoaded) {
            if (state.members.isEmpty) {
              return EmptyState(
                icon: Icons.people_outline,
                title: 'No Team Members',
                subtitle: 'Invite your first team member to get started.',
                action: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/invite-member'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Invite Member'),
                ),
              );
            }

            return Column(
              children: [
                // Teams section
                if (state.teams.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text('Teams', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New Team'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.teams.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final team = state.teams[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group, color: AppColors.primary),
                                const SizedBox(height: 4),
                                Text(team.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                Text('${team.memberCount} members', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Members section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text('Members (${state.members.length})', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = state.members[index];
                      return _MemberTile(member: member);
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Profile member;

  const _MemberTile({required this.member});

  Color get _roleColor => switch (member.role) {
    'OWNER' => AppColors.primary,
    'ADMIN' => AppColors.info,
    'MANAGER' => AppColors.warning,
    _ => AppColors.textTertiary,
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _roleColor.withValues(alpha: 0.1),
        child: Text(
          member.initials,
          style: TextStyle(color: _roleColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(member.fullName.isNotEmpty ? member.fullName : 'Unknown'),
      subtitle: Text('${member.role} · ${member.department}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: member.isActive ? AppColors.successLight : AppColors.errorLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          member.isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: 11,
            color: member.isActive ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () => Navigator.pushNamed(context, '/member-detail', arguments: member.id),
    );
  }
}
