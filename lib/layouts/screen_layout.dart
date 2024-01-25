// ignore_for_file: use_build_context_synchronously
import 'package:bscs_chat/models/profile.dart' as model;
import 'package:bscs_chat/models/user.dart' as model;
import 'package:bscs_chat/resources/auth_methods.dart';
import 'package:bscs_chat/resources/firestore_user_methods.dart';
import 'package:bscs_chat/widgets/chat_list.dart';
import 'package:bscs_chat/widgets/text_field_input.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../widgets/cs_logo.dart';

class ScreenLayout extends StatefulWidget {
  const ScreenLayout({Key? key}) : super(key: key);

  @override
  State<ScreenLayout> createState() => _ScreenLayoutState();
}

class _ScreenLayoutState extends State<ScreenLayout> {
  ScreenType _currentScreen = ScreenType.chat; 
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Controllers and variables for profile screen
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  Uint8List? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  String _getAppBarTitle() {
    switch (_currentScreen) {
      case ScreenType.chat:
        return 'Chat';
      case ScreenType.about:
        return 'About';
      case ScreenType.profile:
        return 'Profile';
      default:
        return 'BSCS Chat';
    }
  }

  Future<void> _loadUserProfile() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    String? currentUserId = auth.currentUser?.uid;

    if (currentUserId != null) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      var userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData != null && userData.containsKey('profile')) {
        var userProfile = userData['profile'];
        _firstNameController.text = userProfile['firstName'] ?? '';
        _lastNameController.text = userProfile['lastName'] ?? '';

        // Load the profile image if available
        if (userProfile.containsKey('profileImage') && userProfile['profileImage'] != null) {
          _loadProfileImage(userProfile['profileImage']);
        }
      }
    }
  }

  Future<void> _loadProfileImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        setState(() {
          _profileImage = response.bodyBytes;
        });
      }
    } catch (e) {
      // Handle errors or set a default image if needed
    }
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      var currentUser = FirebaseAuth.instance.currentUser;      
      if (currentUser != null) {
        // Assuming you have a way to get the current user's profile image URL
        String? profileImageUrl = currentUser.photoURL;

        // Send message to Firestore
        FirebaseFirestore.instance.collection('chats').add({
          'text': _messageController.text,
          'userId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(), // Firestore server timestamp
          'profileImage': profileImageUrl ?? '', // Handling null profile image
        });
        _messageController.clear();
      }
    }
    Future.delayed(const Duration(milliseconds: 1000)).then((_) {
      _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
      );
    });
  }

  void _signOut() async {
    try{
      await AuthMethods().signOut();
      
    } catch(e) {
      if (kDebugMode) {
        print(e.toString());
      }
    } 
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    switch (_currentScreen) {
      case ScreenType.chat:
        bodyContent = _buildChatScreen();
        break;
      case ScreenType.about:
        bodyContent = _buildAboutScreen();
        break;
      case ScreenType.profile:
        bodyContent = _buildProfileScreen();
        break;
    }

    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 38, 13, 165),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0.0,
          title: Text(_getAppBarTitle()),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: _buildDrawer(),
        body: bodyContent,
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 38, 13, 165),
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat'),
            onTap: () {
              setState(() {
                _currentScreen = ScreenType.chat;
              });
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              setState(() {
                _currentScreen = ScreenType.profile;
              });
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              setState(() {
                _currentScreen = ScreenType.about;
              });
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sign Out'),
            onTap: () {
              _signOut();
              // Navigate back to the login screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        children: [
          Expanded(
            child: ChatList(scrollController: _scrollController,),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFieldInput(
                    textEditingController: _messageController,
                    labelText: 'Type your message...',
                    textInputType: TextInputType.text,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          // New button for scrolling to the bottom
          TextButton(
            onPressed: () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_downward), 
                const SizedBox(width: 10,),
                Text("Scroll to Bottom".toUpperCase()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutScreen() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 25),
              child: CsLogo(height: 150.0),
            ),
            Text(
              'BSCS Chat',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'This is a chat application for BSCS students to communicate and share information. Enjoy secure and real-time messaging with your peers!',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Version: 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    final FireStoreUserMethods userMethods = FireStoreUserMethods();
    final ImagePicker picker = ImagePicker();
    final FirebaseAuth auth = FirebaseAuth.instance;

    Future<void> selectImage() async {
      final XFile? selectedImage = await picker.pickImage(source: ImageSource.gallery);
      if (selectedImage != null) {
        setState(() {
        });
      }
    }

  Future<void> saveProfile() async {
    String? imageUrl;
    if (_profileImage != null) {
      imageUrl = await userMethods.updateProfileImage(_profileImage, auth.currentUser!.uid);
    }
    
    model.Profile updateProfile = model.Profile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      profileImage: imageUrl,
    );

    model.User updatedUser = model.User(
      uid: auth.currentUser!.uid,
      profile: updateProfile
    );

    try {
      await userMethods.updateCurrentUserData(updatedUser);
      // Show Snackbar upon successful save
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Optionally handle errors, such as network issues
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: selectImage,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _profileImage != null ? MemoryImage(_profileImage!) : null,
                child: _profileImage == null ? const Icon(Icons.add_a_photo) : null,
              ),
            ),
            const SizedBox(height: 30,),
            TextFieldInput(
              textEditingController: _firstNameController,
              labelText: 'First Name',
              textInputType: TextInputType.text,
            ),
            const SizedBox(height: 10),
            TextFieldInput(
              textEditingController: _lastNameController,
              labelText: 'Last Name',
              textInputType: TextInputType.text,
            ),
            const SizedBox(height: 20,),
            ElevatedButton(
              onPressed: saveProfile,
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }



Widget _buildFloatingActionButton() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 50.0),
    child: FloatingActionButton(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.grey,
      elevation: 0,
      onPressed: () {
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
        );
      },
      child: const Icon(Icons.arrow_downward), // Your FAB icon
    ),
  );
}


}

enum ScreenType { chat, about, profile }
