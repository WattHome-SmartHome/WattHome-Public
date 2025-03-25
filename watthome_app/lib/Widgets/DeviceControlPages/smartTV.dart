import 'package:flutter/material.dart';

class SmartTV extends StatefulWidget {
  const SmartTV({super.key});

  @override
  State<SmartTV> createState() => _SmartTVState();
}

class _SmartTVState extends State<SmartTV>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}