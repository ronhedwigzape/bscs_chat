import 'package:bscs_chat/widgets/cs_logo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
   void _editMessage(String messageId, String currentText) async {
    TextEditingController editController = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_note),
              SizedBox(width: 10,),
              Text('Edit Your Message'),
            ],
          ),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: Divider.createBorderSide(
                  context,
                  color: Colors.grey,
                ),
              )
            ),),
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red, backgroundColor: Colors.redAccent, // Button Background Color
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Align to left
                      children: [
                        Icon(Icons.delete_forever, color: Colors.black,),
                        Text('Unsend', style: TextStyle(color: Colors.black),),
                      ],
                    ),
                    onPressed: () {
                      // Delete the message from Firestore
                      _unsendMessage(messageId);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 10,),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green, backgroundColor: Colors.lightGreenAccent, // Button Background Color
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end, // Align to right
                      children: [
                        Icon(Icons.update, color: Colors.black,),
                        Text('Update', style: TextStyle(color: Colors.black),),
                      ],
                    ),
                    onPressed: () {
                      // Update the message in Firestore
                      FirebaseFirestore.instance.collection('chats').doc(messageId).update({
                        'text': editController.text,
                        'isEdited': true,
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            
          ],
        );
      },
    );
  }

  void _unsendMessage(String messageId) {
    FirebaseFirestore.instance.collection('chats').doc(messageId).update({
      'text': '', // Empty the message text or set a placeholder
      'isDeleted': true, // Flag to indicate the message is deleted
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('chats').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 10, // Number of shimmer items
            itemBuilder: (context, index) => _buildShimmerEffect(),
          );
        }
        if (snapshot.hasData) {
          return SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 25),
                  child: CsLogo(height: 90.0),
                ),
                const Text(
                  'BSCS Chat',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'A chat app for every BSCS student.'
                ),
                ListView.builder(
                  reverse: true,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var messageData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    bool isCurrentUser = messageData['userId'] == currentUserId;
                    String profileImageUrl = messageData.containsKey('profileImage') ? messageData['profileImage'] : '';
                    String messageText = messageData['text'] ?? 'Message error';
                
                    // Fetch the user's name
                    Future<String> fetchUserName(String userId) async {
                      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
                      var userData = userDoc.data() as Map<String, dynamic>;
                      return userData['profile']['firstName'] ?? 'User';
                    }

                    if (messageData.containsKey('isEdited') && messageData['isEdited']) {
                        return FutureBuilder(
                        future: fetchUserName(messageData['userId']),
                        builder: (context, AsyncSnapshot<String> nameSnapshot) {
                          if (nameSnapshot.connectionState == ConnectionState.done) {
                            String userName = nameSnapshot.data!;
                            if (isCurrentUser) {
                              return GestureDetector(
                                onLongPress: () {
                                  _editMessage(snapshot.data!.docs[index].id, messageData['text']);
                                },
                                child: Column(
                                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                      children: [
                                        Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                      children: [
                                        const Text('Edited', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Container(
                                          margin: const EdgeInsets.all(8),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isCurrentUser ? const Color.fromARGB(255, 38, 13, 165) : Colors.grey[300],
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Text(messageText, 
                                          style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),),
                                        ),
                                        if (isCurrentUser && profileImageUrl.isNotEmpty)
                                          CircleAvatar(backgroundImage: NetworkImage(profileImageUrl)),
                                        if (isCurrentUser && profileImageUrl.isEmpty)
                                          const CircleAvatar(backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Windows_10_Default_Profile_Picture.svg/2048px-Windows_10_Default_Profile_Picture.svg.png')),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
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
                                        color: isCurrentUser ? const Color.fromARGB(255, 38, 13, 165) : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Text(messageText, 
                                      style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),),
                                    ),
                                    const Text('Edited', style: TextStyle(fontSize: 12, color: Colors.grey)),],
                                )
                              ],
                            );
                          } else {
                            return _buildShimmerEffect();
                          }
                        }
                      );
                    } else if (messageData.containsKey('isDeleted') && messageData['isDeleted']) {
                      return FutureBuilder(
                        future: fetchUserName(messageData['userId']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            String userName = snapshot.data!;
                            if (isCurrentUser) {
                              return GestureDetector(
                                child: Column(
                                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
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
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(color: const Color.fromARGB(255, 160, 160, 160), width: 0.5)
                                          ),
                                          child: const Text("You unsent a message.", 
                                          style: TextStyle(color: Color.fromARGB(255, 160, 160, 160), fontStyle: FontStyle.italic),),
                                        ),
                                        if (isCurrentUser && profileImageUrl.isNotEmpty)
                                          CircleAvatar(backgroundImage: NetworkImage(profileImageUrl)),
                                        if (isCurrentUser && profileImageUrl.isEmpty)
                                          const CircleAvatar(backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Windows_10_Default_Profile_Picture.svg/2048px-Windows_10_Default_Profile_Picture.svg.png')),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Row(
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
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(color: const Color.fromARGB(255, 160, 160, 160), width: 0.5)
                                      ),
                                      child: Text("${snapshot.data} unsent a message.", 
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 160, 160, 160), fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                    if (isCurrentUser && profileImageUrl.isNotEmpty)
                                      CircleAvatar(backgroundImage: NetworkImage(profileImageUrl)),
                                    if (isCurrentUser && profileImageUrl.isEmpty)
                                      const CircleAvatar(backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Windows_10_Default_Profile_Picture.svg/2048px-Windows_10_Default_Profile_Picture.svg.png')),
                                  ],
                                )
                              ],
                            );
                          } 
                          else if (snapshot.connectionState == ConnectionState.waiting) {
                            return _buildShimmerEffect();
                          }
                          else {
                            return _buildShimmerEffect();
                          }
                        }
                      );
                    } else {
                      return FutureBuilder(
                        future: fetchUserName(messageData['userId']),
                        builder: (context, AsyncSnapshot<String> nameSnapshot) {
                          if (nameSnapshot.connectionState == ConnectionState.done) {
                            String userName = nameSnapshot.data!;
                            if (isCurrentUser) {
                              return GestureDetector(
                                onLongPress: () {
                                  _editMessage(snapshot.data!.docs[index].id, messageData['text']);
                                },
                                child: Column(
                                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
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
                                            color: isCurrentUser ? const Color.fromARGB(255, 38, 13, 165) : Colors.grey[300],
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Text(messageText, 
                                          style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),),
                                        ),
                                        if (isCurrentUser && profileImageUrl.isNotEmpty)
                                          CircleAvatar(backgroundImage: NetworkImage(profileImageUrl)),
                                        if (isCurrentUser && profileImageUrl.isEmpty)
                                          const CircleAvatar(backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Windows_10_Default_Profile_Picture.svg/2048px-Windows_10_Default_Profile_Picture.svg.png')),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            }
                            return Column(
                              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Row(
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
                                        color: isCurrentUser ? const Color.fromARGB(255, 38, 13, 165) : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Text(messageText, 
                                      style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),),
                                    ),
                                    if (isCurrentUser && profileImageUrl.isNotEmpty)
                                      CircleAvatar(backgroundImage: NetworkImage(profileImageUrl)),
                                    if (isCurrentUser && profileImageUrl.isEmpty)
                                      const CircleAvatar(backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Windows_10_Default_Profile_Picture.svg/2048px-Windows_10_Default_Profile_Picture.svg.png')),
                                  ],
                                )
                              ],
                            );
                          } else {
                            return _buildShimmerEffect();
                          }
                        }
                      );
                    }
                
                  },
                ),
              ],
            ),
          );
        } else {
          return ListView.builder(
            itemCount: 10, // Number of shimmer items
            itemBuilder: (context, index) => _buildShimmerEffect(),
          );
        }
      },
    );
  }

  Widget _buildShimmerEffect() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    height: 10.0,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    height: 10.0,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.scrollController.dispose();
    super.dispose();
  }
}
