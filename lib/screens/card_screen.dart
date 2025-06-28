import 'profile_screen.dart';
import 'package:flutter/material.dart';

class CardManagementScreen extends StatefulWidget {
  const CardManagementScreen({super.key});

  @override
  State<CardManagementScreen> createState() => _CardManagementScreenState();
}

class _CardManagementScreenState extends State<CardManagementScreen> {
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  int _selectedIndex = 1; // Cards tab selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF4285F4),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'T',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Taplerr',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              // Navigate back to login page
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Card Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'NFC Card Binding & Management',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bind New NFC Card Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bind New NFC Card',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Serial Number Field
                  const Text(
                    'Serial Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _serialController,
                    decoration: InputDecoration(
                      hintText: 'Enter card serial number',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF4285F4)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // OTP Code Field
                  const Text(
                    'OTP Code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      hintText: 'Enter OTP',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF4285F4)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bind Card Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle bind card action
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Card binding initiated'),
                            backgroundColor: Color(0xFF4285F4),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.link, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Bind Card',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bound NFC Cards Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bound NFC Cards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Card Serial',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Binding Date',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'MMU-FT',
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ),
                        const Expanded(
                          flex: 3,
                          child: Text(
                            '2025-03-11\n15:53:48',
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: IconButton(
                            onPressed: () {
                              // Handle unbind action
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Unbind Card'),
                                  content: const Text(
                                    'Are you sure you want to unbind this card?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Card unbound successfully',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      },
                                      child: const Text('Unbind'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Navigate based on selected tab
          switch (index) {
            case 0:
              // Home navigation - you can create home_screen.dart
              Navigator.pushReplacementNamed(context, '/login');
              break;
            case 1:
              // Already on Cards page
              break;
            case 2:
              // Apps navigation - you can create apps_screen.dart
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Apps page not implemented yet')),
              );
              break;
            case 3:
              // Contacts navigation - you can create contacts_screen.dart
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contacts page not implemented yet'),
                ),
              );
              break;
            case 4:
              // Navigate to Profile page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4285F4),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            activeIcon: Icon(Icons.credit_card),
            label: 'Cards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps_outlined),
            activeIcon: Icon(Icons.apps),
            label: 'Apps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            activeIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _serialController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
