import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:income/catgory.dart';
import 'package:income/currency.dart';
import 'package:income/login.dart';
import 'package:income/profilebudget.dart';
import 'package:income/security.dart';
import 'package:income/statistics.dart';
import 'package:income/userprofile2.dart';

import 'accprofile.dart';
import 'budget.dart';


class ProfilePage extends StatelessWidget {
  final String userId;

  ProfilePage({Key? key})
      : userId = FirebaseAuth.instance.currentUser?.uid ?? '',
        super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => bottomnav(),
                ));
          },
        ),
        title: Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _showLogoutDialog;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 255, 228, 226),
            ),
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(child: Text('User not found'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                CircleAvatar(
                    radius: 50,
                    backgroundImage: CachedNetworkImageProvider(
                      userData['profileImageUrl'] ??
                          'https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.vectorstock.com%2Froyalty-free-vector%2Fuser-sign-golden-style-icon-vector-8892198&psig=AOvVaw2L_LO3oQZlr0cT3TTtTYqB&ust=1722936104128000&source=images&cd=vfe&opi=89978449&ved=0CBEQjRxqFwoTCJCjlKrD3YcDFQAAAAAdAAAAABAE',
                    )),
                SizedBox(height: 10),
                Text(
                  userData['name'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  userData['email'],
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.account_circle),
                  title: Text(
                    'User profile',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('Change profile image, name or password'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              userProfileEditPage(userId: userId)),
                    );
                  },
                ),
                const Divider(
                  color: Colors.black,
                  height: 0.01,
                  thickness: 0.2,
                ),
                ListTile(
                  leading: Icon(Icons.check_circle),
                  title: Text('Budgetting',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Explore premium options and enjoy'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BudgetingPage(),
                        ));
                  },
                ),
                const Divider(
                  color: Colors.black,
                  height: 0.01,
                  thickness: 0.2,
                ),
                ListTile(
                  leading: Icon(Icons.account_balance),
                  title: Text('Accounts',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Manage accounts and description'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountsSection(),
                        ));
                  },
                ),
                const Divider(
                  color: Colors.black,
                  height: 0.01,
                  thickness: 0.2,
                ),
                ListTile(
                  leading: Icon(Icons.attach_money),
                  title: Text('Currencies',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Add other currencies, adjust exchange rates'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CurrenciesPage(userId: userId),
                        ));
                  },
                ),
                const Divider(
                  color: Colors.black,
                  height: 0.01,
                  thickness: 0.2,
                ),
                ListTile(
                  leading: Icon(Icons.category),
                  title: Text('Categories',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Manage categories and add sub-categories'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoriesPage(),
                        ));
                  },
                ),
                const Divider(
                  color: Colors.black,
                  height: 0.01,
                  thickness: 0.2,
                ),
                ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Security',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Protect your app with PIN or Fingerprint'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SecurityPage(),
                        ));
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Logout'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => LoginPage()));
            },
          ),
        ],
      );
    },
  );
}
