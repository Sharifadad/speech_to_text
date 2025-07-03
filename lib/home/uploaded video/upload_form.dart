import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class UploadForm extends StatefulWidget {
  final File videoFile;
  final String videoPath;

  const UploadForm({
    Key? key,
    required this.videoFile,
    required this.videoPath,
  }) : super(key: key);

  @override
  State<UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends State<UploadForm> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;
  bool _hasAttemptedUpload = false;
  late VideoPlayerController _playerController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _playerController = VideoPlayerController.file(widget.videoFile);
    await _playerController.initialize();
    setState(() {
      _isVideoInitialized = true;
    });
    _playerController.play();
    _playerController.setLooping(true);
  }

  @override
  void dispose() {
    _playerController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _uploadVideo() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _hasAttemptedUpload = true;
    });

    try {
      // Simulate actual upload - replace with your real upload logic
      await Future.delayed(const Duration(seconds: 2));

      // Only show success if we actually completed the upload
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Return success to previous screen
      Get.back(result: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Get.back(result: false);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isUploading
              ? null
              : () => Get.back(result: _hasAttemptedUpload),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _isUploading ? null : _uploadVideo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _isVideoInitialized
                  ? VideoPlayer(_playerController)
                  : Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _playerController.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_playerController.value.isPlaying) {
                        _playerController.pause();
                      } else {
                        _playerController.play();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.loop, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _playerController.setLooping(!_playerController.value.isLooping);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                hintText: 'Enter video title',
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                hintText: 'Enter video description',
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadVideo,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text('Upload Video'),
            ),
          ],
        ),
      ),
    );
  }
}