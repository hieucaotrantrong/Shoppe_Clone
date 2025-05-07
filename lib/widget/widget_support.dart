import 'package:flutter/material.dart';

class AppWidget {
  static TextStyle boldTextFieldStyle() {
    return const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle HeadlineTextFieldStyle() {
    return const TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle LightTextFieldStyle() {
    return const TextStyle(
      fontSize: 15.0,
      fontWeight: FontWeight.w500,
      color: Colors.black38,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle semiBoldTextFieldStyle() {
    return const TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w500,
      color: Colors.black,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle regularTextFieldStyle() {
    return const TextStyle(
      fontSize: 15.0,
      fontWeight: FontWeight.normal,
      color: Colors.black,
      fontFamily: 'Poppins',
    );
  }

  static headlineTextFeildStyle() {}

  static lightTextFeildStyle() {}
}