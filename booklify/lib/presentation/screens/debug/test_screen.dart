import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/seed_data_service.dart';
import '../../providers/auth_provider.dart';

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  bool _isLoading = false;
  String _statusMessage = 'Ready for testing';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Card(
            color: Colors.deepPurple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_statusMessage),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Auth Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authentication',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${authState.status.name}'),
                  if (authState.user != null) ...[
                    Text('User: ${authState.user!.displayName}'),
                    Text('Email: ${authState.user!.email}'),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Database Tests
          Text(
            'Database Tests',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          _buildTestButton(
            icon: Icons.storage,
            label: 'Seed Test Data',
            color: Colors.green,
            onPressed: () => _runTest('Seeding database...', () async {
              await SeedDataService.seedDatabase();
              return '✅ Database seeded successfully!';
            }),
          ),

          _buildTestButton(
            icon: Icons.person_add,
            label: 'Test Sign Up',
            color: Colors.blue,
            onPressed: () => _runTest('Creating test user...', () async {
              await ref.read(authProvider.notifier).signUp(
                email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
                password: 'test123',
                displayName: 'Test User',
              );
              return '✅ User created successfully!';
            }),
          ),

          _buildTestButton(
            icon: Icons.login,
            label: 'Test Demo Login',
            color: Colors.orange,
            onPressed: () => _runTest('Logging in demo user...', () async {
              final creds = await SeedDataService.getDemoCredentials();
              await ref.read(authProvider.notifier).signIn(
                email: creds['email'] as String,
                password: creds['password'] as String,
              );
              return '✅ Demo login successful!';
            }),
          ),

          _buildTestButton(
            icon: Icons.delete_sweep,
            label: 'Clear Database',
            color: Colors.red,
            onPressed: () => _runTest('Clearing database...', () async {
              await SeedDataService.clearDatabase();
              return '✅ Database cleared!';
            }),
          ),

          const SizedBox(height: 16),

          // Demo Credentials
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vpn_key, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Demo Credentials',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Email: demo@booklify.com'),
                  const Text('Password: demo123'),
                  const SizedBox(height: 8),
                  const Text(
                    'Use these credentials to test the login flow',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Navigation Tests
          Text(
            'Navigation Tests',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          _buildTestButton(
            icon: Icons.menu_book,
            label: 'Go to Library',
            color: Colors.purple,
            onPressed: () {
              Navigator.pushNamed(context, '/library');
            },
          ),

          _buildTestButton(
            icon: Icons.park,
            label: 'Go to Reading Garden',
            color: Colors.green,
            onPressed: () {
              Navigator.pushNamed(context, '/garden');
            },
          ),

          _buildTestButton(
            icon: Icons.emoji_events,
            label: 'Go to Achievements',
            color: Colors.amber,
            onPressed: () {
              Navigator.pushNamed(context, '/achievements');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Future<void> _runTest(String startMessage, Future<String> Function() testFn) async {
    setState(() {
      _isLoading = true;
      _statusMessage = startMessage;
    });

    try {
      final result = await testFn();
      setState(() {
        _statusMessage = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }
}
