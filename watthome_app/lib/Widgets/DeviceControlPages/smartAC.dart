import 'package:flutter/material.dart';

class SmartAC extends StatefulWidget {
  const SmartAC({super.key});

  @override
  State<SmartAC> createState() => _SmartACState();
}

class _SmartACState extends State<SmartAC>
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