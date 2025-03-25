import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:watthome_app/Admin/Screens/DashBoard/dashBoardMain.dart';
import 'package:watthome_app/Admin/Screens/Family/addUser.dart';
import 'package:watthome_app/Admin/Screens/Profile/profileMain.dart';
import 'package:watthome_app/Admin/Screens/Reports/reportsPage.dart';
import 'package:watthome_app/Models/customColors.dart';

class NavbarAdmin extends StatefulWidget {
  const NavbarAdmin({super.key});

  @override
  NavbarAdminState createState() => NavbarAdminState();
}

class NavbarAdminState extends State<NavbarAdmin> {
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);
  bool _isNavBarVisible = true;

  List<Widget> _buildScreens() {
    return [
      const DashboardMain(), // Page for dashboard
      const Reportspage(), // Page for reports
      const AddUserPage(), // Page for adding users
      const AdminProfileScreen(), // Page for admin profile
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.dashboard_rounded),
        title: ("Dashboard"),
        activeColorPrimary: const Color.fromARGB(255, 255, 255, 255),
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.content_paste_rounded),
        title: ("Reports"),
        activeColorPrimary: const Color.fromARGB(255, 255, 255, 255),
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.add_home_rounded),
        title: ("My Home"),
        activeColorPrimary: const Color.fromARGB(255, 255, 255, 255),
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.settings),
        title: ("Settings"),
        activeColorPrimary: const Color.fromARGB(255, 255, 255, 255),
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  void toggleNavBarVisibility(bool isVisible) {
    setState(() {
      _isNavBarVisible = isVisible;
    });
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
          handleAndroidBackButtonPress: true,
          hideNavigationBarWhenKeyboardAppears: true,
          isVisible: _isNavBarVisible,
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
