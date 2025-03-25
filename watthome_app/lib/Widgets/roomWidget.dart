import 'package:flutter/material.dart';

class RoomButton extends StatelessWidget {
  final String roomName;
  final int devicesOn;
  final IconData icon;
  final VoidCallback onTap; // Callback for tap event

  const RoomButton({
    super.key,
    required this.roomName,
    required this.devicesOn,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // Or GestureDetector for more control
      onTap: onTap, // Call the provided callback
      borderRadius: BorderRadius.circular(10), // Match the design
      child: Container(
        padding: const EdgeInsets.all(16), // Adjust padding as needed
        decoration: BoxDecoration(
          color: Colors.grey[200], // Or Theme.of(context).cardColor
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30), // Room icon
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roomName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$devicesOn devices on'),
              ],
            ),
            const Spacer(), // Push the kilowatt info to the right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('1000 Kw/h'),
                Text('+11.2%', style: TextStyle(color: Colors.red[400])), // Example color
              ],
            ),
          ],
        ),
      ),
    );
  }
}