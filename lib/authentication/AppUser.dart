import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  String? name;
  String? uid;
  String? image;
  String? email;
  String? youtube;
  String? facebook;
  String? twitter;
  String? instagram;
  DateTime createdAt;

  AppUser({
    this.name,
    this.uid,
    this.image,
    this.email,
    this.youtube,
    this.facebook,
    this.twitter,
    this.instagram,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'uid': uid,
      'image': image,
      'email': email,
      'youtube': youtube,
      'facebook': facebook,
      'twitter': twitter,
      'instagram': instagram,
      'createdAt': createdAt,
    };
  }

  factory AppUser.fromSnap(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return AppUser(
      name: dataSnapshot["name"],
      uid: dataSnapshot["uid"],
      image: dataSnapshot["image"],
      email: dataSnapshot["email"],
      youtube: dataSnapshot["youtube"],
      facebook: dataSnapshot["facebook"],
      twitter: dataSnapshot["twitter"],
      instagram: dataSnapshot["instagram"],
      createdAt: dataSnapshot["createdAt"]?.toDate() ?? DateTime.now(),
    );
  }
}