import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/tasks/tasks_bloc.dart';
import '../../blocs/team/team_bloc.dart';
import '../../../domain/entities/profile.dart';

class AssignTaskPage extends StatefulWidget {
  const AssignTaskPage({super.key});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController();

  String _priority = 'MEDIUM';
  String? _selectedMemberId;
  DateTime? _dueDate;
  String? _dueTime;

  @override
  void initState() {
    super.initState();
    context.read<TeamBloc>().add(LoadCompanyMembers());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dueTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedMemberId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a team member'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final taskData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'assigned_to': _selectedMemberId,
        'priority': _priority,
        'status': 'TODO',
        'due_date': _dueDate?.toIso8601String().split('T').first,
        'due_time': _dueTime,
        'target_value': _targetValueController.text.isNotEmpty
            ? double.parse(_targetValueController.text)
            : null,
      };

      context.read<TasksBloc>().add(CreateTask(taskData));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Task')),
      body: BlocListener<TasksBloc, TasksState>(
        listener: (context, state) {
          if (state is TaskCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task assigned successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          } else if (state is TasksError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<TeamBloc, TeamState>(
          builder: (context, teamState) {
            final members = teamState is CompanyMembersLoaded ? teamState.members : <Profile>[];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      validator: (v) => AppValidators.required(v, 'Task title'),
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        hintText: 'e.g. PowerEMS – 20 leads contact karna',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Add task details...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Assign To
                    DropdownButtonFormField<String>(
        initialValue: _selectedMemberId,
                      items: members
                          .map((m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(m.fullName.isNotEmpty ? m.fullName : 'Unknown'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedMemberId = v),
                      decoration: const InputDecoration(labelText: 'Assign To'),
                      validator: (_) => _selectedMemberId == null ? 'Select a member' : null,
                    ),
                    const SizedBox(height: 16),

                    // Priority
                    DropdownButtonFormField<String>(
        initialValue: _priority,
                      items: ['URGENT', 'HIGH', 'MEDIUM', 'LOW']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) => setState(() => _priority = v ?? 'MEDIUM'),
                      decoration: const InputDecoration(labelText: 'Priority'),
                    ),
                    const SizedBox(height: 16),

                    // Due date & time
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDueDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Due Date'),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    _dueDate == null
                                        ? 'Select date'
                                        : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickDueTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Due Time'),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(_dueTime ?? 'Select time'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Target value
                    TextFormField(
                      controller: _targetValueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Value (optional)',
                        hintText: 'e.g. 20 calls',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _onSubmit,
                        child: const Text('Assign Task'),
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

