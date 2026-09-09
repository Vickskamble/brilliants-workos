import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../blocs/standup/standup_bloc.dart';
import '../../../domain/entities/standup.dart';

class MorningPlanPage extends StatefulWidget {
  const MorningPlanPage({super.key});

  @override
  State<MorningPlanPage> createState() => _MorningPlanPageState();
}

class _MorningPlanPageState extends State<MorningPlanPage> {
  final _task1Controller = TextEditingController();
  final _task2Controller = TextEditingController();
  final _task3Controller = TextEditingController();
  bool _prefilled = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    context.read<StandupBloc>().add(LoadMyStandup());
  }

  @override
  void dispose() {
    _task1Controller.dispose();
    _task2Controller.dispose();
    _task3Controller.dispose();
    super.dispose();
  }

  void _prefill(Standup? standup) {
    if (_prefilled || standup == null) return;
    _prefilled = true;
    _task1Controller.text = standup.planTask1 ?? '';
    _task2Controller.text = standup.planTask2 ?? '';
    _task3Controller.text = standup.planTask3 ?? '';
  }

  void _onSubmit() {
    context.read<StandupBloc>().add(SaveMorningPlanEvent(
          planTask1: _task1Controller.text.trim().isEmpty ? null : _task1Controller.text,
          planTask2: _task2Controller.text.trim().isEmpty ? null : _task2Controller.text,
          planTask3: _task3Controller.text.trim().isEmpty ? null : _task3Controller.text,
        ));
    setState(() => _saving = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Morning Plan')),
      body: BlocListener<StandupBloc, StandupState>(
        listener: (context, state) {
          if (state is StandupSaved) {
            setState(() => _saving = false);
            // Refresh the dashboard stand-up card instantly.
            context.read<StandupBloc>().add(LoadCompanyStandups(silent: true));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Morning plan saved!'),
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
              return const LoadingState(message: 'Loading your plan...');
            }

            if (state is StandupError && state is! MyStandupLoaded) {
              return EmptyState(
                icon: Icons.wb_sunny_outlined,
                title: 'Could not load plan',
                subtitle: state.message,
                action: ElevatedButton(
                  onPressed: () => context.read<StandupBloc>().add(LoadMyStandup()),
                  child: const Text('Retry'),
                ),
              );
            }

            if (state is MyStandupLoaded) {
              _prefill(state.standup);
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
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.wb_sunny, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Top 3 Tasks',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Plan your priorities for the day',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _task1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Task 1',
                      hintText: 'e.g. Contact 20 PowerEMS leads',
                      prefixIcon: Icon(Icons.looks_one),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _task2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Task 2',
                      hintText: 'e.g. Follow-up with 5 clients',
                      prefixIcon: Icon(Icons.looks_two),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _task3Controller,
                    decoration: const InputDecoration(
                      labelText: 'Task 3',
                      hintText: 'e.g. Schedule 2 demos',
                      prefixIcon: Icon(Icons.looks_3),
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
                          : const Text('Save Plan'),
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