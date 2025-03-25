import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Widgets/navbar-admin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:watthome_app/Widgets/textField.dart';
import '../../../../Models/availableDevices.dart';

class Manageappliancepage extends StatefulWidget {
  const Manageappliancepage({super.key});

  @override
  State<Manageappliancepage> createState() => _ManageappliancepageState();
}

class _ManageappliancepageState extends State<Manageappliancepage> {
  final info = NetworkInfo();
  List<String> appliances = [];
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _homeId;

  @override
  void initState() {
    super.initState();
    setNetwork();
    _getHomeId(); // _loadDevicesFromFirebase() will be called inside _getHomeId()
  }

  Future<void> setNetwork() async {
    // Request location permission
    var locationStatus = await Permission.location.status;
    if (locationStatus.isDenied) {
      await Permission.locationWhenInUse.request();
    }
    if (await Permission.location.isRestricted) {
      openAppSettings();
    }

    // Check if location permission is granted
    if (await Permission.location.isGranted) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _getHomeId() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final homeId = userDoc['homeId'];
        if (homeId != null) {
          final homeDoc = await FirebaseFirestore.instance
              .collection('homes')
              .doc(homeId)
              .get();
          if (homeDoc.exists) {
            if (mounted) {
              setState(() {
                _homeId = homeDoc.id;
              });
              _loadDevicesFromFirebase(); // Load devices after _homeId is set
            }
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
          .get();
      final devices =
          snapshot.docs.map((doc) => doc['name'] as String).toList();
      if (mounted) {
        setState(() {
          appliances = devices;
        });
      }
    }
  }

  Future<void> _deleteDevice(String deviceId) async {
    if (_homeId != null) {
      await _firestore
          .collection('homes')
          .doc(_homeId)
          .collection('devices')
          .doc(deviceId)
          .delete();
      _loadDevicesFromFirebase();
    }
  }

  Future<void> _showDeleteDialog(String deviceId) async {
    AwesomeDialog(
      padding: const EdgeInsets.all(16),
      dialogBorderRadius: BorderRadius.all(
        Radius.circular(15),
      ),
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Warning',
      titleTextStyle: TextStyle(
        color: CustomColors.textColor,
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
      desc:
          'Are you sure you want to delete this device? You will have to re-pair it to use it again.',
      descTextStyle: TextStyle(
        color: CustomColors.textColor,
        fontSize: 16,
      ),
      btnCancelOnPress: () {},
      btnCancelColor: CustomColors.successColor,
      btnOkOnPress: () {
        _deleteDevice(deviceId);
      },
      btnOkColor: CustomColors.errorColor,
    ).show();
  }

  void _showAvailableDevices() {
    setState(() {
      _isLoading = true;
    });

    // Hide the bottom navbar
    (context.findAncestorStateOfType<NavbarAdminState>())
        ?.toggleNavBarVisibility(false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _AvailableDevicesBottomSheet(isLoading: _isLoading);
      },
    ).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
      // Show the bottom navbar
      (context.findAncestorStateOfType<NavbarAdminState>())
          ?.toggleNavBarVisibility(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Appliances'),
        backgroundColor: CustomColors.backgroundColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.info_outline, size: 30),
              onPressed: () {
                // showDialog(
                //   context: context,
                //   builder: (context) {
                //     return AlertDialog(
                //       backgroundColor: CustomColors.secondaryAccentColor,
                //       title: const Text('Tip',
                //           style: TextStyle(
                //               fontSize: 25,
                //               color: CustomColors.secondaryColor)),
                //       content: const Text(
                //           'Want to remove a device? Swipe left on the device and tap delete.',
                //           style: TextStyle(fontSize: 16)),
                //       actions: [
                //         TextButton(
                //           onPressed: () {
                //             Navigator.of(context).pop();
                //           },
                //           child: const Text('OK',
                //               style: TextStyle(
                //                   fontSize: 25,
                //                   color: CustomColors.secondaryColor)),
                //         ),
                //       ],
                //     );
                //   },
                // );
                AwesomeDialog(
                  padding: const EdgeInsets.all(16),
                  dialogBorderRadius: BorderRadius.circular(15),
                  context: context,
                  dialogType: DialogType.info,
                  animType: AnimType.scale,
                  title: 'Tip',
                  titleTextStyle: TextStyle(
                    color: CustomColors.textColor,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  desc:
                      'Want to remove a device? Swipe left on the device and tap delete.',
                  descTextStyle: TextStyle(
                    color: CustomColors.textColor,
                    fontSize: 16,
                  ),
                  btnOkOnPress: () {},
                  btnOkColor: CustomColors.primaryColor,
                ).show();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: appliances.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_other,
                            size: 100,
                            color: CustomColors.textAccentColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Add your first smart device to get started!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                color: CustomColors.textAccentColor),
                          ),
                        ],
                      ),
                    ),
                  )
                : FutureBuilder<QuerySnapshot>(
                    future: _firestore
                        .collection('homes')
                        .doc(_homeId)
                        .collection('devices')
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading devices'),
                        );
                      }
                      final devices = snapshot.data?.docs ?? [];
                      if (devices.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.devices_other,
                                  size: 100,
                                  color: CustomColors.textAccentColor,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Add your first smart device to get started!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: CustomColors.textAccentColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          final deviceType = device['name'];
                          final deviceImage = availableDevices
                              .firstWhere(
                                (d) => d.name == deviceType,
                                orElse: () => Device(
                                    name: 'Unknown',
                                    imageUrl:
                                        'assets/Images/DefaultDevice.png'),
                              )
                              .imageUrl;

                          return Slidable(
                            key: UniqueKey(),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) async {
                                    await _showDeleteDialog(device.id);
                                  },
                                  backgroundColor: CustomColors.errorColor,
                                  foregroundColor: CustomColors.backgroundColor,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                ),
                              ],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Card(
                                color: CustomColors.tileColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(90),
                                ),
                                child: ListTile(
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 6.0),
                                  leading: CircleAvatar(
                                    radius: 30,
                                    backgroundColor:
                                        Colors.white, // Set background to white
                                    backgroundImage: AssetImage(deviceImage),
                                  ),
                                  title: Text(
                                    device['customName'] ?? device['name'],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(device['name']),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAvailableDevices();
        },
        backgroundColor: CustomColors.primaryColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(90)),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

//-------------------------------------------------------------------------------------

class _AvailableDevicesBottomSheet extends StatefulWidget {
  final bool isLoading;

  const _AvailableDevicesBottomSheet({required this.isLoading});

  @override
  State<_AvailableDevicesBottomSheet> createState() =>
      _AvailableDevicesBottomSheetState();
}

class _AvailableDevicesBottomSheetState
    extends State<_AvailableDevicesBottomSheet> {
  bool _internalIsLoading = false;
  String? _wifiName = 'Unknown';

  @override
  void initState() {
    super.initState();
    _internalIsLoading = widget.isLoading;
    _setNetwork();
    if (_internalIsLoading) {
      _loadDevices();
    }
  }

  Future<void> _setNetwork() async {
    final info = NetworkInfo();
    var locationStatus = await Permission.location.status;
    if (locationStatus.isDenied) {
      await Permission.locationWhenInUse.request();
    }
    if (await Permission.location.isRestricted) {
      openAppSettings();
    }

    if (await Permission.location.isGranted) {
      var wifiName = await info.getWifiName();
      if (mounted) {
        setState(() {
          _wifiName = wifiName;
        });
      }
    }
  }

  Future<void> _loadDevices() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _internalIsLoading = false;
      });
    }
  }

  Future<void> _promptForCustomName(String deviceInfo) async {
    TextEditingController customNameController = TextEditingController();
    bool isNameEntered = false;

    await AwesomeDialog(
      borderSide: BorderSide(color: CustomColors.primaryColor, width: 2),
      dialogBorderRadius: BorderRadius.circular(15),
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      title: 'Enter Custom Name',
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CustomTextField(
              controller: customNameController,
              hintText: 'Enter a device name!',
              maxLength: 15,
            )
          ],
        ),
      ),
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        if (customNameController.text.isNotEmpty) {
          isNameEntered = true;
        } else {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            animType: AnimType.scale,
            title: 'Error',
            desc: 'Device name cannot be empty!',
            btnOkOnPress: () {},
            btnOkColor: CustomColors.errorColor,
          ).show();
        }
      },
      btnOkColor: CustomColors.primaryColor,
    ).show();

    if (isNameEntered) {
      await addDeviceToFirebase(deviceInfo, customNameController.text);
    }
  }

  Future<void> addDeviceToFirebase(String deviceName, String customName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final homeId = userDoc['homeId'];

      if (homeId != null) {
        final devicesRef = FirebaseFirestore.instance
            .collection('homes')
            .doc(homeId)
            .collection('devices');

        // Count only devices with the same type (deviceName)
        final snapshot = await devicesRef
            .where('name', isEqualTo: deviceName) // Filter by type
            .get();

        int deviceId =
            snapshot.docs.length + 1; // Start at 1, increment per type

        await devicesRef.add({
          'deviceId': deviceId,
          'name': deviceName,
          'customName': customName,
          'isUsed': false,
        });

        (context.findAncestorStateOfType<_ManageappliancepageState>())
            ?._loadDevicesFromFirebase();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CustomColors.backgroundColor,
              CustomColors.backgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Search',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Connected to: $_wifiName',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CustomColors.textAccentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _internalIsLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                              color: CustomColors.primaryColor,
                            ))
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: availableDevices.length,
                              itemBuilder: (context, index) {
                                final device = availableDevices[index];
                                return GestureDetector(
                                  onTap: () async {
                                    await _promptForCustomName(device.name);
                                    Navigator.pop(context);
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    color: CustomColors.tileColor,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            boxShadow: [
                                              BoxShadow(
                                                color: CustomColors
                                                    .secondaryColor
                                                    .withOpacity(0.3),
                                                spreadRadius: 0.1,
                                                blurRadius: 30,
                                              ),
                                            ],
                                          ),
                                          child: Image.asset(
                                            device.imageUrl,
                                            height: 80,
                                            width: 80,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.error,
                                                size: 80,
                                                color: CustomColors.errorColor,
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(device.name),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Didn\'t find your device?',
                            style: TextStyle(
                              color: CustomColors.textAccentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ElevatedButton.icon(
                    //   onPressed: () {},
                    //   icon: const Icon(Icons.qr_code_scanner_rounded),
                    //   label: const Text('Scan QR Code'),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: CustomColors.primaryColor,
                    //     foregroundColor: Colors.white,
                    //     iconColor: Colors.white,
                    //     minimumSize: const Size(double.infinity, 50),
                    //   ),
                    // ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: CustomColors.textAccentColor,
                        ),
                        const SizedBox(width: 6),
                        Text.rich(TextSpan(
                          text:
                              'Try resetting your device if it doesn\'t show up.',
                          style: TextStyle(
                            color: CustomColors.textAccentColor,
                            // fontWeight: FontWeight.bold,
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
