import 'package:cloud_firestore/cloud_firestore.dart';

class Video {
  final String userID;
  final String userName;
  final String? userProfileImage; // Made nullable as it might not always be available
  final String videoID;
  final int totalComments;
  final int totalShares;
  final List<String> likesList; // Specified type for better type safety
  final String artistSongName;
  final String descriptionTags;
  final String videoUrl;
  final String thumbnailUrl;
  final DateTime publishedDateTime; // Changed to DateTime for better handling

  Video({
    required this.userID,
    required this.userName,
    this.userProfileImage,
    required this.videoID,
    this.totalComments = 0,
    this.totalShares = 0,
    this.likesList = const [],
    required this.artistSongName,
    required this.descriptionTags,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.publishedDateTime,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'videoID': videoID,
      'totalComments': totalComments,
      'totalShares': totalShares,
      'likesList': likesList,
      'artistSongName': artistSongName,
      'descriptionTags': descriptionTags,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'publishedDateTime': publishedDateTime.millisecondsSinceEpoch,
    };
  }

  // Factory constructor to create Video from Firestore document
  factory Video.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return Video(
      userID: data['userID'] as String,
      userName: data['userName'] as String,
      userProfileImage: data['userProfileImage'] as String?,
      videoID: data['videoID'] as String,
      totalComments: (data['totalComments'] as int?) ?? 0,
      totalShares: (data['totalShares'] as int?) ?? 0,
      likesList: List<String>.from(data['likesList'] ?? []),
      artistSongName: data['artistSongName'] as String,
      descriptionTags: data['descriptionTags'] as String,
      videoUrl: data['videoUrl'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String,
      publishedDateTime: DateTime.fromMillisecondsSinceEpoch(
        (data['publishedDateTime'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // Helper method to create a copy with updated values
  Video copyWith({
    String? userID,
    String? userName,
    String? userProfileImage,
    String? videoID,
    int? totalComments,
    int? totalShares,
    List<String>? likesList,
    String? artistSongName,
    String? descriptionTags,
    String? videoUrl,
    String? thumbnailUrl,
    DateTime? publishedDateTime,
  }) {
    return Video(
      userID: userID ?? this.userID,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      videoID: videoID ?? this.videoID,
      totalComments: totalComments ?? this.totalComments,
      totalShares: totalShares ?? this.totalShares,
      likesList: likesList ?? this.likesList,
      artistSongName: artistSongName ?? this.artistSongName,
      descriptionTags: descriptionTags ?? this.descriptionTags,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      publishedDateTime: publishedDateTime ?? this.publishedDateTime,
    );
  }
}