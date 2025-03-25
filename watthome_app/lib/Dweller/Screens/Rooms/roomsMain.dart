import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:watthome_app/Models/customColors.dart';
import 'package:watthome_app/Widgets/navbar-dweller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watthome_app/Widgets/weather_widget.dart';
import 'package:watthome_app/Dweller/Screens/Rooms/ApplicationScreen.dart';
import 'package:watthome_app/Models/availableDevices.dart';
import 'package:watthome_app/Widgets/textField.dart';
import 'package:watthome_app/Widgets/customDropdown.dart';
import '../Rooms/roomsScreen.dart';
// import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';

// Declare global variables to hold the state
FirebaseFirestore _firestore = FirebaseFirestore.instance;
FirebaseAuth _auth = FirebaseAuth.instance;
String? _homeId;
List<Map<String, dynamic>> devices = [];
List<Map<String, dynamic>> rooms = [];
bool _isLoading = false; // Make _isLoading global

// Declare a global function to trigger the refresh data
Future<void> refreshData(RoomsScreenState roomsScreenState) async {
  print("Refreshing data (global function)...");
  roomsScreenState.setState(() {
    _isLoading = true;
  });
  await loadRoomsFromFirebase(roomsScreenState);
  await loadDevicesFromFirebase(roomsScreenState);
  roomsScreenState.setState(() {
    _isLoading = false;
  });
}

// Declare global functions to load data
Future<void> loadDevicesFromFirebase(RoomsScreenState roomsScreenState) async {
  if (_homeId != null) {
    final snapshot = await _firestore
        .collection('homes')
        .doc(_homeId)
        .collection('devices')
        .where('isUsed',
            isEqualTo: false) // Only load devices that are not used
        .get();
    if (roomsScreenState.mounted) {
      roomsScreenState.setState(() {
        devices = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Add unique ID to each device
          return data;
        }).toList();
      });
    }
  }
}

Future<void> loadRoomsFromFirebase(RoomsScreenState roomsScreenState) async {
  if (_homeId != null) {
    final snapshot = await _firestore
        .collection('homes')
        .doc(_homeId)
        .collection('rooms')
        .get();
    if (roomsScreenState.mounted) {
      List<Map<String, dynamic>> loadedRooms = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> roomData = doc.data();
        roomData['id'] = doc.id;
        final devicesSnapshot = await doc.reference.collection('devices').get();
        roomData['devices'] =
            devicesSnapshot.docs.map((deviceDoc) => deviceDoc.data()).toList();
        loadedRooms.add(roomData);
      }
      roomsScreenState.setState(() {
        rooms = loadedRooms;
      });
    }
  }
}

Future<void> getHomeId(RoomsScreenState roomsScreenState) async {
  final user = _auth.currentUser;
  if (user != null) {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final homeId = userDoc['homeId'];
      if (homeId != null) {
        final homeDoc = await _firestore.collection('homes').doc(homeId).get();
        if (homeDoc.exists && roomsScreenState.mounted) {
          roomsScreenState.setState(() {
            _homeId = homeId;
          });
          loadDevicesFromFirebase(roomsScreenState);
          loadRoomsFromFirebase(roomsScreenState);
        }
      }
    }
  }
}

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({Key? key}) : super(key: key);

  @override
  RoomsScreenState createState() => RoomsScreenState();
}

class RoomsScreenState extends State<RoomsScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    getHomeId(this);
    _scrollController.addListener(_scrollListener);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
        _animationController.forward();
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showAddRoomPage(BuildContext context) {
    (context.findAncestorStateOfType<NavbarDwellerState>())
        ?.toggleNavBarVisibility(false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddRoomBottomSheet(
        devices: devices,
        onRoomAdded: () => loadRoomsFromFirebase(this),
      ),
    ).whenComplete(() {
      (context.findAncestorStateOfType<NavbarDwellerState>())
          ?.toggleNavBarVisibility(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < 0) {
          if (!_isFabVisible) {
            setState(() {
              _isFabVisible = true;
            });
            _animationController.reverse();
          }
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: CustomColors.backgroundColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 17, 16, 10),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: CustomColors.primaryColor,
                        )
                      : const WeatherWidget(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    constraints:
                        BoxConstraints(maxWidth: 800), // Add constraint
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEE2E7),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TabBar(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: CustomColors.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                        shape: BoxShape.rectangle,
                        border: Border.all(
                            color: CustomColors.primaryColor, width: 2),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black,
                      indicatorPadding:
                          const EdgeInsets.fromLTRB(-55, 5, -55, 5),
                      tabs: const [
                        Tab(text: "Rooms"),
                        Tab(text: "Devices"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 800), // Add constraint
              child: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: () =>
                        refreshData(this), // Use the global function
                    color: CustomColors.primaryColor,
                    child: RoomScreen(
                      showAddRoomPage: _showAddRoomPage,
                      rooms: rooms,
                      scrollController: _scrollController,
                      isFabVisible: _isFabVisible,
                      offsetAnimation: _offsetAnimation,
                      opacityAnimation: _opacityAnimation,
                      roomsScreenState: this, // Pass the state to RoomScreen
                    ),
                  ),
                  DevicesScreen(devices: devices),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoomScreen extends StatefulWidget {
  final Function(BuildContext) showAddRoomPage;
  final List<Map<String, dynamic>> rooms;
  final ScrollController scrollController;
  final bool isFabVisible;
  final Animation<Offset> offsetAnimation;
  final Animation<double> opacityAnimation;
  final RoomsScreenState roomsScreenState; // Receive the state

  const RoomScreen({
    required this.showAddRoomPage,
    required this.rooms,
    required this.scrollController,
    required this.isFabVisible,
    required this.offsetAnimation,
    required this.opacityAnimation,
    required this.roomsScreenState,
    Key? key,
  }) : super(key: key);

  @override
  _RoomScreenState createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  Widget _getDeviceImage(String deviceName) {
    final device = availableDevices.firstWhere(
      (device) => device.name.toLowerCase() == deviceName.toLowerCase(),
      orElse: () =>
          Device(name: 'Unknown', imageUrl: 'assets/Images/unknown.png'),
    );
    return Image.asset(device.imageUrl, width: 40, height: 40);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.rooms.isEmpty
            ? const Center(
                child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.meeting_room_rounded,
                      size: 100,
                      color: CustomColors.textAccentColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Create your first room!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ))
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  controller: widget.scrollController,
                  itemCount: widget.rooms.length,
                  itemBuilder: (context, index) {
                    final room = widget.rooms[index];
                    final roomDevices = room['devices'] as List<dynamic>? ?? [];
                    bool isEditExpanded = false;

                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Card(
                          margin: const EdgeInsets.fromLTRB(18, 5, 18, 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                      ),
                                      child: room['imageNum'] != null
                                          ? Hero(
                                              tag:
                                                  'roomImage_${room['imageNum']}_${room['name']}', // Unique tag for each room image
                                              child: Image.asset(
                                                'assets/Images/rooms/${room['imageNum']}.png',
                                                height: 150,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Image.asset(
                                              'assets/Images/roomPlaceholder.jpg', // Replace with actual placeholder image path
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 500),
                                            padding: isEditExpanded
                                                ? const EdgeInsets.symmetric(
                                                    horizontal: 1.0)
                                                : EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              color: isEditExpanded
                                                  ? CustomColors.primaryColor
                                                  : CustomColors
                                                      .backgroundColor,
                                              borderRadius:
                                                  BorderRadius.circular(90),
                                            ),
                                            child: Row(
                                              children: [
                                                if (isEditExpanded)
                                                  TextButton(
                                                    onPressed: () {
                                                      _showEditRoomBottomSheet(
                                                          context, room);
                                                    },
                                                    child: const Text(
                                                      'Edit',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: isEditExpanded
                                                        ? CustomColors
                                                            .primaryColor
                                                        : Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: IconButton(
                                                    icon: Icon(
                                                      isEditExpanded
                                                          ? Icons.close
                                                          : Icons.edit,
                                                      color: isEditExpanded
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        isEditExpanded =
                                                            !isEditExpanded;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Row(
                                            children: roomDevices.map((device) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.white,
                                                  child: GestureDetector(
                                                    // onTap: () {
                                                    //   print("  fesfsefsefesf $device['name']");
                                                    //   Navigator.push(
                                                    //     context,
                                                    //     MaterialPageRoute(
                                                    //       builder: (context) =>
                                                    //           ApplicationScreen(
                                                    //         item:
                                                    //             device['name'],
                                                    //       ),
                                                    //     ),
                                                    //   );
                                                    // },
                                                    child: _getDeviceImage(
                                                        device['name']),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.chevron_right_rounded),
                                            iconSize: 30,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      RoomPage(
                                                    roomName: room['name'],
                                                    devices: roomDevices,
                                                    imageNum: room[
                                                        'imageNum'], // Pass imageNum parameter
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: SlideTransition(
            position: widget.offsetAnimation,
            child: FadeTransition(
              opacity: widget.opacityAnimation,
              child: FloatingActionButton(
                shape: ShapeBorder.lerp(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(90),
                  ),
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(90),
                  ),
                  0.5,
                ),
                onPressed: () => widget.showAddRoomPage(context),
                backgroundColor: CustomColors.primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditRoomBottomSheet(
      BuildContext context, Map<String, dynamic> room) {
    (context.findAncestorStateOfType<NavbarDwellerState>())
        ?.toggleNavBarVisibility(false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditRoomBottomSheet(
        room: room,
        onRoomUpdated: () async {
          await refreshData(widget.roomsScreenState);
        },
        roomsScreenState: widget.roomsScreenState, // Pass state
      ),
    ).whenComplete(() {
      (context.findAncestorStateOfType<NavbarDwellerState>())
          ?.toggleNavBarVisibility(true);
    });
  }
}

class DevicesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> devices;

  const DevicesScreen({required this.devices, Key? key}) : super(key: key);

  Widget _getDeviceImage(String deviceName) {
    final device = availableDevices.firstWhere(
      (device) => device.name.toLowerCase() == deviceName.toLowerCase(),
      orElse: () =>
          Device(name: 'Unknown', imageUrl: 'assets/Images/unknown.png'),
    );
    return Image.asset(device.imageUrl, width: 40, height: 40);
  }

  @override
  Widget build(BuildContext context) {
    return devices.isEmpty
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
                  'No devices found!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ))
        : ListView.builder(
            itemCount: devices.length + 1, // Increment itemCount by 1
            itemBuilder: (context, index) {
              if (index == devices.length) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(
                        'Want to add a new device?\nContact your admin!',
                        style: TextStyle(
                            fontSize: 16, color: CustomColors.textAccentColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }
              final device = devices[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  child: ListTile(
                    leading: _getDeviceImage(device['name']),
                    title: Text(device['customName'] ?? device['name']),
                    subtitle: Text(device['name']),
                    trailing: IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      iconSize: 30,
                      onPressed: () {
                        print("efssefesfesf2 $device['name']");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ApplicationScreen(
                                item: device['name'],
                                deviceid: device['deviceId']),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
  }
}

class _AddRoomBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> devices;
  final VoidCallback onRoomAdded;

  const _AddRoomBottomSheet(
      {required this.devices, required this.onRoomAdded, Key? key})
      : super(key: key);

  @override
  __AddRoomBottomSheetState createState() => __AddRoomBottomSheetState();
}

class __AddRoomBottomSheetState extends State<_AddRoomBottomSheet> {
  final List<String> _roomNames = [
    'Living-room',
    'Kitchen',
    'TV-Lobby',
    'Bedroom'
  ];
  String? _selectedRoomName;
  final List<Map<String, dynamic>> _selectedDevices = [];
  String? _imageUrl;
  final TextEditingController _customRoomNameController =
      TextEditingController();
  String? _imageNum;

  bool get _isSaveButtonEnabled {
    return _selectedRoomName != null &&
        _customRoomNameController.text.trim().isNotEmpty &&
        _selectedDevices.isNotEmpty;
  }

  void _updateRoomImage(String roomType) {
    switch (roomType) {
      case 'Living-room':
        _imageNum = 'room1';
        break;
      case 'Kitchen':
        _imageNum = 'room2';
        break;
      case 'TV-Lobby':
        _imageNum = 'room3';
        break;
      case 'Bedroom':
        _imageNum = 'room4';
        break;
      default:
        _imageNum = null;
    }
  }

  Icon _getDeviceIcon(String deviceName) {
    switch (deviceName.toLowerCase()) {
      case 'smart light':
        return const Icon(Icons.lightbulb);
      case 'smart speaker':
        return const Icon(Icons.speaker);
      case 'smart tv':
        return const Icon(Icons.tv);
      case 'air conditioner':
        return const Icon(Icons.ac_unit);
      default:
        return const Icon(Icons.device_hub);
    }
  }

  Future<void> _saveRoom() async {
    final roomType = _selectedRoomName;
    final customRoomName = _customRoomNameController.text.trim();

    if (roomType == null || customRoomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select a room type and enter a custom room name.')),
      );
      return;
    }

    if (_selectedDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one device.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final homeId = userDoc['homeId'];

      if (homeId != null) {
        final roomDoc = await FirebaseFirestore.instance
            .collection('homes')
            .doc(homeId)
            .collection('rooms')
            .add({
          'name': customRoomName,
          'type': roomType,
          'imageUrl': _imageUrl,
          'imageNum': _imageNum,
        });

        for (var device in _selectedDevices) {
          await roomDoc.collection('devices').add(device);
        }

        widget.onRoomAdded();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Container(
        decoration: const BoxDecoration(
          color: CustomColors.backgroundColor,
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
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                  image: _imageNum != null
                      ? DecorationImage(
                          image:
                              AssetImage('assets/Images/rooms/$_imageNum.png'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageNum == null
                    ? const Icon(Icons.house_rounded,
                        size: 50, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('Enter a custom room name:'),
              const SizedBox(height: 5),
              CustomTextField(
                controller: _customRoomNameController,
                hintText: 'Enter custom room name',
                maxLength: 20,
              ),
              const SizedBox(height: 5),
              const Text('Select your room type:'),
              const SizedBox(height: 5),
              CustomDropdown(
                value: _selectedRoomName,
                hintText: 'Select room type',
                items: _roomNames,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRoomName = newValue;
                    _updateRoomImage(newValue!);
                  });
                },
              ),
              const SizedBox(height: 5),
              const Text('Select devices to pair with the room:'),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.devices.length,
                  itemBuilder: (context, index) {
                    final device = widget.devices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          device['customName'] ?? device['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(device['name']),
                        value: _selectedDevices.contains(device),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedDevices.add(device);
                            } else {
                              _selectedDevices.remove(device);
                            }
                          });
                        },
                        activeColor: CustomColors.primaryColor,
                        checkColor: Colors.white,
                        secondary: _getDeviceIcon(device['name']),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 5),
              Center(
                child: ElevatedButton(
                  onPressed: _isSaveButtonEnabled ? _saveRoom : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _isSaveButtonEnabled
                        ? CustomColors.primaryColor
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditRoomBottomSheet extends StatefulWidget {
  final Map<String, dynamic> room;
  final Future<void> Function() onRoomUpdated;
  final RoomsScreenState roomsScreenState; // Receive the state

  const _EditRoomBottomSheet({
    required this.room,
    required this.onRoomUpdated,
    required this.roomsScreenState,
    Key? key,
  }) : super(key: key);

  @override
  __EditRoomBottomSheetState createState() => __EditRoomBottomSheetState();
}

class __EditRoomBottomSheetState extends State<_EditRoomBottomSheet> {
  final List<String> _roomNames = [
    'Living-room',
    'Kitchen',
    'TV-Lobby',
    'Bedroom'
  ];
  String? _selectedRoomName;
  late List<Map<String, dynamic>> _selectedDevices;
  String? _imageUrl;
  final TextEditingController _customRoomNameController =
      TextEditingController();
  String? _imageNum;

  bool get _isSaveButtonEnabled {
    return _selectedRoomName != null &&
        _customRoomNameController.text.trim().isNotEmpty &&
        _selectedDevices.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _selectedRoomName = widget.room['type'];
    _customRoomNameController.text = widget.room['name'];
    _selectedDevices = List<Map<String, dynamic>>.from(widget.room['devices']);
    _imageNum = widget.room['imageNum'];
  }

  void _updateRoomImage(String roomType) {
    switch (roomType) {
      case 'Living-room':
        _imageNum = 'room1';
        break;
      case 'Kitchen':
        _imageNum = 'room2';
        break;
      case 'TV-Lobby':
        _imageNum = 'room3';
        break;
      case 'Bedroom':
        _imageNum = 'room4';
        break;
      default:
        _imageNum = null;
    }
  }

  Icon _getDeviceIcon(String deviceName) {
    switch (deviceName.toLowerCase()) {
      case 'smart light':
        return const Icon(Icons.lightbulb);
      case 'smart speaker':
        return const Icon(Icons.speaker);
      case 'smart tv':
        return const Icon(Icons.tv);
      case 'air conditioner':
        return const Icon(Icons.ac_unit);
      default:
        return const Icon(Icons.device_hub);
    }
  }

  Future<void> _saveRoom() async {
    final roomType = _selectedRoomName;
    final customRoomName = _customRoomNameController.text.trim();

    if (roomType == null || customRoomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select a room type and enter a custom room name.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final homeId = userDoc['homeId'];

      if (homeId != null) {
        final roomDoc = FirebaseFirestore.instance
            .collection('homes')
            .doc(homeId)
            .collection('rooms')
            .doc(widget.room['id']);

        await roomDoc.update({
          'name': customRoomName,
          'type': roomType,
          'imageUrl': _imageUrl,
          'imageNum': _imageNum,
        });

        final devicesCollection = roomDoc.collection('devices');
        final existingDevicesSnapshot = await devicesCollection.get();

        // Remove existing devices
        for (var doc in existingDevicesSnapshot.docs) {
          await doc.reference.delete();
        }

        // Add updated devices
        for (var device in _selectedDevices) {
          await devicesCollection.add(device);
        }

        widget.onRoomUpdated();

        // Use the global refreshData
        await refreshData(widget.roomsScreenState);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final homeId = userDoc['homeId'];

      if (homeId != null) {
        final roomDoc = FirebaseFirestore.instance
            .collection('homes')
            .doc(homeId)
            .collection('rooms')
            .doc(widget.room['id']);

        try {
          await roomDoc.delete(); // Await the deletion

          widget
              .onRoomUpdated(); // Await the onRoomUpdated function from the RoomScreen

          Navigator.pop(context); // Close the bottom sheet
        } catch (e) {
          print("Error deleting room: $e");
          // Handle the error appropriately (e.g., show a snackbar)
        }
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: const Text('Are you sure you want to delete this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoom();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Container(
        decoration: const BoxDecoration(
          color: CustomColors.backgroundColor,
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
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                  image: _imageNum != null
                      ? DecorationImage(
                          image:
                              AssetImage('assets/Images/rooms/$_imageNum.png'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageNum == null
                    ? const Icon(Icons.face_2_rounded,
                        size: 50, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 10),
              const Text('Enter a custom room name:'),
              const SizedBox(height: 5),
              CustomTextField(
                controller: _customRoomNameController,
                hintText: 'Enter custom room name',
                maxLength: 20,
              ),
              const Text('Select your room type:'),
              const SizedBox(height: 5),
              CustomDropdown(
                value: _selectedRoomName,
                hintText: 'Select room type',
                items: _roomNames,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRoomName = newValue;
                    _updateRoomImage(newValue!);
                  });
                },
              ),
              const SizedBox(height: 5),
              const Text('Select devices to pair with the room:'),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.room['devices'].length,
                  itemBuilder: (context, index) {
                    final device = widget.room['devices'][index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          device['customName'] ?? device['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(device['name']),
                        value: _selectedDevices.contains(device),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedDevices.add(device);
                            } else {
                              _selectedDevices.remove(device);
                            }
                          });
                        },
                        activeColor: CustomColors.primaryColor,
                        checkColor: Colors.white,
                        secondary: _getDeviceIcon(device['name']),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isSaveButtonEnabled ? _saveRoom : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _isSaveButtonEnabled
                            ? CustomColors.primaryColor
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(150, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                    TextButton(
                      onPressed: _showDeleteConfirmationDialog,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size(150, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Delete Room'),
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
