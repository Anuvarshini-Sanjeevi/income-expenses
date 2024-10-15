import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:income/homepage.dart';

import 'dart:io';

import 'homepage.dart';

class userProfileEditPage extends StatefulWidget {
  final String userId;

  userProfileEditPage({required this.userId});

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<userProfileEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  bool _isLoading = true;
  File? _profileImage;
  String? _profileImageUrl;

  

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final userData = doc.data() ?? {};
    _nameController = TextEditingController(text: userData['name'] ?? '');
    _emailController = TextEditingController(text: userData['email'] ?? '');
    _usernameController =
        TextEditingController(text: userData['username'] ?? '');
    _phoneController = TextEditingController(text: userData['phone'] ?? '');
    _profileImageUrl = userData['profileImageUrl'];
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveUserData() async {
    final userData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'username': _usernameController.text,
      'phone': _phoneController.text,
    };

    if (_profileImage != null) {
      final profileImageUrl = await _uploadProfileImage();
      userData['profileImageUrl'] = profileImageUrl;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update(userData);
  }

  Future<String> _uploadProfileImage() async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child(widget.userId);
    final uploadTask = storageRef.putFile(_profileImage!);
    final snapshot = await uploadTask.whenComplete(() => null);
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.gupterTextTheme(Theme.of(context).textTheme),
      ),
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>HomeScreen(),
                ),
              );
            },
          ),
          title: Text('Edit Profile'),
          backgroundColor: Colors.green,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Container(
                padding: EdgeInsets.fromLTRB(16, 55, 16, 30),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImage == null
                              ? (_profileImageUrl == null
                                  ? NetworkImage(
                                      'https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.vectorstock.com%2Froyalty-free-vector%2Fuser-sign-golden-style-icon-vector-8892198&psig=AOvVaw2L_LO3oQZlr0cT3TTtTYqB&ust=1722936104128000&source=images&cd=vfe&opi=89978449&ved=0CBEQjRxqFwoTCJCjlKrD3YcDFQAAAAAdAAAAABAE')
                                  : NetworkImage(_profileImageUrl!))
                              : FileImage(_profileImage!) as ImageProvider,
                          child: Icon(
                            Icons.camera_alt,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_circle),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await _saveUserData();
                          Navigator.pop(context);
                        },
                        child: Text('Save'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
