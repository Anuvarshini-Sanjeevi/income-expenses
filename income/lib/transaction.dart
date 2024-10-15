import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlusPageEdit extends StatefulWidget {
  final String transactionId;

  PlusPageEdit({required this.transactionId});

  @override
  _PlusPageEditState createState() => _PlusPageEditState();
}

class _PlusPageEditState extends State<PlusPageEdit> {
  final _formKey = GlobalKey<FormState>();
  final payeeController = TextEditingController();
  final noteController = TextEditingController();
  final amountController = TextEditingController();

  String? selectedCategory;
  String? selectedAccount;
  String? selectedCategoryForTransfer;
  bool isIncome = false;
  bool isTransfer = false;
  String? selectedPlace;
  String? selectedAttachment;
  DateTime? selectedDate; // To manage selected date
  TimeOfDay? selectedTime; // To manage selected time

  List<String> accounts = [];
  List<Map<String, dynamic>> categories = [];
  List<String> payeeSuggestions = []; // List to store payee suggestions

  @override
  void initState() {
    super.initState();
    _fetchAccountsFromFirestore(); // Fetch accounts
    _loadTransactionDetails(widget.transactionId); // Load transaction details
    _loadPayeeSuggestions(); // Fetch payee suggestions
  }

  // Load payee suggestions from Firestore
  Future<void> _loadPayeeSuggestions() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('payees')
            .get();

        setState(() {
          payeeSuggestions = snapshot.docs
              .map((doc) => doc.get('payeeName') as String)
              .toList();
        });
      } catch (e) {
        print("Error fetching payee suggestions: $e");
      }
    }
  }

  Future<void> _loadTransactionDetails(String transactionId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot transaction = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (transaction.exists) {
        setState(() {
          amountController.text = transaction['amount'].toString();
          selectedCategory = transaction['label'];
          selectedAccount = transaction['paymentTypeFrom'];
          payeeController.text = transaction['payee'];
          noteController.text = transaction['note'];
          selectedPlace = transaction['place'];
          selectedAttachment = transaction['attachment'];
          _fetchCategoriesFromFirestore(); // Fetch categories
          _fetchAccountsFromFirestore(); // Fetch accounts
        });
      }
    }
  }

  Future<void> _updateTransactionInFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(widget.transactionId)
          .update({
        'amount': double.tryParse(amountController.text) ?? 0.0,
        'label': selectedCategory,
        'payee': payeeController.text,
        'note': noteController.text,
        'paymentTypeFrom': selectedAccount,
        'place': selectedPlace,
        'attachment': selectedAttachment,
        'date': DateTime.now(),
      });

      // Add payee to suggestions if not already present
      if (!payeeSuggestions.contains(payeeController.text)) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('payees')
            .add({'payeeName': payeeController.text});
      }
    }
  }

  Future<void> _fetchCategoriesFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final collectionName = isIncome ? 'income' : 'expense';
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('category')
            .doc(collectionName)
            .collection('items')
            .get();

        final fetchedCategories = snapshot.docs.map((doc) {
          final categoryName = doc.get('name') as String;
          final subcategories = doc.get('subcategories') as List<dynamic>;
          return {
            'categoryName': categoryName,
            'subcategories': subcategories.cast<String>(),
          };
        }).toList();

        setState(() {
          categories = fetchedCategories;
          if (selectedCategory == null && categories.isNotEmpty) {
            selectedCategory = categories.first['categoryName'] as String?;
          }
        });
      } catch (e) {
        print("Error fetching categories: $e");
      }
    }
  }

  Future<void> _fetchAccountsFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('accounts')
            .get();

        final fetchedAccounts = snapshot.docs.map((doc) {
          return doc.get('accountName') as String;
        }).toList();

        setState(() {
          accounts = fetchedAccounts;
          if (selectedAccount == null && accounts.isNotEmpty) {
            selectedAccount = accounts.first;
          }
        });
      } catch (e) {
        print("Error fetching accounts: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Transaction'),
        backgroundColor: Colors.yellow,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              if (_formKey.currentState?.validate() == true) {
                await _updateTransactionInFirestore();
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButton<String>(
                value:
                    isIncome ? 'Income' : (isTransfer ? 'Transfer' : 'Expense'),
                items: ['Income', 'Expense', 'Transfer'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    isIncome = newValue == 'Income';
                    isTransfer = newValue == 'Transfer';
                    _fetchCategoriesFromFirestore(); // Fetch new categories based on type
                  });
                },
              ),
              _buildTextField("Amount", "Enter amount", amountController),
              _buildTextField("Note", "Description", noteController),
              if (!isTransfer) _buildStaticField('Category', selectedCategory),
              if (!isTransfer)
                _buildPayeeField(), // Payee field with suggestions
              if (isTransfer)
                Column(
                  children: [
                    _buildStaticField("From Account", selectedAccount),
                    _buildStaticField("To Account", selectedCategoryForTransfer,
                        isTransfer: true),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeButton(
                      "Date",
                      "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
                      _pickDate,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTimeButton(
                      "Time",
                      TimeOfDay.now().format(context),
                      _pickTime,
                    ),
                  ),
                ],
              ),
              if (!isTransfer) _buildStaticField("Account", selectedAccount),
              if (!isTransfer)
                _buildAddButton(
                    "Place", selectedPlace, () => _pickPlace(context)),
              _buildAddButton(
                  "Attachments", selectedAttachment, _pickAttachment),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }

  Widget _buildStaticField(String label, String? value,
      {bool isTransfer = false}) {
    return ListTile(
      title: Text('$label: ${value ?? 'Not selected'}'),
      trailing: Icon(Icons.edit),
      onTap: () {
        if (label == 'Account' ||
            label == 'From Account' ||
            label == 'To Account') {
          _showAccountSelectionDialog(isFromAccount: label == 'From Account');
        } else if (label == 'Category') {
          _showCategorySelectionDialog();
        }
      },
    );
  }

  Widget _buildDateTimeButton(String label, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(value),
      trailing: Icon(Icons.arrow_drop_down),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
      visualDensity: VisualDensity(vertical: -4),
      tileColor: Colors.grey[100],
    );
  }

  Widget _buildAddButton(
      String label, String? value, Future<void> Function() onTap) {
    return ListTile(
      title: Text('$label: ${value ?? 'None'}'),
      trailing: Icon(Icons.add),
      onTap: onTap,
    );
  }

  Widget _buildPayeeField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return payeeSuggestions.where((payee) {
          return payee
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        payeeController.text = selection;
      },
      fieldViewBuilder: (BuildContext context, TextEditingController controller,
          FocusNode focusNode, VoidCallback onFieldSubmitted) {
        return TextFormField(
          controller: payeeController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Payee',
            hintText: 'Enter or select a payee',
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  Future<void> _pickPlace(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlacePicker(
          onPlacePicked: (place) {
            setState(() {
              selectedPlace = place;
            });
          },
        ),
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          selectedAttachment = result.files.first.name;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Storage permission is required to pick files.")),
      );
    }
  }

  void _showCategorySelectionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select ${isIncome ? "Income" : "Expense"} Category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index]['categoryName'];
                    final subcategories =
                        categories[index]['subcategories'] as List<String>;

                    return ExpansionTile(
                      title: Text(category),
                      children: subcategories.map((sub) {
                        return ListTile(
                          title: Text(sub),
                          onTap: () {
                            setState(() {
                              selectedCategory = sub;
                              Navigator.pop(context);
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // void _showAccountSelectionDialog({bool isFromAccount = true}) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) {
  //       return Container(
  //         padding: EdgeInsets.all(16.0),
  //         child: ListView.builder(
  //           itemCount: accounts.length,
  //           itemBuilder: (context, index) {
  //             final account = accounts[index];

  //             return ListTile(
  //               title: Text(account),
  //               onTap: () {
  //                 Navigator.pop(context, account);
  //               },
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   ).then((selectedAccount) {
  //     if (selectedAccount != null) {
  //       setState(() {
  //         if (isFromAccount) {
  //           this.selectedAccount = selectedAccount;
  //         } else {
  //           selectedCategoryForTransfer = selectedAccount;
  //         }
  //       });
  //     }
  //   });
  // }

  void _showAccountSelectionDialog({bool isFromAccount = true}) async {
    final selectedAccount = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];

              return ListTile(
                title: Text(account),
                onTap: () {
                  Navigator.pop(context, account);
                },
              );
            },
          ),
        );
      },
    );

    if (selectedAccount != null) {
      setState(() {
        if (isFromAccount) {
          this.selectedAccount = selectedAccount;
        } else {
          this.selectedAccount = selectedAccount;
          selectedCategoryForTransfer = selectedAccount;
        }
      });
    }
  }
}

class PlacePicker extends StatefulWidget {
  final Function(String) onPlacePicked;

  PlacePicker({required this.onPlacePicked});

  @override
  _PlacePickerState createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  String _pickedPlace = "";
  List<String> allPlaces = [
    'Chennai, Tamil Nadu',
    'Coimbatore, Tamil Nadu',
    'Madurai, Tamil Nadu',
    'Tiruchirappalli, Tamil Nadu',
    'Salem, Tamil Nadu',
    'Erode, Tamil Nadu',
    'Vellore, Tamil Nadu',
    'Kanchipuram, Tamil Nadu',
    'Tirunelveli, Tamil Nadu',
    'Kumbakonam, Tamil Nadu',
    'Thanjavur, Tamil Nadu',
    'Nagapattinam, Tamil Nadu',
    'Dharmapuri, Tamil Nadu',
    'Karur, Tamil Nadu',
    'Ramanathapuram, Tamil Nadu',
    'Sivagangai, Tamil Nadu',
    'Dindigul, Tamil Nadu',
    'Tenkasi, Tamil Nadu',
    'Cuddalore, Tamil Nadu',
    'Ariyalur, Tamil Nadu',
    'Krishnagiri, Tamil Nadu',
    'Delhi',
    'Maharashtra',
    'West Bengal',
    'Karnataka',
    'Telangana',
    'Gujarat',
    'Rajasthan',
    'Uttar Pradesh',
    'Madhya Pradesh',
    'Andhra Pradesh',
    'Kerala',
    'Goa',
    'Punjab',
    'Haryana',
    'Bihar',
    'Jharkhand',
    'Odisha',
    'Chhattisgarh',
    'Assam',
    'Tripura',
    'Meghalaya',
    'Nagaland',
    'Manipur',
    'Arunachal Pradesh',
    'Sikkim',
    'Himachal Pradesh',
    'Uttarakhand',
    'Jammu & Kashmir',
    'Ladakh',
    'Puducherry',
    'Chandigarh',
    'Dadra & Nagar Haveli and Daman & Diu'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select a Place"),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              widget.onPlacePicked(_pickedPlace);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TypeAheadField<String>(
              suggestionsCallback: (pattern) async {
                return pattern.isEmpty
                    ? allPlaces
                    : await _getPlaceSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              onSelected: (suggestion) {
                setState(() {
                  _pickedPlace = suggestion;
                });
              },
            ),
            SizedBox(height: 20),
            if (_pickedPlace.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Selected Place: $_pickedPlace',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _getPlaceSuggestions(String query) async {
    return allPlaces
        .where((place) => place.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

  