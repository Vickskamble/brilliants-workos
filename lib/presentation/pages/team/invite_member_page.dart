import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/auth/auth_bloc.dart';

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
      // TODO: Implement send invite (would call an Edge Function)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite sent! (Email delivery coming soon)'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Member')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: SingleChildScrollView(
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
                  'They will receive an email with instructions to join your team.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Name
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

                // Email
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

                // Role
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

                // Department
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
                    onPressed: _onInvite,
                    child: const Text('Send Invite'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

