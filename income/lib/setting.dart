import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:income/login.dart';
import 'package:income/profileedit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: UserGreeting(userId: 'exampleUserId'), // Pass the actual user ID here
  ));
}

class UserGreeting extends StatelessWidget {
  final String userId;

  UserGreeting({required this.userId});

  Future<Map<String, dynamic>> fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return doc.data()!;
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return Future.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error fetching data: ${snapshot.error}'));
        }

        final userData = snapshot.data ?? {};
        final name = userData['name'] ?? 'User';
        final profileImageUrl = userData['profileImageUrl'] ??
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTFA8ewdwEhnD6NRpS665hs1zkxDmr6c3vgdn2t1qwGsVKTpKppZe1sTbXakbWYGXwzW9Q&usqp=CAU';

        return SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ProfileEditPage(userId: userId)),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(profileImageUrl),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello $name!',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200, width: 3),
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.settings, color: Colors.blue, size: 30),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SettingsPage(userId: userId)),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class SettingsPage extends StatefulWidget {
  final String userId;

  SettingsPage({required this.userId});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String userName = 'Loading...';
  String profileImageUrl = 'https://via.placeholder.com/150'; // Default image

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          userName = data?['name'] ?? 'Unknown User';
          profileImageUrl = data?['profileImageUrl'] ??
              'https://via.placeholder.com/150'; // Fallback image
        });
      } else {
        setState(() {
          userName = 'User not found';
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Error fetching name';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Settings', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(profileImageUrl),
                  ),
                  SizedBox(width: 16.0),
                  Text(
                    userName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Account Settings', style: TextStyle(color: Colors.grey)),
            ),
            ListTile(
  title: Text('Account Details'),
  trailing: Icon(Icons.arrow_forward_ios),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountPage(userId: widget.userId),
      ),
    );
  },
),
            ListTile(
              title: Text('Change password'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ChangePasswordDialog()),
);

              },
            ),
           ListTile(
            title: Text('Delete Account'),
            onTap: () {
              showDeleteAccountDialog(context);
            },
          ),
           
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('More', style: TextStyle(color: Colors.grey)),
            ),
            ListTile(
              title: Text('About us'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                  Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => AboutUsPage()),
);
              },
            ),
            ListTile(
              title: Text('Privacy policy'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
);
              },
            ),
          ],
        ),
      ),
    );
  }
}


class AccountPage extends StatefulWidget {
  final String userId;

  AccountPage({required this.userId});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String userName = 'Loading...';
  String email = 'Loading...';
  
  String profileImageUrl = 'https://via.placeholder.com/150'; // Default image

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          userName = data?['name'] ?? 'Unknown User';
          email = data?['email'] ?? 'No email provided';
         
          profileImageUrl = data?['profileImageUrl'] ??
              'https://via.placeholder.com/150'; // Fallback image
        });
      } else {
        setState(() {
          userName = 'User not found';
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Error fetching data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(16.0),
      title: Text('Account'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
                SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(email),
                  
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
class ChangePasswordDialog extends StatefulWidget {
  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _changePassword() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'No user is logged in.';
        _isLoading = false;
      });
      return;
    }

    try {
      
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      
      if (_newPasswordController.text != _confirmPasswordController.text) {
        throw Exception('Passwords do not match.');
      }
      if (_newPasswordController.text.length < 6) {
        throw Exception('Password must be at least 6 characters.');
      }

     
      await user.updatePassword(_newPasswordController.text);

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change Password'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _changePassword,
                    child: Text('Change Password'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
}

void showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete Account'),
        content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text('Delete'),
          ),
        ],
      );
    },
  );
}
class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.headline5,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Introduction',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.headline6,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'Welcome to [Your App Name]. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our application. Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Data Collection',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.headline6,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'We may collect information about you in a variety of ways. The information we may collect from you includes:',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              '- Personal Data: Personally identifiable information, such as your name, email address, and phone number, that you voluntarily give to us when you register with the application or when you choose to participate in various activities related to the application.',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            Text(
              '- Derivative Data: Information our servers automatically collect when you access the application, such as your IP address, your browser type, your operating system, your access times, and the pages you have directly visited.',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            Text(
              '- Financial Data: Financial information, such as data related to your payment method, that we may collect when you purchase, order, return, exchange, or request information about our services from the application.',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Use of Data',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.headline6,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'Having accurate information about you permits us to provide you with a smooth, efficient, and customized experience. Specifically, we may use information collected about you via the application to:',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              '- Assist with account creation and logon process.',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            Text(
              '- Monitor and analyze usage and trends to improve your experience with the application.',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            Text(
              '- Perform other business activities as needed.',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Contact Us',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.headline6,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'If you have questions or comments about this Privacy Policy, please contact us at:',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'Email: [your-email@example.com]',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            Text(
              'Phone: [your-phone-number]',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'This Privacy Policy may be updated from time to time to reflect changes to our practices. We will notify you of any changes by posting the new Privacy Policy on this page.',
              style: GoogleFonts.lato(
                // textStyle: Theme.of(context).textTheme.bodyText1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Us'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Our App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Welcome to our REFILL WEALTH app! Our mission is to help you manage your finances efficiently and effectively. Whether you want to track your spending, set a budget, or visualize your financial progress, we have you covered.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Track income and expenses\n• Categorize transactions\n• Set and manage budgets\n• View detailed financial reports and graphs\n• User-friendly interface and experience',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Our Team',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Our team is dedicated to providing you with the best financial management experience. We are constantly working on new features and improvements based on your feedback.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
             
            ],
          ),
        ),
      ),
    );
  }
}