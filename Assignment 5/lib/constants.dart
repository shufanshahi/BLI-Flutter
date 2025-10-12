import 'package:flutter/material.dart';

const Color buttonColor = Color.fromARGB(222, 255, 162, 0);

AppBar appBar(String title) => AppBar(
      title: Text(title),
      automaticallyImplyLeading: false,
    );

const optionText = Text(
  'Or',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
  textAlign: TextAlign.center,
);

const spacer = SizedBox(
  height: 12,
);
