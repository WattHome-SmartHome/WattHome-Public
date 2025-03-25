import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:watthome_app/Dweller/Screens/DashBoard/dashBoardMain.dart';
import 'package:watthome_app/Dweller/Screens/Profile/profileMain.dart';
import 'package:watthome_app/Dweller/Screens/Rooms/roomsMain.dart';
import 'package:watthome_app/Dweller/Screens/Tasks/tasksMain.dart';
import 'package:watthome_app/Models/customColors.dart';

class NavbarDweller extends StatefulWidget {
  const NavbarDweller({super.key});

  @override
  State<NavbarDweller> createState() => NavbarDwellerState();
}

class NavbarDwellerState extends State<NavbarDweller> {
  late PersistentTabController _controller;
  bool _isNavBarVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  void toggleNavBarVisibility(bool isVisible) {
    setState(() {
      _isNavBarVisible = isVisible;
    });
  }

  List<Widget> _buildScreens() {
    return [
      DwellerHomeScreen(),
      const RoomsScreen(),
      TaskScreen(),
      const ProfileScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: ("DashBoard"),
        activeColorPrimary: const Color.fromARGB(255, 255, 255, 255),
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.meeting_room),
        title: ("Rooms"),
        activeColorPrimary: const Color.fromARGB(255, 255, 255, 255),
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.task),
        title: ("Tasks"),
        activeColorPrimary: const Color.fromARGB(255, 255, 255, 255),
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        title: ("Profile"),
        activeColorPrimary: const Color.fromARGB(255, 255, 255, 255),
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PersistentTabView(
          context,
          controller: _controller,
          screens: _buildScreens(),
          items: _navBarsItems(),
          confineToSafeArea: true,
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          isVisible: _isNavBarVisible,
          handleAndroidBackButtonPress: true,
          resizeToAvoidBottomInset: true,
          stateManagement: true,
          decoration: NavBarDecoration(
            borderRadius: BorderRadius.circular(15.0),
            colorBehindNavBar: CustomColors.backgroundColor,
          ),
          navBarStyle: NavBarStyle.style9,
          margin: EdgeInsets.symmetric(
            horizontal:
                constraints.maxWidth > 600 ? constraints.maxWidth * 0.2 : 20,
          ),
        );
      },
    );
  }
}
