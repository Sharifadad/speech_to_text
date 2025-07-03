import 'package:get/get.dart';
import 'package:video_compress/video_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class UploadController extends GetxController {
  final RxBool isCompressing = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool isStoringData = false.obs;
  final RxDouble uploadProgress = 0.0.obs;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<File> compressVideoFile(String videoFilePath) async {
    try {
      isCompressing.value = true;
      final compressedVideo = await VideoCompress.compressVideo(
        videoFilePath,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
      );

      final compressedFile = compressedVideo!.file;
      if (compressedFile == null) {
        throw Exception('Compression failed - no output file');
      }
      return compressedFile;
    } catch (e) {
      Get.snackbar('Compression Error', 'Failed to compress video: $e');
      rethrow;
    } finally {
      isCompressing.value = false;
    }
  }

  Future<String> uploadVideoToFirebaseStorage(
      String videoID, String videoFilePath) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      final compressedFile = await compressVideoFile(videoFilePath);
      final ref = _storage.ref().child("All Videos").child(videoID);

      final uploadTask = ref.putFile(
        compressedFile,
        SettableMetadata(contentType: 'video/mp4'),
      );

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        uploadProgress.value =
            taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      Get.snackbar('Upload Error', 'Failed to upload video: $e');
      rethrow;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  Future<String> uploadThumbnailImageToFirebaseStorage(
      String videoID, String videoFilePath) async {
    try {
      // Generate thumbnail from video
      final thumbnailFile = await VideoCompress.getFileThumbnail(videoFilePath);
      final ref = _storage.ref().child("Thumbnails").child(videoID);

      final uploadTask = ref.putFile(thumbnailFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      Get.snackbar('Thumbnail Error', 'Failed to upload thumbnail: $e');
      rethrow;
    }
  }

  Future<void> saveVideoInformationToFireStoreDatabase(
      String artistSongName, String descriptionTags,
      String videoFilePath, BuildContext context) async {
    try {
      isStoringData.value = true;
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Get user data
      final userDoc = await _firestore.collection("users").doc(currentUser.uid).get();
      if (!userDoc.exists) throw Exception('User data not found');

      final userData = userDoc.data() as Map<String, dynamic>;
      final videoID = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload files
      final videoUrl = await uploadVideoToFirebaseStorage(videoID, videoFilePath);
      final thumbnailUrl = await uploadThumbnailImageToFirebaseStorage(videoID, videoFilePath);

      // Save video data
      await _firestore.collection("Videos").doc(videoID).set({
        "userID": currentUser.uid,
        "userName": userData['name'],
        "videoID": videoID,
        "artistSongName": artistSongName,
        "descriptionTags": descriptionTags,
        "videoUrl": videoUrl,
        "thumbnailUrl": thumbnailUrl,
        "publishedDateTime": DateTime.now(),
        "likesList": [],
        "commentsCount": 0,
        "sharesCount": 0,
      });

      Get.snackbar("Success", "Video uploaded successfully");
    } catch (errorMsg) {
      Get.snackbar("Video Upload Failed",
          "Error occurred: ${errorMsg.toString()}");
      rethrow;
    } finally {
      isStoringData.value = false;
    }
  }
}