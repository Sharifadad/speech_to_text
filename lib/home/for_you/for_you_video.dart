import 'package:flutter/material.dart';



class forYouVideo extends StatefulWidget {
  const forYouVideo({super.key});

  @override
  State<forYouVideo> createState() => _forYouVideoState();
}

class _forYouVideoState extends State<forYouVideo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "for you video screen",
          style: TextStyle(
              color: Colors.white
          ),
        ),
      ),
    );
  }
}
