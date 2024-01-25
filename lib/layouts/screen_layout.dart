import 'dart:typed_data';
import 'package:bscs_chat/models/profile.dart' as model;
import 'package:bscs_chat/models/user.dart' as model;
import 'package:bscs_chat/resources/auth_methods.dart';
import 'package:bscs_chat/resources/firestore_user_methods.dart';
import 'package:bscs_chat/widgets/text_field_input.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScreenLayout extends StatefulWidget {
  const ScreenLayout({Key? key}) : super(key: key);

  @override
  State<ScreenLayout> createState() => _ScreenLayoutState();
}

class _ScreenLayoutState extends State<ScreenLayout> {
  ScreenType _currentScreen = ScreenType.chat; // Default screen
  final TextEditingController _messageController = TextEditingController();

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 38, 13, 165),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0.0,
        title: const Text('BSCS Chat'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: bodyContent,
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
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('chats').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    reverse: true, // For chat-like scrolling
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var messageData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      bool isCurrentUser = messageData['userId'] == currentUserId;
                      String profileImageUrl = messageData.containsKey('profileImage') ? messageData['profileImage'] : '';
                      String messageText = messageData['text'] ?? 'Message error';
      
                      return Row(
                        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isCurrentUser && profileImageUrl.isNotEmpty)
                            CircleAvatar(backgroundImage: NetworkImage(profileImageUrl)),
                          if (!isCurrentUser && profileImageUrl.isEmpty)
                            const CircleAvatar(backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Windows_10_Default_Profile_Picture.svg/2048px-Windows_10_Default_Profile_Picture.svg.png')),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isCurrentUser ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(messageText),
                          ),
                          if (isCurrentUser && profileImageUrl.isNotEmpty)
                            CircleAvatar(backgroundImage: NetworkImage(profileImageUrl)),
                          if (isCurrentUser && profileImageUrl.isEmpty)
                            const CircleAvatar(backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Windows_10_Default_Profile_Picture.svg/2048px-Windows_10_Default_Profile_Picture.svg.png')),
                        ],
                      );
                    },
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
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
        ],
      ),
    );
  }

  Widget _buildAboutScreen() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'BSCS Chat Room',
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
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    Uint8List? profileImage ;
    final FireStoreUserMethods userMethods = FireStoreUserMethods();
    final ImagePicker picker = ImagePicker();
    final FirebaseAuth auth = FirebaseAuth.instance;

    Future<void> selectImage() async {
      final XFile? selectedImage = await picker.pickImage(source: ImageSource.gallery);
      if (selectedImage != null) {
        final Uint8List imageData = await selectedImage.readAsBytes();
        setState(() {
          profileImage = imageData;
        });
      }
    }

    Future<void> saveProfile() async {
      String? imageUrl;
      if (profileImage != null) {
        imageUrl = await userMethods.updateProfileImage(profileImage, auth.currentUser!.uid);
      }
      
      model.Profile updateProfile = model.Profile(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        profileImage: imageUrl,
      );

      model.User updatedUser = model.User(
        uid: auth.currentUser!.uid,
        profile: updateProfile
      );
      await userMethods.updateCurrentUserData(updatedUser);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: selectImage,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: profileImage != null ? MemoryImage(profileImage!) : null,
                child: profileImage == null ? const Icon(Icons.add_a_photo) : null,
              ),
            ),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(hintText: 'First Name'),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(hintText: 'Last Name'),
            ),
            ElevatedButton(
              onPressed: saveProfile,
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

}

enum ScreenType { chat, about, profile }
