import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/targets/targets_bloc.dart';
import '../../blocs/team/team_bloc.dart';
import '../../../domain/entities/profile.dart';

class SetTargetPage extends StatefulWidget {
  const SetTargetPage({super.key});

  @override
  State<SetTargetPage> createState() => _SetTargetPageState();
}

class _SetTargetPageState extends State<SetTargetPage> {
  final _formKey = GlobalKey<FormState>();
  final _targetValueController = TextEditingController();

  String _targetType = 'SALES';
  String _periodType = 'MONTHLY';
  String? _selectedMemberId;
  DateTime _periodStart = DateTime.now();
  DateTime _periodEnd = DateTime.now().add(const Duration(days: 30));

  static const _targetTypes = {
    'SALES': 'Sales',
    'LEADS': 'Leads',
    'CALLS': 'Calls',
    'MEETINGS': 'Meetings',
    'DEMOS': 'Demos',
    'CONVERSIONS': 'Conversions',
    'REVENUE': 'Revenue',
    'POSTS': 'Posts',
    'REELS': 'Reels',
    'TASKS_COMPLETED': 'Tasks Completed',
  };

  @override
  void initState() {
    super.initState();
    context.read<TeamBloc>().add(LoadCompanyMembers());
  }

  @override
  void dispose() {
    _targetValueController.dispose();
    super.dispose();
  }

  Future<void> _pickPeriodStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodStart,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _periodStart = picked;
        _periodEnd = picked.add(const Duration(days: 30));
      });
    }
  }

  Future<void> _pickPeriodEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodEnd,
      firstDate: _periodStart,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _periodEnd = picked);
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

      final targetData = <String, dynamic>{
        'profile_id': _selectedMemberId,
        'target_type': _targetType,
        'period_type': _periodType,
        'period_start': _periodStart.toIso8601String().split('T').first,
        'period_end': _periodEnd.toIso8601String().split('T').first,
        'target_value': double.parse(_targetValueController.text),
      };

      context.read<TargetsBloc>().add(CreateTargetEvent(targetData));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Target')),
      body: BlocListener<TargetsBloc, TargetsState>(
        listener: (context, state) {
          if (state is TargetCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Target set successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          } else if (state is TargetsError) {
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
                    const Icon(Icons.flag_outlined, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Set Performance Target',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'System will automatically calculate daily/weekly breakdown.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

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
                      decoration: const InputDecoration(labelText: 'Assign To Member'),
                      validator: (_) => _selectedMemberId == null ? 'Select a member' : null,
                    ),
                    const SizedBox(height: 16),

                    // Target Type
                    DropdownButtonFormField<String>(
        initialValue: _targetType,
                      items: _targetTypes.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _targetType = v ?? 'SALES'),
                      decoration: const InputDecoration(labelText: 'Target Type'),
                    ),
                    const SizedBox(height: 16),

                    // Period Type
                    DropdownButtonFormField<String>(
        initialValue: _periodType,
                      items: const [
                        DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                        DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                        DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                        DropdownMenuItem(value: 'QUARTERLY', child: Text('Quarterly')),
                        DropdownMenuItem(value: 'YEARLY', child: Text('Yearly')),
                      ],
                      onChanged: (v) => setState(() => _periodType = v ?? 'MONTHLY'),
                      decoration: const InputDecoration(labelText: 'Period'),
                    ),
                    const SizedBox(height: 16),

                    // Period Dates
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickPeriodStart,
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Start Date'),
                              child: Text(DateFormat('dd MMM yyyy').format(_periodStart)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickPeriodEnd,
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'End Date'),
                              child: Text(DateFormat('dd MMM yyyy').format(_periodEnd)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Target Value
                    TextFormField(
                      controller: _targetValueController,
                      validator: (v) => AppValidators.positiveNumber(v, 'Target value'),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Target Value',
                        hintText: 'e.g. 200000 for ₹2,00,000',
                        prefixIcon: _targetType == 'REVENUE' || _targetType == 'SALES'
                            ? const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Center(child: Text('₹', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 18))),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _onSubmit,
                        child: const Text('Set Target'),
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

