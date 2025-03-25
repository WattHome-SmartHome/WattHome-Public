import 'package:flutter/material.dart';

class Smartlight extends StatefulWidget {
  const Smartlight({super.key});

  @override
  State<Smartlight> createState() => _SmartlightState();
}

class _SmartlightState extends State<Smartlight>
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