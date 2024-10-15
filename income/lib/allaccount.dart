
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'general.dart';
class AllAccountsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
                 theme: ThemeData(
        textTheme: GoogleFonts.gupterTextTheme(Theme.of(context).textTheme),
      ),
    home:Scaffold(
      appBar: AppBar(
        title: Text('All Accounts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('accounts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error fetching accounts'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No accounts found'));
          }

          List<Widget> accountCards = snapshot.data!.docs.map<Widget>((doc) {
            var data = doc.data() as Map<String, dynamic>;
            Color color = Color(data['color'] as int);
            String accountName = data['accountName'] ?? '';
            String initialValue = '${data['initialValue']} ${data['currency']}';

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home:AccountCard(
              color: color,
              label: accountName,
              amount: initialValue,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              margin: EdgeInsets.symmetric(horizontal: 5),
              )
            );
          }).toList();

          return MaterialApp(
              debugShowCheckedModeBanner: false,
              home:GridView.builder(
            padding: EdgeInsets.all(10),
            itemCount: accountCards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Adjust according to the layout preference
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2 / 1,
            ),
            itemBuilder: (context, index) {
              return accountCards[index];
            },
              )
          );
        },
      ),
    )
    );
  }
}
