import 'package:flutter/material.dart';
import 'package:gocart/screens/login_screen.dart';
import 'package:gocart/utils/theme_provider.dart';
import 'package:gocart/screens/home_screen.dart';
import 'package:gocart/screens/list_screen.dart';
import 'package:gocart/screens/cart_screen.dart';
import 'package:gocart/globals/logger.dart';

void main() {
  logger.i('Starting the GoCart application...');
  runApp(const GoCart());
}

class GoCart extends StatelessWidget {
  const GoCart({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'goCart Grocery Price Comparison App',
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      home: const HomeLayout(),
    );
  }
}

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

@override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  // 1. Track the current active index
  int _currentScreenIndex = 3;

  // 2. Define the list of screens to toggle between
  final List<Widget> _screens = const [
    Center(child: HomeScreen()),
    Center(child: ListScreen()),
    Center(child: CartScreen()),
    Center(child: LoginScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('goCart'),
      ),
      // 3. Render the selected screen in the body
      body: IndexedStack(
        index: _currentScreenIndex,
        children: _screens,
      ),
      
      // 4. Implement the NavigationBar widget
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentScreenIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentScreenIndex = index;
          });
        },
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'List',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}