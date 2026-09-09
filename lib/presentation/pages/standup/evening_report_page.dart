import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../blocs/standup/standup_bloc.dart';

class EveningReportPage extends StatefulWidget {
  const EveningReportPage({super.key});

  @override
  State<EveningReportPage> createState() => _EveningReportPageState();
}

class _EveningReportPageState extends State<EveningReportPage> {
  final _completedController = TextEditingController();
  final _pendingController = TextEditingController();
  final _blockersController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    context.read<StandupBloc>().add(LoadMyStandup());
  }

  @override
  void dispose() {
    _completedController.dispose();
    _pendingController.dispose();
    _blockersController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_completedController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tell us what you completed today'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<StandupBloc>().add(SaveEveningReportEvent(
          completedToday: _completedController.text,
          pendingToday: _pendingController.text.trim().isEmpty ? null : _pendingController.text,
          blockers: _blockersController.text.trim().isEmpty ? null : _blockersController.text,
        ));
    setState(() => _saving = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evening Report')),
      body: BlocListener<StandupBloc, StandupState>(
        listener: (context, state) {
          if (state is StandupSaved) {
            setState(() => _saving = false);
            // Refresh the dashboard stand-up card instantly.
            context.read<StandupBloc>().add(LoadCompanyStandups(silent: true));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report submitted!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          } else if (state is StandupError) {
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<StandupBloc, StandupState>(
          builder: (context, state) {
            if (state is StandupLoading) {
              return const LoadingState(message: 'Loading today\'s report...');
            }

            if (state is StandupError) {
              return EmptyState(
                icon: Icons.nights_stay_outlined,
                title: 'Could not load report',
                subtitle: state.message,
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.nights_stay, color: AppColors.info, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End of Day Report',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Share what you got done today',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _completedController,
                    validator: (v) => AppValidators.required(v, 'Completed today'),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'What did you complete today?',
                      hintText: 'e.g. Closed 3 deals, demo for Acme Corp',
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _pendingController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'What is still pending?',
                      hintText: 'e.g. Awaiting client response on proposal',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _blockersController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Any blockers?',
                      hintText: 'e.g. Need access to client portal',
                      prefixIcon: Icon(Icons.block),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _onSubmit,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}