import 'package:flutter/material.dart';

class Smartspeaker extends StatefulWidget {
  const Smartspeaker({super.key});

  @override
  State<Smartspeaker> createState() => _SmartspeakerState();
}

class _SmartspeakerState extends State<Smartspeaker>
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