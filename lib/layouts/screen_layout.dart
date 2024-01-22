import 'package:bscs_chat/resources/auth_methods.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScreenLayout extends StatefulWidget {
  const ScreenLayout({Key? key}) : super(key: key);

  @override
  State<ScreenLayout> createState() => _ScreenLayoutState();
}

class _ScreenLayoutState extends State<ScreenLayout> {
  int _page = 0;
  PageController pageController = PageController();

  String currentAppName = 'BSCS Chat Room'; // Set initial app name

  Future<String> getUserType() async {
    return await AuthMethods().getCurrentUserType();
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  Future navigationTapped(int page) async {
    setState(() {
      _page = page;
    });
    pageController.jumpToPage(page);
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0.0,
          title: const Text('Welcome'),
        ),
        body: Column(
          children: [

        ],),
        bottomNavigationBar: FutureBuilder<String>(
          future: AuthMethods().getCurrentUserType(),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            String userType = snapshot.data ?? '';
            return CupertinoTabBar(
              onTap: navigationTapped,
              items: userType == 'Staff'
                  ? [
                      buildBottomNavigationBarItem(Icons.calendar_month, 0),
                      buildBottomNavigationBarItem(Icons.add_circle, 1),
                      buildBottomNavigationBarItem(Icons.note_alt, 2),
                      buildBottomNavigationBarItem(Icons.person, 3)
                    ]
                  : userType == 'Officer'
                      ? [
                          buildBottomNavigationBarItem(Icons.calendar_month, 0),
                          buildBottomNavigationBarItem(Icons.feedback, 1),
                          buildBottomNavigationBarItem(Icons.add_circle, 2),
                          buildBottomNavigationBarItem(Icons.note_alt, 3),
                          buildBottomNavigationBarItem(Icons.person, 4)
                        ]
                      : [
                          buildBottomNavigationBarItem(Icons.calendar_month, 0),
                          buildBottomNavigationBarItem(Icons.feedback, 1),
                          buildBottomNavigationBarItem(Icons.note_alt, 2),
                          buildBottomNavigationBarItem(Icons.person, 3)
                        ],
            );
          },
        ),
      ),
    );
  }

  BottomNavigationBarItem buildBottomNavigationBarItem(
      IconData iconData, int pageIndex) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Icon(
          iconData,
          color: _page == pageIndex
              ? Colors.blue
              : Colors.white,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
