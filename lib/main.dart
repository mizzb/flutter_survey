import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_survey/screens/mdns_widget.dart';

import 'constants/constants.dart' as constants;

Future main() async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: constants.app_tittle,
      theme: ThemeData.dark(),
      home: MDNSWidget(),
    );
  }
}
