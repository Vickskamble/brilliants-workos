import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';

class CreateCompanyPage extends StatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  State<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends State<CreateCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  String? _industry;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    // Auto-generate slug from company name
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    _slugController.text = slug;
  }

  String? _validateSlug(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Slug is required';
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9-]*[a-z0-9]$').hasMatch(value)) {
      return 'Use lowercase letters, numbers, and hyphens';
    }
    return null;
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    context.read<AuthBloc>().add(
          AuthCompanyCreated(
            name: _nameController.text.trim(),
            slug: _slugController.text.trim(),
            industry: _industry,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        final message = switch (state) {
          AuthError s => s.message,
          AuthCompanyCreateError s => s.message,
          _ => null,
        };
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.workspaces_outlined, size: 72, color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Set up your workspace',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your company to get started with Brilliants Work OS',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _nameController,
                            onChanged: _onNameChanged,
                            decoration: const InputDecoration(
                              labelText: 'Company name',
                              hintText: 'e.g. Brilliants',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty ? 'Company name is required' : null,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _slugController,
                            decoration: InputDecoration(
                              labelText: 'Workspace URL / slug',
                              hintText: 'brilliants',
                              prefixIcon: const Icon(Icons.link),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'Copy slug',
                                onPressed: () => Clipboard.setData(
                                  ClipboardData(text: _slugController.text),
                                ),
                              ),
                            ),
                            validator: _validateSlug,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _industry,
                            decoration: const InputDecoration(
                              labelText: 'Industry (optional)',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: [
                              'Software',
                              'Retail',
                              'Manufacturing',
                              'Finance',
                              'Healthcare',
                              'Education',
                              'Marketing',
                              'Consulting',
                              'Other',
                            ]
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (value) => setState(() => _industry = value),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _onSubmit,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Create workspace'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You will be the Owner (admin) of this workspace.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
