import 'package:flutter/material.dart';

class NetworkLoggerScreen extends StatefulWidget {
  const NetworkLoggerScreen({Key? key}) : super(key: key);

  @override
  State<NetworkLoggerScreen> createState() => _NetworkLoggerScreenState();
}

class _NetworkLoggerScreenState extends State<NetworkLoggerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Logs'),
      ),
      body: Container(),
    );
  }
}