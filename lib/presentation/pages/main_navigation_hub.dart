import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/dashboard/dashboard_bloc.dart';
import '../blocs/tasks/tasks_bloc.dart';
import '../blocs/team/team_bloc.dart';
import '../blocs/targets/targets_bloc.dart';
import '../blocs/standup/standup_bloc.dart';
import 'owner/owner_dashboard.dart';
import 'tasks/my_tasks_page.dart';
import 'team/team_list_page.dart';
import 'targets/targets_page.dart';
import 'notifications/notifications_page.dart';

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const OwnerDashboard(),
    const MyTasksPage(),
    const TeamListPage(),
    const TargetsPage(),
    const NotificationsPage(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboard());
    context.read<DashboardBloc>().subscribeToNotifications();
    context.read<DashboardBloc>().subscribeToLiveData();
    context.read<TasksBloc>().subscribeToTaskChanges();
    context.read<StandupBloc>().subscribeToStandupChanges();
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex && index != 0) {
      // Re-tapping the active tab refreshes it too.
      setState(() {});
    } else {
      setState(() => _currentIndex = index);
    }

    // Always refresh the tab being shown (auto, no manual pull needed).
    switch (index) {
      case 0:
        context.read<DashboardBloc>().add(LoadDashboard(silent: true));
      case 1:
        context.read<TasksBloc>().add(LoadMyTasks(silent: true));
        context.read<TasksBloc>().add(LoadAssignedTasks(silent: true));
      case 2:
        context.read<TeamBloc>().add(LoadTeamData());
      case 3:
        context.read<TargetsBloc>().add(LoadTargets());
      case 4:
        context.read<DashboardBloc>().add(LoadNotifications());
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<DashboardBloc, int>(
      (bloc) => bloc.state is DashboardLoaded
          ? (bloc.state as DashboardLoaded).unreadCount
          : 0,
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          const NavigationDestination(icon: Icon(Icons.task_outlined), selectedIcon: Icon(Icons.task), label: 'Tasks'),
          const NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Team'),
          const NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Targets'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
