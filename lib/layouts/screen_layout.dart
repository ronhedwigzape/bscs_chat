import 'package:bscs_chat/resources/auth_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      // Send message to Firestore (example path: 'chats/messages')
      FirebaseFirestore.instance.collection('chats').doc('messages').set({
        'text': _messageController.text,
        // Include other data like sender ID, timestamp, etc.
      });
      _messageController.clear();
    }
  }
  
  void _signOut() async {
    try{
      await AuthMethods().signOut();
      
    } catch(e) {
      print(e.toString());
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
      // Add other cases for different screens
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 38, 13, 165),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0.0,
        title: const Text('BSCS Chat Room'),
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
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('chats').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(message['text']), // Display the message text
                    );
                  },
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(labelText: 'Type a message'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
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
}

enum ScreenType { chat, about }