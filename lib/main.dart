import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:queberry_feedback/screens/mdns_widget.dart';


import 'constants/constants.dart' as constants;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MaterialApp(
      title: constants.app_tittle,
      theme: ThemeData(
          primaryColor: Color.fromRGBO(45, 51, 62, 1),
          scaffoldBackgroundColor: Color.fromRGBO(245, 245, 245, 1),
      ),
      home: SafeArea(child: MDNSWidget()),
    );
  }
}
