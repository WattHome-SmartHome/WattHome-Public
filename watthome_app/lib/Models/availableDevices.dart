class Device {
  final String name;
  final String imageUrl;

  Device({required this.name, required this.imageUrl});
}

final List<Device> availableDevices = [
  Device(name: 'Smart Light', imageUrl: 'assets/Images/devices/lightbulb.png'),
  Device(name: 'Air Conditioner', imageUrl: 'assets/Images/devices/aircon.png'),
  Device(
      name: 'Smart Speaker', imageUrl: 'assets/Images/devices/speaker.png'),
  Device(name: 'Smart TV', imageUrl: 'assets/Images/devices/TV.png'),
  // Add more devices as needed
];
