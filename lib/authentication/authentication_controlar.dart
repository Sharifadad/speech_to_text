import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'AppUser.dart';
import '../home/home_screen.dart';

class AuthenticationController extends GetxController {
  final Rx<File?> _pickedFile = Rx<File?>(null);
  File? get profileImage => _pickedFile.value;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        _pickedFile.value = File(pickedImage.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  void togglePasswordVisibility() => obscurePassword.toggle();
  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.toggle();

  Future<void> handleSignUp() async {
    if (_validateForm()) {
      try {
        isLoading.value = true;
        await _createUserWithEmailAndPassword(
          nameController.text.trim(),
          emailController.text.trim(),
          passwordController.text.trim(),
        );
        isLoading.value = false;
        Get.offAll(() => HomeScreen());
      } catch (e) {
        isLoading.value = false;
        Get.snackbar('Error', 'Failed to create account: ${e.toString()}');
      }
    }
  }

  Future<void> _createUserWithEmailAndPassword(
      String name, String email, String password,
      ) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? imageUrl;
      if (_pickedFile.value != null) {
        imageUrl = await _uploadProfileImage(userCredential.user!.uid);
      }

      await _saveUserDataToFirestore(
        userCredential.user!.uid,
        name,
        email,
        imageUrl,
      );
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  Future<String> _uploadProfileImage(String userId) async {
    try {
      final ref = _storage.ref('profile_images/$userId.jpg');
      await ref.putFile(_pickedFile.value!);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<void> _saveUserDataToFirestore(
      String userId, String name, String email, String? imageUrl,
      ) async {
    try {
      final user = AppUser(
        name: name,
        uid: userId,
        email: email,
        image: imageUrl,
        youtube: '',
        facebook: '',
        twitter: '',
        instagram: '',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(userId).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to save user data: ${e.toString()}');
    }
  }

  bool _validateForm() {
    if (nameController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter your name');
      return false;
    }

    if (emailController.text.isEmpty || !emailController.text.contains('@')) {
      Get.snackbar('Error', 'Please enter a valid email');
      return false;
    }

    if (passwordController.text.isEmpty || passwordController.text.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters');
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar('Error', 'Passwords do not match');
      return false;
    }

    return true;
  }
}