import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_survey/screens/mdns_widget.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRODIGY AI',
      theme: ThemeData.dark(),
      home: MDNSWidget(),
    );
  }
}
