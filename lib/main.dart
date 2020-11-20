import 'package:flutter/material.dart';

import 'mysplash.dart';

void main() {
  runApp(new MaterialApp(
    theme: ThemeData.from(colorScheme: ColorScheme.dark()),
    home: new MySplash(),
  ));
}
