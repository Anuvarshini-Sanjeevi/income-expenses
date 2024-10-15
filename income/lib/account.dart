import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;

class NewAccountScreen extends StatefulWidget {
  @override
  _NewAccountScreenState createState() => _NewAccountScreenState();
}

class _NewAccountScreenState extends State<NewAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _bankAccountNumberController = TextEditingController();
  final TextEditingController _initialValueController = TextEditingController();

  String? _selectedType;
  String? _selectedCurrency;
  Color _selectedColor = Colors.blue;  // Default color
  double _conversionRate = 1.0;  // Default conversion rate (1 INR = 1 INR)
  List<String> _currencyList = [];  // Initially empty

  @override
  void initState() {
    super.initState();
    _selectedType = 'General';  // Default type

    _fetchCurrencyList().then((currencies) {
      setState(() {
        _currencyList = currencies;
        if (_currencyList.isNotEmpty) {
          _selectedCurrency = _currencyList.first;  // Set the first currency as the default
          _fetchConversionRate();  // Fetch conversion rate for the default currency
        }
      });
    }).catchError((error) {
      // Handle errors and display a message to the user
      setState(() {
        _currencyList = [];
        _selectedCurrency = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No currencies found. Please add a new currency.')),
      );
    });
  }

  Future<List<String>> _fetchCurrencyList() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('currencies')
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => doc.data()['code'] as String).toList();
      } else {
        throw Exception('No currencies found');
      }
    } catch (e) {
      print('Error fetching currency list: $e');
      return [];
    }
  }

  Future<void> _fetchConversionRate() async {
    if (_selectedCurrency == null) return;

    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/INR'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _conversionRate = 1 / (data['rates'][_selectedCurrency] ?? 1.0);  // Get conversion rate from selected currency to INR
        });
      } else {
        throw Exception('Failed to load conversion rate');
      }
    } catch (e) {
      print('Error fetching conversion rate: $e');
    }
  }

  void _saveAccount() {
    if (_formKey.currentState?.validate() ?? false) {
      // Convert the initial value to INR before saving
      final double initialValue = double.tryParse(_initialValueController.text) ?? 0.0;
      final double convertedValue = initialValue * _conversionRate;

      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('accounts')
          .add({
        'accountName': _accountNameController.text,
        'bankAccountNumber': _bankAccountNumberController.text,
        'type': _selectedType,
        'initialValue': convertedValue,  // Save as INR
        'currency': 'INR',  // Store currency as INR
        'color': _selectedColor.value.toRadixString(16),  // Save color as hex string
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account saved successfully')),
        );
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save account: $error')),
        );
      });
    }
  }

  void _showAccountsPopup() {
    // Implement the popup to show existing accounts if needed
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 600;

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
              Navigator.pop(context);
            },
          ),
          title: Text('New Account', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green[400],
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _saveAccount,
            ),
           
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isWideScreen ? 24.0 : 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: _accountNameController,
                    decoration: InputDecoration(labelText: 'Account name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter account name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isWideScreen ? 24.0 : 16.0),
                  TextFormField(
                    controller: _bankAccountNumberController,
                    decoration: InputDecoration(labelText: 'Bank account number'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter bank account number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isWideScreen ? 24.0 : 16.0),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(labelText: 'Type'),
                    items: [
                      'General',
                      'Savings',
                      'Current account',
                      'Credit card',
                      'Saving account',
                      'Bonus',
                      'Insurance',
                      'Investment',
                      'Loan',
                      'Mortgage',
                      'Account with overdraft',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                  SizedBox(height: isWideScreen ? 24.0 : 16.0),
                  TextFormField(
                    controller: _initialValueController,
                    decoration: InputDecoration(labelText: 'Initial value'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter initial value';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isWideScreen ? 24.0 : 16.0),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: InputDecoration(labelText: 'Currency'),
                    items: _currencyList.map((String code) {
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(code),  // Displaying the currency code
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value;
                        _fetchConversionRate();  // Fetch conversion rate when currency changes
                      });
                    },
                    validator: (value) {
                      if (value == null || !_currencyList.contains(value)) {
                        return 'Please select a valid currency';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isWideScreen ? 24.0 : 16.0),
                  Text('Select Color'),
                  SizedBox(height: 8.0),
                  GestureDetector(
                    onTap: () async {
                      Color? selectedColor = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Select Color'),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: _selectedColor,
                                onColorChanged: (color) {
                                  Navigator.of(context).pop(color);
                                },
                              ),
                            ),
                          );
                        },
                      );
                      if (selectedColor != null) {
                        setState(() {
                          _selectedColor = selectedColor;
                        });
                      }
                    },
                    child: Container(
                      width: 500,
                      height: 40,
                      color: _selectedColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
