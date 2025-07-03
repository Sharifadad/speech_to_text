import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'authentication/settings_screen.dart';  // Adjust if needed based on your directory structure
import 'authentication/settings_screen.dart';
//import 'authentication/signup_screen.dart';
//import 'package:lib/authentication/settings_screen.dart'; // Make sure this import is correct

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? bio;
  String username = 'username';
  String country = 'Country';
  int followingCount = 0;
  int followersCount = 0;
  int likesCount = 0;
  bool isPrivate = false;
  bool showLikes = true;
  bool showLockedVideos = true;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _showImageSourceDialog() async {
    await Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Select Image Source', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile() async {
    final result = await Get.dialog<Map<String, dynamic>>(
      SimpleDialog(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Change profile picture', style: TextStyle(color: Colors.white)),
            onTap: () {
              Get.back(result: {'action': 'profile_picture'});
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white),
            title: const Text('Change username', style: TextStyle(color: Colors.white)),
            onTap: () => Get.back(result: {'action': 'username'}),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white),
            title: const Text('Edit bio', style: TextStyle(color: Colors.white)),
            onTap: () => Get.back(result: {'action': 'bio'}),
          ),
          ListTile(
            leading: Icon(isPrivate ? Icons.lock_open : Icons.lock, color: Colors.white),
            title: Text(isPrivate ? 'Make account public' : 'Make account private',
                style: const TextStyle(color: Colors.white)),
            onTap: () => Get.back(result: {'action': 'privacy'}),
          ),
          ListTile(
            leading: Icon(showLikes ? Icons.visibility_off : Icons.visibility, color: Colors.white),
            title: Text(showLikes ? 'Hide liked videos' : 'Show liked videos',
                style: const TextStyle(color: Colors.white)),
            onTap: () => Get.back(result: {'action': 'toggle_likes'}),
          ),
          ListTile(
            leading: Icon(showLockedVideos ? Icons.lock_outline : Icons.lock_open, color: Colors.white),
            title: Text(showLockedVideos ? 'Hide locked videos' : 'Show locked videos',
                style: const TextStyle(color: Colors.white)),
            onTap: () => Get.back(result: {'action': 'toggle_locked_videos'}),
          ),
        ],
      ),
    );

    if (result != null) {
      if (result['action'] == 'profile_picture') {
        await _showImageSourceDialog();
      } else {
        setState(() {
          switch (result['action']) {
            case 'username':
              username = 'new_username';
              break;
            case 'bio':
              bio = 'New bio text';
              break;
            case 'privacy':
              isPrivate = !isPrivate;
              break;
            case 'toggle_likes':
              showLikes = !showLikes;
              break;
            case 'toggle_locked_videos':
              showLockedVideos = !showLockedVideos;
              break;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit') {
                await _editProfile();
              } else if (value == 'settings') {
                // Use GetX navigation to your actual SettingsScreen
                Get.toNamed('/settings');
              } else if (value == 'promote') {
                Get.snackbar('Promote', 'Promotion options will appear here');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'promote',
                child: Text('Promote'),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings and privacy'),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit profile'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Profile picture with tap to change
            Center(
              child: GestureDetector(
                onTap: () {
                  if (_profileImage != null) {
                    Get.dialog(
                      Dialog(
                        backgroundColor: Colors.transparent,
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: CircleAvatar(
                            radius: 100,
                            backgroundImage: FileImage(_profileImage!),
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : const NetworkImage('https://via.placeholder.com/100') as ImageProvider,
                      backgroundColor: Colors.grey,
                    ),
                    if (isPrivate)
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(Icons.lock, size: 20, color: Colors.white),
                      ),
                    if (_profileImage == null)
                      const Icon(Icons.person, size: 28, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        followingCount.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Following',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        followersCount.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Followers',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        likesCount.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Likes',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _editProfile,
                child: const Text('Edit profile'),
              ),
            ),
            const SizedBox(height: 20),
            if (bio == null)
              const Center(
                child: Text(
                  'Tap to add bio',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  bio!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}