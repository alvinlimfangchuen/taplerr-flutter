import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  int _selectedIndex = 4; // Profile tab selected

  // User data (you can replace with actual user data)
  String userName = "John Doe";
  String userEmail = "john.doe@taplerr.com";
  String userPhone = "+60 12-345 6789";
  String userRole = "Administrator";
  String joinDate = "March 2024";

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: Color(0xFF4285F4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Change Profile Picture',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildImageOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    if (_profileImage != null)
                      _buildImageOption(
                        icon: Icons.delete,
                        label: 'Remove',
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _profileImage = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile picture removed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFF4285F4)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color ?? const Color(0xFF4285F4),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4285F4), width: 3),
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(
                          _profileImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey[600],
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4285F4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userRole,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4285F4), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4285F4), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

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
            // Profile Header
            _buildProfileCard(),

            const SizedBox(height: 24),

            // Personal Information
            _buildInfoCard('Personal Information', [
              _buildInfoRow(Icons.email_outlined, 'Email', userEmail),
              _buildInfoRow(Icons.phone_outlined, 'Phone', userPhone),
              _buildInfoRow(Icons.calendar_today_outlined, 'Joined', joinDate),
            ]),

            const SizedBox(height: 24),

            // Quick Actions
            _buildInfoCard('Quick Actions', [
              _buildActionButton(Icons.edit_outlined, 'Edit Profile', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit profile not implemented yet'),
                  ),
                );
              }),
              _buildActionButton(Icons.lock_outline, 'Change Password', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change password not implemented yet'),
                  ),
                );
              }),
              _buildActionButton(
                Icons.security_outlined,
                'Security Settings',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Security settings not implemented yet'),
                    ),
                  );
                },
              ),
              _buildActionButton(Icons.help_outline, 'Help & Support', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Help & support not implemented yet'),
                  ),
                );
              }),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Home page not implemented yet')),
              );
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/cards');
              break;
            case 2:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Apps page not implemented yet')),
              );
              break;
            case 3:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contacts page not implemented yet'),
                ),
              );
              break;
            case 4:
              // Already on Profile page
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
}
