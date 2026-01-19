// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:gokwik/config/types.dart';
import 'package:gokwik/go_kwik_client.dart';
import 'package:gokwik/api/base_response.dart';
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    HomeScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await GoKwikClient.instance.initializeSDK(InitializeSdkProps(
        // mid: '19g6jle2d5p3n',
        mid: "12wyqc2guqmkrw6406j",
        // mid: '19x8g5js05wj',
        // mid: "2be09imdmw6032",
        environment: Environment.production,
        isSnowplowTrackingEnabled: false,
        mode: 'debug',

        onAnalytics: (eventname, properties) {
          debugPrint("eventName::: $eventname");
          debugPrint("event properties::: $properties");
        },
      ));
    } catch (e) {
      // Now that Failure class has a proper toString() method, this should work
      debugPrint("ERROR IN INIT: $e");
      
      // Also try to access the message property directly if it's a Failure
      if (e is Failure) {
        debugPrint("MESSAGE ${e.message}");
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If we're on the home screen, let the system handle the back button
        if (_selectedIndex == 0) {
          return true;
        }
        // Otherwise, navigate to the home screen
        setState(() {
          _selectedIndex = 0;
        });
        return false;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
