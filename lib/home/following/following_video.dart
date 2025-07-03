import 'package:flutter/material.dart';



class followingVideo extends StatefulWidget {
  const followingVideo({super.key});

  @override
  State<followingVideo> createState() => _followingVideoState();
}

class _followingVideoState extends State<followingVideo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "following video screen",
              style: TextStyle(
                color: Colors.white
              ),
        ),
      ),
    );
  }
}
