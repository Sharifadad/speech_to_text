import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'upload_form.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> with WidgetsBindingObserver {
  bool _isUploading = false;
  bool _showSuccess = false;
  final ImagePicker _picker = ImagePicker();
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isDialogOpen) {
      // Reset state when app resumes and dialog was open
      _isDialogOpen = false;
      _resetState();
    }
  }

  void _resetState() {
    if (mounted) {
      setState(() {
        _isUploading = false;
        _showSuccess = false;
      });
    }
  }

  Future<void> _showUploadOptions() async {
    if (_isUploading) return;
    _resetState();

    _isDialogOpen = true;
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text(
            'Upload Options',
            style: TextStyle(fontSize: 22),
          ),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'gallery'),
              child: const Row(
                children: [
                  Icon(Icons.photo_library),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Upload video from gallery",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'camera'),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Make video with phone camera",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: const Row(
                children: [
                  Icon(Icons.cancel),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Cancel",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    _isDialogOpen = false;

    if (result == 'gallery') {
      await _uploadVideoFromGallery();
    } else if (result == 'camera') {
      await _makeVideoWithCamera();
    }
  }

  Future<void> _uploadVideoFromGallery() async {
    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      final XFile? videoFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      ).catchError((error) {
        if (mounted) {
          _showErrorSnackbar('Failed to pick video: $error');
        }
        debugPrint('Error picking video: $error');
        return null;
      });

      if (!mounted) return;

      if (videoFile != null) {
        final success = await Get.to<bool>(
              () => UploadForm(
            videoFile: File(videoFile.path),
            videoPath: videoFile.path,
          ),
        );
        if (!mounted) return;

        if (success == true) {
          setState(() => _showSuccess = true);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showSuccess = false);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to pick video: ${e.toString()}');
      }
      debugPrint('Error picking video: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _makeVideoWithCamera() async {
    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      final XFile? videoFile = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      ).catchError((error) {
        if (mounted) {
          _showErrorSnackbar('Failed to record video: $error');
        }
        debugPrint('Error recording video: $error');
        return null;
      });

      if (!mounted) return;

      if (videoFile != null) {
        final success = await Get.to<bool>(
              () => UploadForm(
            videoFile: File(videoFile.path),
            videoPath: videoFile.path,
          ),
        );
        if (!mounted) return;

        if (success == true) {
          setState(() => _showSuccess = true);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showSuccess = false);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to record video: ${e.toString()}');
      }
      debugPrint('Error recording video: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_showSuccess) ...[
              const Icon(
                Icons.check_circle,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              const Text(
                'Video uploaded successfully!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Image.asset(
                "assets/images/upload.png",
                width: 260,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.cloud_upload,
                    size: 100,
                    color: Colors.white,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: _isUploading ? null : _showUploadOptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 15),
                disabledBackgroundColor: Colors.green.withOpacity(0.6),
              ),
              child: _isUploading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Upload New Video',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_isUploading) ...[
              const SizedBox(height: 20),
              const Text(
                'Processing video...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}