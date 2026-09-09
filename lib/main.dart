import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'core/network/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/team_repository.dart';
import 'data/repositories/target_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/tasks/tasks_bloc.dart';
import 'presentation/blocs/team/team_bloc.dart';
import 'presentation/blocs/targets/targets_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/signup_page.dart';
import 'presentation/pages/auth/forgot_password_page.dart';
import 'presentation/pages/auth/create_company_page.dart';
import 'presentation/pages/main_navigation_hub.dart';
import 'presentation/pages/tasks/assign_task_page.dart';
import 'presentation/pages/team/invite_member_page.dart';
import 'presentation/pages/targets/set_target_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseClientManager.initialize();
  } catch (e) {
    // If Supabase isn't configured, still show app but with error state
    debugPrint('Supabase initialization error: $e');
  }

  runApp(const BrilliantsWorkOSApp());
}

class BrilliantsWorkOSApp extends StatefulWidget {
  const BrilliantsWorkOSApp({super.key});

  @override
  State<BrilliantsWorkOSApp> createState() => _BrilliantsWorkOSAppState();
}

class _BrilliantsWorkOSAppState extends State<BrilliantsWorkOSApp> {
  late final AuthRepository _authRepository;
  late final TaskRepository _taskRepository;
  late final TeamRepository _teamRepository;
  late final TargetRepository _targetRepository;
  late final DashboardRepository _dashboardRepository;

  @override
  void initState() {
    super.initState();

    // Get the supabase client
    final client = SupabaseClientManager.isInitialized
        ? SupabaseClientManager.instance
        : SupabaseClient('', '');

    _authRepository = AuthRepository(client);
    _taskRepository = TaskRepository(client);
    _teamRepository = TeamRepository(client);
    _targetRepository = TargetRepository(client);
    _dashboardRepository = DashboardRepository(client);
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => _authRepository),
        RepositoryProvider<TaskRepository>(create: (_) => _taskRepository),
        RepositoryProvider<TeamRepository>(create: (_) => _teamRepository),
        RepositoryProvider<TargetRepository>(create: (_) => _targetRepository),
        RepositoryProvider<DashboardRepository>(create: (_) => _dashboardRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(repository: _authRepository)..add(AuthStarted()),
          ),
          BlocProvider<TasksBloc>(
            create: (context) => TasksBloc(repository: context.read<TaskRepository>()),
          ),
          BlocProvider<TeamBloc>(
            create: (context) => TeamBloc(repository: context.read<TeamRepository>()),
          ),
          BlocProvider<TargetsBloc>(
            create: (context) => TargetsBloc(repository: context.read<TargetRepository>()),
          ),
          BlocProvider<DashboardBloc>(
            create: (context) => DashboardBloc(repository: context.read<DashboardRepository>()),
          ),
        ],
        child: MaterialApp(
          title: 'Brilliants Work OS',
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: _routes,
          home: const _AppGate(),
        ),
      ),
    );
  }
}

final Map<String, WidgetBuilder> _routes = {
  '/login': (_) => const LoginPage(),
  '/signup': (_) => const SignupPage(),
  '/forgot-password': (_) => const ForgotPasswordPage(),
  '/home': (_) => const MainNavigationHub(),
  '/assign-task': (_) => const AssignTaskPage(),
  '/invite-member': (_) => const InviteMemberPage(),
  '/set-target': (_) => const SetTargetPage(),
};

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is Authenticated) {
          return const MainNavigationHub();
        }

        if (state is AuthNeedsCompany) {
          return const CreateCompanyPage();
        }

        if (state is AuthCompanyCreateError) {
          return const CreateCompanyPage();
        }

        // Unauthenticated or error
        return const LoginPage();
      },
    );
  }
}
