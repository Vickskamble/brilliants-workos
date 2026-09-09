import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MorningPlanPage extends StatefulWidget {
  const MorningPlanPage({super.key});

  @override
  State<MorningPlanPage> createState() => _MorningPlanPageState();
}

class _MorningPlanPageState extends State<MorningPlanPage> {
  final _task1Controller = TextEditingController();
  final _task2Controller = TextEditingController();
  final _task3Controller = TextEditingController();

  @override
  void dispose() {
    _task1Controller.dispose();
    _task2Controller.dispose();
    _task3Controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    // TODO: Save morning plan via DashboardBloc
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Morning plan saved!'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Morning Plan')),
      body: SingleChildScrollView(
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

            // Task 1
            TextFormField(
              controller: _task1Controller,
              decoration: const InputDecoration(
                labelText: 'Task 1',
                hintText: 'e.g. Contact 20 PowerEMS leads',
                prefixIcon: Icon(Icons.looks_one),
              ),
            ),
            const SizedBox(height: 16),

            // Task 2
            TextFormField(
              controller: _task2Controller,
              decoration: const InputDecoration(
                labelText: 'Task 2',
                hintText: 'e.g. Follow-up with 5 clients',
                prefixIcon: Icon(Icons.looks_two),
              ),
            ),
            const SizedBox(height: 16),

            // Task 3
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
                onPressed: _onSubmit,
                child: const Text('Save Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
