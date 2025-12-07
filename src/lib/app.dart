import 'package:flutter/material.dart';
import 'services/api/trainer_directory_service.dart';

/// The root widget of the Coach Planner application.
///
/// This widget sets up the Material Design theme and navigation structure
/// for the entire application.
class CoachPlannerApp extends StatelessWidget {
  const CoachPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coach Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16.0, height: 1.5),
          bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

/// The home page of the application.
///
/// This is a temporary placeholder that will be replaced with the actual
/// home page implementation.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Planner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const TrainerDirectoryDemo(),
    );
  }
}

class TrainerDirectoryDemo extends StatelessWidget {
  const TrainerDirectoryDemo({super.key});

  static final TrainerDirectoryService _service = TrainerDirectoryService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _service.fetchPublicTrainers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        }
        final data = snapshot.data!;
        if (data.data.isEmpty) {
          return const Center(child: Text('No trainers found.'));
        }
        return ListView.builder(
          itemCount: data.data.length,
          itemBuilder: (context, index) {
            final trainer = data.data[index];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(trainer.displayName),
              subtitle: Text(trainer.contactPhone ?? ''),
            );
          },
        );
      },
    );
  }
}
