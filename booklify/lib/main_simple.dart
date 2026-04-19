import 'package:flutter/material.dart';

void main() {
  runApp(const BooklifySimpleApp());
}

class BooklifySimpleApp extends StatelessWidget {
  const BooklifySimpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booklify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const SimpleHomePage(),
    );
  }
}

class SimpleHomePage extends StatefulWidget {
  const SimpleHomePage({super.key});

  @override
  State<SimpleHomePage> createState() => _SimpleHomePageState();
}

class _SimpleHomePageState extends State<SimpleHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const LibraryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Booklify'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book,
            size: 100,
            color: Colors.indigo,
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome to Booklify!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '🌱 Grow Your Mind',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Book'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 20),
          Text(
            'Your Library',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'No books yet. Add your first book!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 20),
          Text(
            'Your Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Start your reading journey!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}