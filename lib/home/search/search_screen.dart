import 'package:flutter/material.dart';



class search_screen extends StatefulWidget {
  const search_screen({super.key});

  @override
  State<search_screen> createState() => _search_screenState();
}

class _search_screenState extends State<search_screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          " search screen",
          style: TextStyle(
              color: Colors.white
          ),
        ),
      ),
    );
  }
}
