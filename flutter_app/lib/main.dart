import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.restoreSession();

  runApp(CodeQuestApp(authProvider: authProvider));
}

class CodeQuestApp extends StatelessWidget {
  const CodeQuestApp({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProxyProvider<AuthProvider, CourseProvider>(
          create: (_) => CourseProvider(),
          update: (_, auth, course) => (course ?? CourseProvider())..attachAuth(auth),
        ),
      ],
      child: MaterialApp(
        title: 'CodeQuest',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppRouter(),
      ),
    );
  }
}
