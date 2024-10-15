// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'homepage.dart';

// class AccountScreen extends StatefulWidget {
//   final String accountType;

//   AccountScreen({required this.accountType});

//   @override
//   _NewAccountScreenState createState() => _NewAccountScreenState();
// }

// class _NewAccountScreenState extends State<AccountScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _accountNameController = TextEditingController();
//   final _bankAccountNumberController = TextEditingController();
//   late String _selectedType;
//   int _initialValue = 0;
//   String _selectedCurrency = 'INR';
//   Color _selectedColor = Colors.teal;

//   @override
//   void initState() {
//     super.initState();
//     _selectedType = widget.accountType;
//   }

//   @override
//   void dispose() {
//     _accountNameController.dispose();
//     _bankAccountNumberController.dispose();
//     super.dispose();
//   }

//   Future<void> _saveAccount() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         User? user = FirebaseAuth.instance.currentUser;

//         if (user != null) {
//           await FirebaseFirestore.instance
//               .collection('users')
//               .doc(user.uid)
//               .collection('accounts')
//               .add({
//             'accountName': _accountNameController.text,
//             'bankAccountNumber': _bankAccountNumberController.text,
//             'type': _selectedType,
//             'initialValue': _initialValue,
//             'currency': _selectedCurrency,
//             'color': _selectedColor.value,
//           });

//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(builder: (context) => HomeScreen()),
//             (route) => false,
//           );
//         } else {
//           // Handle user not logged in
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('User not logged in')),
//           );
//         }
//       } catch (e) {
//         // Handle error
//         print('Error saving account: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving account')),
//         );
//       }
//     }
//   }

//   void _showAccountTypeScreen() async {
//     final result = await showDialog<String>(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           child: AccountTypeScreen(),
//         );
//       },
//     );

//     if (result != null) {
//       setState(() {
//         _selectedType = result;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final bool isWideScreen = screenWidth > 600;

//     return Scaffold(
//       appBar: AppBar(
//         leading: Builder(
//           builder: (BuildContext context) {
//             return IconButton(
//               icon: const Icon(
//                 Icons.close,
//                 color: Colors.white,
//               ),
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
//             );
//           },
//         ),
//         title: Text('New Account',
//             style: TextStyle(
//               color: Colors.white,
//             )),
//         backgroundColor: Colors.green[400],
//         actions: [
//           IconButton(
//             icon: const Icon(
//               Icons.check,
//               color: Colors.white,
//             ),
//             onPressed: _saveAccount,
//             tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(isWideScreen ? 24.0 : 16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               TextFormField(
//                 controller: _accountNameController,
//                 decoration: InputDecoration(labelText: 'Account name'),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter account name';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: isWideScreen ? 24.0 : 16.0),
//               TextFormField(
//                 controller: _bankAccountNumberController,
//                 decoration: InputDecoration(labelText: 'Bank account number'),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter bank account number';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: isWideScreen ? 24.0 : 16.0),
//               DropdownButtonFormField<String>(
//                 value: _selectedType,
//                 decoration: InputDecoration(labelText: 'Type'),
//                 items: ['General', 'Savings', 'Current'].map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   if (value == 'General') {
//                     _showAccountTypeScreen();
//                   } else {
//                     setState(() {
//                       _selectedType = value!;
//                     });
//                   }
//                 },
//               ),
//               SizedBox(height: isWideScreen ? 24.0 : 16.0),
//               DropdownButtonFormField<int>(
//                 value: _initialValue,
//                 decoration: InputDecoration(labelText: 'Initial value'),
//                 items: [0, 10, 100, 1000].map((int value) {
//                   return DropdownMenuItem<int>(
//                     value: value,
//                     child: Text('$value'),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _initialValue = value!;
//                   });
//                 },
//               ),
//               SizedBox(height: isWideScreen ? 24.0 : 16.0),
//               DropdownButtonFormField<String>(
//                 value: _selectedCurrency,
//                 decoration: InputDecoration(labelText: 'Currency'),
//                 items: ['INR', 'USD', 'EUR'].map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedCurrency = value!;
//                   });
//                 },
//               ),
//               SizedBox(height: isWideScreen ? 29.0 : 20.0),
//               DropdownButtonFormField<Color>(
//                 value: _selectedColor,
//                 decoration: InputDecoration(labelText: 'Color'),
//                 items: [
//                   Colors.teal,
//                   Colors.blue,
//                   Colors.red,
//                   Colors.orange,
//                 ].map((Color color) {
//                   return DropdownMenuItem<Color>(
//                     value: color,
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(vertical: 8.0),
//                       child: Container(
//                         width: isWideScreen
//                             ? screenWidth * 0.4
//                             : screenWidth * 0.8,
//                         height: 60,
//                         decoration: BoxDecoration(
//                           color: color,
//                           borderRadius: BorderRadius.circular(4.0),
//                           border: Border.all(
//                             color: Colors.black12,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedColor = value!;
//                   });
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class AccountTypeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Choose an account type',
//           style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: ListView(
//         children: <Widget>[
//           ListTile(
//             title: Text(
//               'General',
//               style: TextStyle(color: const Color.fromARGB(255, 142, 140, 140)),
//             ),
//             onTap: () {
//               Navigator.pop(context, 'General');
//             },
//           ),
//           ListTile(
//             title: Text(
//               'Cash',
//               style: TextStyle(color: const Color.fromARGB(255, 142, 140, 140)),
//             ),
//             onTap: () {
//               Navigator.pop(context, 'Cash');
//             },
//           ),
//           ListTile(
//             title: Text(
//               'Current account',
//               style: TextStyle(color: const Color.fromARGB(255, 142, 140, 140)),
//             ),
//             onTap: () {
//               Navigator.pop(context, 'Current account');
//             },
//           ),
//           ListTile(
//             title: Text(
//               'Credit card',
//               style: TextStyle(color: const Color.fromARGB(255, 142, 140, 140)),
//             ),
//             onTap: () {
//               Navigator.pop(context, 'Credit card');
//             },
//           ),
//           ListTile(
//             title: Text(
//               'Saving account',
//               style: TextStyle(color: const Color.fromARGB(255, 142, 140, 140)),
//             ),
//             onTap: () {
//               Navigator.pop(context, 'Saving account');
//             },
//           ),
//           ListTile(
//             title: Text(
//               'Bonus',
//               style: TextStyle(color: const Color.fromARGB(255, 142, 140, 140)),
//             ),
//             onTap: () {
//               Navigator.pop(context, 'Bonus');
//             },
//           ),
//           ListTile(
//             title: Text(
//               'Insurance',
//               style: TextStyle(color: const Color.fromARGB(255, 142, 140, 140)),
//             ),
//             onTap: () {
//               Navigator.pop(context, 'Insurance');
//             },
//           ),
//           ListTile(
//             title: Text(
//               'Investment',
//               style: TextStyle(color: const Color.fromARGB(255, 142, 140, 140)),
//             ),
//             onTap: () {
//               Navigator.pop(context, 'Investment');
//             },
//           ),
//           ListTile(
//             title: Text(
//               'Loan',
//               style: TextStyle(color: const Color.fromARGB(255, 142, 140, 140)),
//             ),
//             onTap: () {
//               Navigator.pop(context, 'Loan');
//             },
//           ),
//           ListTile(
//             title: Text(
//               'Mortgage',
//               style: TextStyle(color: const Color.fromARGB(255, 142, 140, 140)),
//             ),
//             onTap: () {
//               Navigator.pop(context, 'Mortgage');
//             },
//           ),
//           ListTile(
//             title: Text(
//               'Account with overdraft',
//               style: TextStyle(color: const Color.fromARGB(255, 142, 140, 140)),
//             ),
//             onTap: () {
//               Navigator.pop(context, 'Account with overdraft');
//             },
//           ),
//         ],
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.only(left: 300),
//         child: TextButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           child: Text(
//             'CANCEL',
//             style: TextStyle(fontSize: 18, color: Colors.blue),
//           ),
//         ),
//       ),
//     );
//   }
// }