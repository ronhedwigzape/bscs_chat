// ignore_for_file: use_build_context_synchronously
import 'package:bscs_chat/models/chat_message.dart';
import 'package:bscs_chat/models/profile.dart' as model;
import 'package:bscs_chat/models/user.dart' as model;
import 'package:bscs_chat/resources/auth_methods.dart';
import 'package:bscs_chat/resources/firestore_user_methods.dart';
import 'package:bscs_chat/screens/login_screen.dart';
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
  String _currentUserName = '';
  String _currentUserEmail = '';
  // ignore: unused_field
  List<ChatMessage> _chatMessages = [];

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

  // This method will be triggered when the user pulls down the chat list
  Future<void> _refreshChatMessages() async {
    try {
      // Fetch the latest chat messages from Firestore
      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .orderBy('timestamp', descending: true)
          .get();

      // Assuming ChatMessage is a class that represents a chat message
      // Convert each document to a ChatMessage and add to the list
      List<ChatMessage> newMessages = chatSnapshot.docs.map((doc) {
        return ChatMessage.fromDocument(doc); // Replace with actual conversion logic
      }).toList();

      // Update the state with the new messages
      setState(() {
        _chatMessages = newMessages;
      });
    } catch (error) {
      // Handle any errors here
      print("Error fetching chat messages: $error");
    }
  }

void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('How to use this chat app?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Use this app like a messenger.'),
                SizedBox(height: 8),
                Text('Features:'),
                Text('- Pull down to refresh'),
                Text('- Edit and unsend message'),
                Text('- Scroll to bottom, middle, and top'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadUserProfile() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    String? currentUserId = auth.currentUser?.uid;
    _currentUserEmail = auth.currentUser?.email ?? '';

    if (currentUserId != null) {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      var userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData.containsKey('profile')) {
        var userProfile = userData['profile'];
        _firstNameController.text = userProfile['firstName'] ?? '';
        _lastNameController.text = userProfile['lastName'] ?? '';

        // Set full name for display in drawer
        _currentUserName = '${userProfile['firstName'] ?? ''} ${userProfile['lastName'] ?? ''}';

        // Check and load profile image
        String? profileImageUrl = userProfile['profileImage'];
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          await _loadProfileImage(profileImageUrl);
        }

        print('Current user name: $_currentUserName'); // Debug print
        setState(() {}); // Update UI
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
        print('Profile image loaded');
      } else {
        print('Failed to load image: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading profile image: $e');
      // Optionally set a default image in case of error
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
    Future.delayed(const Duration(milliseconds: 2000)).then((_) {
      _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
      );
    });
  }

  void _signOut() async {
    try{
      await AuthMethods().signOut();
      Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const LoginScreen()
        )
      );
    } catch(e) {
      if (kDebugMode) {
        print(e.toString());
      }
    } 
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Scroll to the top of the list
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToMiddle() {
    if (_scrollController.hasClients) {
      double middlePosition = _scrollController.position.maxScrollExtent / 2;
      _scrollController.animateTo(
        middlePosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showInstructionsDialog,
            ),
          ],
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
          UserAccountsDrawerHeader( 
            decoration: const BoxDecoration(
              color: const Color.fromARGB(255, 38, 13, 165),
            ),
            accountName: Text(_currentUserName),
            accountEmail: Text(_currentUserEmail),
            currentAccountPicture: _profileImage != null 
              ? CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: MemoryImage(_profileImage!),
                )
              : CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    _currentUserName.isNotEmpty ? _currentUserName[0] : '?',
                    style: const TextStyle(fontSize: 24.0),
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
            child: RefreshIndicator(
            onRefresh: _refreshChatMessages,
            child: ChatList(scrollController: _scrollController),
          ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => _scrollToTop(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward),
                    SizedBox(width: 10),
                    Text("Top"),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _scrollToMiddle(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.horizontal_rule),
                    SizedBox(width: 10),
                    Text("Middle"),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _scrollToBottom(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_downward),
                    SizedBox(width: 10),
                    Text("Bottom"),
                  ],
                ),
              ),
            ],
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
              'This is a chat application for BSCS students of ACLC College of Iriga to communicate and share information. Enjoy secure and real-time messaging with your peers!',
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
    model.Profile updateProfile = model.Profile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
    );

    model.User updatedUser = model.User(
      uid: auth.currentUser!.uid,
      profile: updateProfile
    );

    try {
      await userMethods.updateCurrentUserData(updatedUser);
      // Show Snackbar upon successful save
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Profile updated successfully!'),
      duration: Duration(seconds: 3),
    ));
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

}

enum ScreenType { chat, about, profile }
