import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart'; 
import '../widgets/sos_wizard.dart';
import 'electronics_page.dart';
import 'food_page.dart';
import 'travel_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _isSosActive = false;

  final List<Widget> _pages = [
    const ProductReviewPage(),
    const ElectronicsPage(),
    const FoodPage(),
    const TravelPage(),
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _listenToBackgroundService();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.sensors,
      Permission.location,
      Permission.camera,
      Permission.notification,
      Permission.systemAlertWindow, // Draw over apps
    ].request();
    
    // Specifically request "Always" location for background SOS precision
    if (await Permission.location.isGranted) {
      await Permission.locationAlways.request();
    }
  }

  void _listenToBackgroundService() {
    FlutterBackgroundService().on('fall_detected').listen((event) {
      if (!_isSosActive && mounted) {
        setState(() => _isSosActive = true);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          
          // SOS Overlay (Triggered by Background Service)
          if (_isSosActive)
            SOSWizard(
              guardianNumber: '+910000000000', // Mock guardian number
              onCancel: () {
                setState(() => _isSosActive = false);
              },
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A73E8),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.electrical_services_outlined),
            activeIcon: Icon(Icons.electrical_services),
            label: 'Tech',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant),
            label: 'Food',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore_outlined),
            activeIcon: Icon(Icons.travel_explore),
            label: 'Travel',
          ),
        ],
      ),
    );
  }
}
