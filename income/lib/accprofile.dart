import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'account.dart';
import 'profile.dart';

class AccountsSection extends StatefulWidget {
  @override
  _AccountsSectionState createState() => _AccountsSectionState();
}

class _AccountsSectionState extends State<AccountsSection> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.gupterTextTheme(Theme.of(context).textTheme),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Accounts settings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
              );
            },
          ),
        ),
        body: Container(
          margin: EdgeInsets.only(top: 15),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _fetchAccountsStream(),
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

              var documents = snapshot.data!.docs;

              return ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final document = documents.removeAt(oldIndex);
                    documents.insert(newIndex, document);
                    _updateOrderInFirestore(documents);
                  });
                },
                children: List.generate(documents.length, (index) {
                  var doc = documents[index];
                  var data = doc.data() as Map<String, dynamic>;
                  String accountName = data['accountName'] ?? '';
                  String accountType = data['accountType'] ?? '';

                  return AccountItem(
                    key: ValueKey(doc.id),
                    accountName: accountName,
                    accountType: accountType,
                    onDelete: () => _deleteAccount(doc.id),
                    onReorder: () {}, // Callback for reorder action
                  );
                }),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewAccountScreen(), // Pass isIncome as needed
              ),
            );
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _fetchAccountsStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .snapshots();
    } else {
      return Stream.empty();
    }
  }

  void _deleteAccount(String accountId) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .doc(accountId)
          .delete();
    }
  }

  void _updateOrderInFirestore(List<DocumentSnapshot> reorderedDocuments) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < reorderedDocuments.length; i++) {
        batch.update(
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('accounts')
              .doc(reorderedDocuments[i].id),
          {'order': i},
        );
      }

      batch.commit();
    }
  }
}

class AccountItem extends StatelessWidget {
  final String accountName;
  final String accountType;
  final VoidCallback onDelete;
  final VoidCallback onReorder;

  AccountItem({
    required Key key,
    required this.accountName,
    required this.accountType,
    required this.onDelete,
    required this.onReorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Icon(Icons.account_balance_wallet),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                accountName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(accountType),
            ],
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
          LongPressDraggable(
            data: accountName,
            onDragStarted: onReorder,
            feedback: Material(
              color: Colors.transparent,
              child: Icon(Icons.reorder, size: 50, color: Colors.grey),
            ),
            child: Icon(Icons.reorder),
          ),
        ],
      ),
    );
  }
}
