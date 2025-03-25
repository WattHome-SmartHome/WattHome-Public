import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:watthome_app/Dweller/Screens/Rooms/ApplicationScreen.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FrequentlyUsedDevices extends StatefulWidget {
  final List<Map<String, dynamic>> frequentlyUsedDevices;

  const FrequentlyUsedDevices({required this.frequentlyUsedDevices, Key? key})
      : super(key: key);

  @override
  _FrequentlyUsedDevicesState createState() => _FrequentlyUsedDevicesState();
}

class _FrequentlyUsedDevicesState extends State<FrequentlyUsedDevices> {
  List<Map<String, dynamic>> selectedDevices = [];
  List<Map<String, dynamic>> availableDevices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _homeId;
  List<Map<String, dynamic>> devices = [];
  List<Map<String, dynamic>> rooms = [];

  Future<void> _initializeData() async {
    await _getHomeId();
    await _loadFrequentlyUsedDevices();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getHomeId() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final homeId = userDoc['homeId'];
        if (homeId != null) {
          final homeDoc =
              await _firestore.collection('homes').doc(homeId).get();
          if (homeDoc.exists && mounted) {
            setState(() {
              _homeId = homeId;
            });
            await _loadDevicesFromFirebase();
          }
        }
      }
    }
  }

  Future<void> _loadDevicesFromFirebase() async {
    if (_homeId != null) {
      final snapshot = await _firestore
          .collection('homes')
          .doc(_homeId)
          .collection('devices')
          .where('isUsed',
              isEqualTo: false) // Only load devices that are not used
          .get();
      if (mounted) {
        setState(() {
          devices = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add unique ID to each device
            return data;
          }).toList();
          availableDevices = devices; // Populate availableDevices list
        });
      }
    }
  }

  Future<void> _loadFrequentlyUsedDevices() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('frequentlyUsedDevices')
          .get();
      if (mounted) {
        setState(() {
          widget.frequentlyUsedDevices.clear();
          widget.frequentlyUsedDevices
              .addAll(snapshot.docs.map((doc) => doc.data()).toList());
        });
      }
    }
  }

  Future<void> _saveFrequentlyUsedDevices() async {
    setState(() {
      _isLoading = true;
    });
    final user = _auth.currentUser;
    if (user != null) {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final batch = _firestore.batch();

      final devicesCollectionRef =
          userDocRef.collection('frequentlyUsedDevices');
      final existingDevicesSnapshot = await devicesCollectionRef.get();

      // Delete existing devices
      for (final doc in existingDevicesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add new devices
      for (final device in widget.frequentlyUsedDevices) {
        final newDocRef = devicesCollectionRef.doc();
        batch.set(newDocRef, device);
      }

      await batch.commit();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteFrequentlyUsedDevice(Map<String, dynamic> device) async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final devicesCollectionRef =
          userDocRef.collection('frequentlyUsedDevices');
      final deviceDoc = await devicesCollectionRef
          .where('name', isEqualTo: device['name'])
          .limit(1)
          .get();
      if (deviceDoc.docs.isNotEmpty) {
        await devicesCollectionRef.doc(deviceDoc.docs.first.id).delete();
        setState(() {
          widget.frequentlyUsedDevices.remove(device);
        });
      }
    }
  }

  Future<void> _confirmDeleteDevice(Map<String, dynamic> device) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove Device'),
          content: Text('Are you sure you want to remove this device?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteFrequentlyUsedDevice(device);
                Navigator.of(context).pop();
              },
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showDeviceSelectionDialog() {
    setState(() {
      selectedDevices
          .clear(); // Clear selectedDevices list before showing dialog
    });
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Devices'),
              content: SingleChildScrollView(
                child: Column(
                  children: availableDevices.map((device) {
                    final isSelected = selectedDevices.contains(device);
                    final isAlreadyAdded = widget.frequentlyUsedDevices
                        .any((d) => d['customName'] == device['customName']);
                    return CheckboxListTile(
                      title: Text(device['customName']),
                      value: isSelected,
                      onChanged: isAlreadyAdded
                          ? null
                          : (bool? value) {
                              setState(() {
                                if (value == true &&
                                    selectedDevices.length < 4) {
                                  selectedDevices.add(device);
                                } else if (value == false) {
                                  selectedDevices.remove(device);
                                }
                              });
                            },
                      subtitle: isAlreadyAdded
                          ? Text(
                              'Already added',
                              style: TextStyle(color: Colors.red),
                            )
                          : null,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      widget.frequentlyUsedDevices.addAll(selectedDevices);
                    });
                    await _saveFrequentlyUsedDevices();
                    Navigator.of(context).pop();
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Icon _getDeviceIcon(String deviceName) {
    switch (deviceName.toLowerCase()) {
      case 'smart light':
        return Icon(Icons.lightbulb_outline,
            size: 55, color: CustomColors.backgroundColor);
      case 'smart speaker':
        return Icon(Icons.speaker,
            size: 55, color: CustomColors.backgroundColor);
      case 'air conditioner':
        return Icon(Icons.air_rounded,
            size: 55, color: CustomColors.backgroundColor);
      case 'smart tv':
        return Icon(Icons.tv_rounded,
            size: 55, color: CustomColors.backgroundColor);
      default:
        return Icon(Icons.device_unknown,
            size: 55, color: CustomColors.backgroundColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick View',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: CustomColors.primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline_rounded),
                      onPressed: widget.frequentlyUsedDevices.length >= 4
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'You\'ve added the maximum amount of devices'),
                                ),
                              );
                            }
                          : _showDeviceSelectionDialog,
                      iconSize: 30,
                      color: widget.frequentlyUsedDevices.length >= 4
                          ? Colors.grey
                          : CustomColors.primaryColor,
                    ),
                  ],
                ),
                // SizedBox(height: 16.0),
                widget.frequentlyUsedDevices.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            SizedBox(height: 50.0),
                            Icon(Icons.devices_other,
                                size: 55, color: Colors.grey),
                            SizedBox(height: 8.0),
                            Text(
                              'Add some Devices!',
                              style:
                                  TextStyle(fontSize: 16.0, color: Colors.grey),
                            ),
                            SizedBox(height: 50.0),
                          ],
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Change to 2 columns
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                        ),
                        itemCount: widget.frequentlyUsedDevices.length,
                        itemBuilder: (context, index) {
                          final device = widget.frequentlyUsedDevices[index];
                          final deviceName = device['name'] ?? 'Unknown Device';
                          final customName = device['customName'] ?? deviceName;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ApplicationScreen(
                                    item: deviceName,
                                    deviceid: device['deviceId'],
                                  ),
                                ),
                              );
                            },
                            onLongPress: () async {
                              await _confirmDeleteDevice(device);
                            },
                            child: Card(
                              color: CustomColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 5,
                              shadowColor: Colors.grey.withOpacity(0.5),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _getDeviceIcon(
                                        deviceName), // Add icon based on device name
                                    SizedBox(height: 8.0),
                                    Text(
                                      customName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w500,
                                        color: CustomColors.backgroundColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
