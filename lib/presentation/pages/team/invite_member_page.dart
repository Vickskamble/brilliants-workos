import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/team/team_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';

class InviteMemberPage extends StatefulWidget {
  const InviteMemberPage({super.key});

  @override
  State<InviteMemberPage> createState() => _InviteMemberPageState();
}

class _InviteMemberPageState extends State<InviteMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _role = 'MEMBER';
  String _department = 'SALES';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onInvite() {
    if (_formKey.currentState!.validate()) {
      context.read<TeamBloc>().add(InviteMember(
            email: _emailController.text.trim(),
            fullName: _nameController.text.trim(),
            role: _role,
            department: _department,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Member')),
      body: BlocListener<TeamBloc, TeamState>(
        listener: (context, state) {
          if (state is MemberInvited) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: state.status == 'IN_OTHER_COMPANY'
                    ? AppColors.error
                    : AppColors.success,
              ),
            );
            if (state.status != 'IN_OTHER_COMPANY') {
              // Refresh team + dashboard instantly.
              context.read<TeamBloc>().add(LoadCompanyMembers());
              context.read<TeamBloc>().add(LoadTeamData());
              context.read<DashboardBloc>().add(LoadDashboard(silent: true));
              Navigator.pop(context);
            }
          } else if (state is TeamError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<TeamBloc, TeamState>(
          builder: (context, state) {
            final sending = state is TeamLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.person_add_outlined, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Invite to Brilliants Work OS',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If they already have an account they\'re added instantly; otherwise they\'ll join automatically when they sign up.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _nameController,
                      validator: (v) => AppValidators.required(v, 'Full name'),
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      validator: AppValidators.email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      items: const [
                        DropdownMenuItem(value: 'MEMBER', child: Text('Member')),
                        DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                      ],
                      onChanged: (v) => setState(() => _role = v ?? 'MEMBER'),
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _department,
                      items: const [
                        DropdownMenuItem(value: 'SALES', child: Text('Sales')),
                        DropdownMenuItem(value: 'MARKETING', child: Text('Marketing')),
                        DropdownMenuItem(value: 'DEVELOPMENT', child: Text('Development')),
                        DropdownMenuItem(value: 'SUPPORT', child: Text('Support')),
                        DropdownMenuItem(value: 'OPERATIONS', child: Text('Operations')),
                        DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _department = v ?? 'SALES'),
                      decoration: const InputDecoration(labelText: 'Department'),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: sending ? null : _onInvite,
                        child: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Send Invite'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}