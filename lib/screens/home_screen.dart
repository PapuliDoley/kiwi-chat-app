import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/models/chat_user';

// Assuming your model is in this path
// import '../../models/chat_user.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  // For storing all users fetched from Firestore
  List<ChatUser> _list = [];

  // For storing users that match the search query
  final List<ChatUser> _searchList = [];

  // To track if the user is currently searching
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    // Initialize mq (Media Query) for responsive sizing
    final mq = MediaQuery.of(context).size;

    return GestureDetector(
      // Hides keyboard when tapping anywhere else on the screen
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: const Icon(CupertinoIcons.home),
          title: _isSearching
              ? TextField(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search by Name or Email...',
                    hintStyle: TextStyle(color: Colors.black54),
                  ),
                  autofocus: true,
                  style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
                  // Logic to filter the list as the user types
                  onChanged: (val) {
                    _searchList.clear();
                    for (var i in _list) {
                      if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                          i.email.toLowerCase().contains(val.toLowerCase())) {
                        _searchList.add(i);
                      }
                    }
                    setState(() {});
                  },
                )
              : const Text('Kiwi'),
          actions: [
            // Search toggle button
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                });
              },
              icon: Icon(
                _isSearching
                    ? CupertinoIcons.clear_circled_solid
                    : Icons.search,
              ),
            ),

            // Logout Button
            IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn.instance.signOut();
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),

        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.pink[100], // Baby pink aesthetic
            child: const Icon(Icons.add_comment_rounded),
          ),
        ),

        // Body with Real-time Firestore Stream
        body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
              case ConnectionState.none:
                return const Center(child: CircularProgressIndicator());

              case ConnectionState.active:
              case ConnectionState.done:
                final data = snapshot.data?.docs;
                _list =
                    data?.map((e) => ChatUser.fromJson(e.data())).toList() ??
                    [];

                if (_list.isNotEmpty) {
                  return ListView.builder(
                    itemCount: _isSearching ? _searchList.length : _list.length,
                    padding: EdgeInsets.only(top: mq.height * .01),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final user = _isSearching
                          ? _searchList[index]
                          : _list[index];

                      // Don't show your own profile in the chat list
                      if (user.id == FirebaseAuth.instance.currentUser?.uid) {
                        return const SizedBox();
                      }
                      return ChatUserCard(user: user);
                    },
                  );
                } else {
                  return const Center(
                    child: Text(
                      'No Users Found! 🥝',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  );
                }
            }
          },
        ),
      ),
    );
  }
}

// Custom Card for each user in the list
class ChatUserCard extends StatelessWidget {
  final ChatUser user;
  const ChatUserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          log("Navigate to chat with ${user.name}");
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.pink[50],
            backgroundImage: NetworkImage(user.image),
          ),
          title: Text(user.name),
          subtitle: Text(user.about, maxLines: 1),
          trailing: user.isOnline
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              : const Text(
                  'Offline',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
        ),
      ),
    );
  }
}
