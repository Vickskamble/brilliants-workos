import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/repositories/team_repository.dart';
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

  Future<void> _showCreateTeamDialog(List<Profile> members) async {
    final bloc = context.read<TeamBloc>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? managerId;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Team'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Team name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: managerId,
                hint: const Text('Manager (optional)'),
                items: members
                    .map((m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.fullName.isNotEmpty ? m.fullName : 'Unknown'),
                        ))
                    .toList(),
                onChanged: (v) => managerId = v,
                decoration: const InputDecoration(labelText: 'Manager'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true && nameController.text.trim().isNotEmpty) {
      if (!mounted) return;
      bloc.add(CreateTeamEvent(
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      ));
      // Find the created team id after reload to assign a manager.
      final teamId = await _waitForNewTeamId(nameController.text.trim(), bloc);
      if (teamId != null && managerId != null && mounted) {
        bloc.add(AddTeamMember(teamId, managerId!));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team created'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<String?> _waitForNewTeamId(String name, TeamBloc bloc) async {
    for (var i = 0; i < 20; i++) {
      final state = bloc.state;
      if (state is TeamDataLoaded) {
        final team = state.teams.where((t) => t.name == name).firstOrNull;
        if (team != null) return team.id;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  Future<void> _showTeamMembers(BuildContext context, String teamId) async {
    final repository = context.read<TeamRepository>();
    final bloc = context.read<TeamBloc>();
    final teamName = (bloc.state is TeamDataLoaded)
        ? (bloc.state as TeamDataLoaded).teams.where((t) => t.id == teamId).firstOrNull?.name ?? 'Team'
        : 'Team';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _TeamMembersSheet(
          teamId: teamId,
          teamName: teamName,
          repository: repository,
          bloc: bloc,
          scrollController: scrollController,
        ),
      ),
    );
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
                          onPressed: () => _showCreateTeamDialog(state.members),
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
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final team = state.teams[index];
                        return InkWell(
                          onTap: () => _showTeamMembers(context, team.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Card(
                            margin: EdgeInsets.zero,
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
                    separatorBuilder: (_, _) => const Divider(height: 1),
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

class _TeamMembersSheet extends StatefulWidget {
  final String teamId;
  final String teamName;
  final TeamRepository repository;
  final TeamBloc bloc;
  final ScrollController scrollController;

  const _TeamMembersSheet({
    required this.teamId,
    required this.teamName,
    required this.repository,
    required this.bloc,
    required this.scrollController,
  });

  @override
  State<_TeamMembersSheet> createState() => _TeamMembersSheetState();
}

class _TeamMembersSheetState extends State<_TeamMembersSheet> {
  late Future<Set<String>> _memberIdsFuture;

  @override
  void initState() {
    super.initState();
    _memberIdsFuture = _loadMemberIds();
  }

  Future<Set<String>> _loadMemberIds() async {
    final members = await widget.repository.getTeamMembers(widget.teamId);
    return members.map((m) => m.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final allMembers = widget.bloc.state is TeamDataLoaded
        ? (widget.bloc.state as TeamDataLoaded).members
        : const <Profile>[];

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${widget.teamName} — Members',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to add or remove members',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Set<String>>(
          future: _memberIdsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final memberIds = snapshot.data ?? <String>{};
            return Column(
              children: allMembers.map((member) {
                final checked = memberIds.contains(member.id);
                return CheckboxListTile(
                  value: checked,
                  title: Text(member.fullName.isNotEmpty ? member.fullName : 'Unknown'),
                  subtitle: Text('${member.role} · ${member.department}'),
                  onChanged: (value) {
                    if (value == true) {
                      widget.bloc.add(AddTeamMember(widget.teamId, member.id));
                    } else {
                      widget.bloc.add(RemoveTeamMember(widget.teamId, member.id));
                    }
                    setState(() {
                      if (value == true) {
                        memberIds.add(member.id);
                      } else {
                        memberIds.remove(member.id);
                      }
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
