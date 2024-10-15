// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:income/budget.dart';
// import 'statistics.dart';

// void main() => runApp(filter());

// class filter extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: FilterPage(),
//     );
//   }
// }

// class FilterPage extends StatefulWidget {
//   @override
//   _FilterPageState createState() => _FilterPageState();
// }

// class _FilterPageState extends State<FilterPage> {
//   String? selectedType;
//   String? selectedRecordConfirmation;
//   String? selectedCategory;
//   String? selectedCurrency;
//   String? selectedPaymentType;
//   String? selectedStatus;
//   bool includeTransfers = true;
//   bool includeDebts = true;

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//        theme: ThemeData(
//         textTheme: GoogleFonts.gupterTextTheme(Theme.of(context).textTheme),
//       ),
//     home:Scaffold(
//       appBar: AppBar(
//         title: Center(
//           child: Text(
//             'Add filter',
//             style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
//           ),
//         ),
//         leading: Builder(
//           builder: (BuildContext context) {
//             return IconButton(
//               icon: const Icon(
//                 Icons.close,
//                 color: Colors.white,
//               ),
//               onPressed: () {
//                Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>bottomnav()));
//               },
              
//             );
//           },
//         ),
//         backgroundColor: Colors.green[400],
//         actions: [
//           IconButton(
//             icon: const Icon(
//               Icons.check,
//               color: Colors.white,
//             ),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => Statistics(
//                     type: selectedType,
//                     recordConfirmation: selectedRecordConfirmation,
//                     category: selectedCategory,
//                     currency: selectedCurrency,
//                     paymentType: selectedPaymentType,
//                     status: selectedStatus,
//                     includeTransfers: includeTransfers,
//                     includeDebts: includeDebts,
//                   ),
//                 ),
//               );
//             },
//             tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             buildDropdown('Type', ['Both', 'Type1', 'Type2'], selectedType, (newValue) {
//               setState(() {
//                 selectedType = newValue;
//               });
//             }),
//             buildDropdown('Record confirmation', ['All', 'Confirmed', 'Unconfirmed'], selectedRecordConfirmation, (newValue) {
//               setState(() {
//                 selectedRecordConfirmation = newValue;
//               });
//             }),
//             buildDropdown('Categories', ['All', 'Category1', 'Category2'], selectedCategory, (newValue) {
//               setState(() {
//                 selectedCategory = newValue;
//               });
//             }),
//             buildLabel(),
//             buildDropdown('Currencies', ['All', 'USD', 'EUR'], selectedCurrency, (newValue) {
//               setState(() {
//                 selectedCurrency = newValue;
//               });
//             }),
//             buildDropdown('Payment Type', ['All', 'Cash', 'Credit Card'], selectedPaymentType, (newValue) {
//               setState(() {
//                 selectedPaymentType = newValue;
//               });
//             }),
//             buildDropdown('Status', ['All', 'Active', 'Inactive'], selectedStatus, (newValue) {
//               setState(() {
//                 selectedStatus = newValue;
//               });
//             }),
//             buildSwitch('Transfers', includeTransfers, (newValue) {
//               setState(() {
//                 includeTransfers = newValue;
//               });
//             }),
//             buildSwitch('Debts', includeDebts, (newValue) {
//               setState(() {
//                 includeDebts = newValue;
//               });
//             }),
//           ],
//         ),
//       ),
//     ),
//     );
//   }

//   Widget buildDropdown(String label, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: DropdownButtonFormField<String>(
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(),
//         ),
//         value: selectedValue,
//         onChanged: onChanged,
//         items: items.map((item) {
//           return DropdownMenuItem<String>(
//             value: item,
//             child: Text(item),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget buildLabel() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: TextFormField(
//         decoration: InputDecoration(
//           labelText: 'Labels',
//           border: OutlineInputBorder(),
//           suffixIcon: IconButton(
//             icon: Icon(Icons.add),
//             onPressed: () {
//               // Handle add label
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Switch(
//             value: value,
//             onChanged: onChanged,
//           ),
//         ],
//       ),
//     );
//   }
// }
