import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_survey/screens/mdns_widget.dart';


Future main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await DotEnv().load('.env');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRODIGY AI',
      theme: ThemeData.dark(),
      home: MDNSWidget(),
    );
  }
}
