import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/dashboard/dashboard_bloc.dart';
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
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
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
