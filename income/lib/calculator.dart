import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'homepage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AddIncomeExpense extends StatefulWidget {
  @override
  _AddIncomeExpenseState createState() => _AddIncomeExpenseState();
}

class _AddIncomeExpenseState extends State<AddIncomeExpense> {
  String selectedCategory = 'EXPENSE';
  String displayText = '0';
  String category = '';
  String? previousValue;
  String? operation;
  bool isNewNumber = true;

  List<String> accounts = [];
  List<Map<String, dynamic>> categories = [];
  String? selectedAccount;
  String? selectedCategoryForTransfer;

  @override
  void initState() {
    super.initState();
    _fetchAccountsFromFirestore();
    _fetchCategoriesFromFirestore(); // Fetch categories on init
  }

  Future<void> _fetchAccountsFromFirestore() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('accounts')
            .get();
        setState(() {
          accounts =
              snapshot.docs.map((doc) => doc['accountName'] as String).toList();
          if (accounts.isNotEmpty) {
            selectedAccount = accounts.first; // Set default selected account
          }
        });
      } else {
        print('User not logged in');
      }
    } catch (e) {
      // Handle error
      print('Error fetching accounts: $e');
    }
  }

  void onNumberClick(String number) {
    setState(() {
      if (displayText == '0' || isNewNumber) {
        displayText = number;
        isNewNumber = false;
      } else {
        displayText += number;
      }
    });
  }

  void onClearClick() {
    setState(() {
      displayText = '0';
      previousValue = null;
      operation = null;
      isNewNumber = true;
    });
  }

  Future<void> _fetchCategoriesFromFirestore() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Check if it's 'INCOME' or 'EXPENSE'
        final String collectionName =
            selectedCategory == 'INCOME' ? 'income' : 'expense';

        // Fetch categories and subcategories
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('category')
            .doc(collectionName)
            .collection('items')
            .get();

        final List<Map<String, dynamic>> fetchedCategories = [];
        for (var doc in snapshot.docs) {
          // Get category name and subcategories
          final String categoryName = doc.get('name');
          final List<dynamic> subcategories =
              doc.get('subcategories') as List<dynamic>;

          // Map category name with subcategories
          fetchedCategories.add({
            'categoryName': categoryName,
            'subcategories': subcategories.cast<String>(),
          });
        }

        setState(() {
          categories.clear();
          categories.addAll(fetchedCategories);
          if (categories.isNotEmpty) {
            category = categories
                .first['categoryName']; // Select first category as default
          }
        });
      } catch (e) {
        print("Error fetching categories: $e");
      }
    } else {
      print('User not logged in');
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
                'Select $selectedCategory Category',
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
                      children: subcategories.map((subcategory) {
                        return ListTile(
                          title: Text(subcategory),
                          onTap: () {
                            setState(() {
                              this.category =
                                  subcategory; // Set selected subcategory
                            });
                            Navigator.pop(context); // Close modal
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

  Future<void> _showAccountSelectionDialog(
      {required bool isFromAccount}) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              accounts.isEmpty
                  ? Text('No accounts available.')
                  : Expanded(
                      child: ListView.builder(
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(accounts[index]),
                            onTap: () async {
                              setState(() {
                                if (isFromAccount) {
                                  selectedAccount = accounts[index];
                                } else {
                                  selectedCategoryForTransfer = accounts[index];
                                }
                              });

                              try {
                                User? user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('selectedAccounts')
                                      .doc(isFromAccount
                                          ? 'fromAccount'
                                          : 'toAccount')
                                      .set({
                                    'accountName': isFromAccount
                                        ? selectedAccount
                                        : selectedCategoryForTransfer,
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Account selected')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('User not logged in')),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Error saving account: $e')),
                                );
                              }

                              Navigator.pop(context);
                            },
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

  void onCategoryChange(String category) {
    setState(() {
      selectedCategory = category;
      displayText = '0';
    });
  }

  void onOperatorClick(String op) {
    setState(() {
      if (previousValue != null && operation != null) {
        performCalculation();
      }
      previousValue = displayText;
      operation = op;
      isNewNumber = true;
    });
  }

  void onEqualsClick() {
    setState(() {
      if (previousValue != null && operation != null) {
        performCalculation();
        previousValue = null;
        operation = null;
      }
    });
  }

  void performCalculation() {
    if (previousValue != null && operation != null) {
      double num1 = double.parse(previousValue!);
      double num2 = double.parse(displayText);
      double result = 0;

      switch (operation) {
        case '+':
          result = num1 + num2;
          break;
        case '-':
          result = num1 - num2;
          break;
        case '*':
          result = num1 * num2;
          break;
        case '÷':
          result = num1 / num2;
          break;
      }

      displayText = result.toStringAsFixed(2);
      isNewNumber = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          // logic
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Color.fromARGB(243, 255, 191, 0),
            leading: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Homepage(),
                  ),
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.check, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PlusPage(selectedCategory, displayText, category),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      color: Color.fromARGB(243, 255, 191, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTab("INCOME", 'INCOME'),
                          _buildTab("EXPENSE", 'EXPENSE'),
                          _buildTab("TRANSFER", 'TRANSFER'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            color: Color.fromARGB(243, 255, 191, 0),
                            height: MediaQuery.of(context).size.height * 0.25,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        selectedCategory == 'EXPENSE'
                                            ? '-'
                                            : selectedCategory == 'INCOME'
                                                ? '+'
                                                : '',
                                        style: TextStyle(
                                          fontSize: 80,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        displayText,
                                        style: TextStyle(
                                          fontSize: 80,
                                          color: Colors.white,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "INR",
                                        style: TextStyle(
                                          fontSize: 36,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: selectedCategory == 'TRANSFER'
                                      ? [
                                          _buildAccountSelector("From Account",
                                              selectedAccount, true),
                                          _buildAccountSelector(
                                              "To Account",
                                              selectedCategoryForTransfer,
                                              false),
                                        ]
                                      : [
                                          Column(
                                            children: [
                                              Text(
                                                "Account",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              GestureDetector(
                                                onTap: () =>
                                                    _showAccountSelectionDialog(
                                                        isFromAccount: true),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 5,
                                                      horizontal: 10),
                                                  decoration: BoxDecoration(
                                                    color: Color.fromARGB(
                                                        243, 255, 191, 0),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: Text(
                                                    selectedAccount ??
                                                        'Select Account',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                "Category",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              GestureDetector(
                                                onTap:
                                                    _showCategorySelectionDialog,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 5,
                                                      horizontal: 10),
                                                  decoration: BoxDecoration(
                                                    color: Color.fromARGB(
                                                        243, 255, 191, 0),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: Text(
                                                    category.isNotEmpty
                                                        ? category
                                                        : 'Select Category',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: GridView.builder(
                                    physics: NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: 12,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 3.0,
                                      mainAxisSpacing: 0.0,
                                    ),
                                    itemBuilder: (context, index) {
                                      switch (index) {
                                        case 0:
                                          return _buildTappableButton('7');
                                        case 1:
                                          return _buildTappableButton('8');
                                        case 2:
                                          return _buildTappableButton('9');
                                        case 3:
                                          return _buildTappableButton('4');
                                        case 4:
                                          return _buildTappableButton('5');
                                        case 5:
                                          return _buildTappableButton('6');
                                        case 6:
                                          return _buildTappableButton('1');
                                        case 7:
                                          return _buildTappableButton('2');
                                        case 8:
                                          return _buildTappableButton('3');
                                        case 9:
                                          return _buildTappableButton('.');
                                        case 10:
                                          return _buildTappableButton('0');
                                        case 11:
                                          return _buildIconButton();
                                        default:
                                          return Container();
                                      }
                                    },
                                  ),
                                ),
                                Container(
                                  width: 70,
                                  height: double.infinity,
                                  color: Colors.grey[400],
                                  child: Column(
                                    children: [
                                      Expanded(
                                          child: _buildTappableOperatorButton(
                                              '+')),
                                      Expanded(
                                          child: _buildTappableOperatorButton(
                                              '-')),
                                      Expanded(
                                          child: _buildTappableOperatorButton(
                                              '*')),
                                      Expanded(
                                          child: _buildTappableOperatorButton(
                                              '÷')),
                                      Expanded(
                                          child: _buildTappableOperatorButton(
                                              '=')),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildTab(String label, String categoryType) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = categoryType;
          displayText = '0'; // Reset the display text when switching tabs
          isNewNumber = true; // Prepare for a new number input
          _fetchCategoriesFromFirestore(); // Fetch categories when tab is selected
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: selectedCategory == categoryType
                  ? Colors.white
                  : Colors.white,
              fontWeight: selectedCategory == categoryType
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: 20,
            ),
          ),
          if (selectedCategory == categoryType)
            Container(
              height: 4,
              width: 50,
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget _buildAccountSelector(
      String title, String? selectedAccount, bool isFromAccount) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        GestureDetector(
          onTap: () =>
              _showAccountSelectionDialog(isFromAccount: isFromAccount),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Color.fromARGB(243, 255, 191, 0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              selectedAccount ?? 'Select Account',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTappableButton(String number) {
    return GestureDetector(
      onTap: () => onNumberClick(number),
      child: Container(
        alignment: Alignment.center,
        color: Colors.white,
        child: Text(
          number,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildTappableOperatorButton(String operator) {
    return GestureDetector(
      onTap: () => onOperatorClick(operator),
      child: Container(
        alignment: Alignment.center,
        height: 89,
        color: Colors.grey[200],
        child: Text(
          operator,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildIconButton() {
    return GestureDetector(
      onTap: onClearClick,
      child: Container(
        alignment: Alignment.center,
        color: Colors.white,
        child: Icon(
          Icons.backspace_sharp,
          size: 30,
          color: Colors.black,
        ),
      ),
    );
  }
}

class PlusPage extends StatefulWidget {
  final String
      selectedCategory; // The category ('INCOME', 'EXPENSE', or 'TRANSFER')
  final String amount; // The amount to be displayed on the page
  final String category; // The specific category selected by the user

  PlusPage(this.selectedCategory, this.amount, this.category);

  @override
  _PlusPageState createState() => _PlusPageState();
}

class _PlusPageState extends State<PlusPage> {
  String selectedLabel =
      "No category selected"; // Default to no category selected
  String selectedAttachment = "ADD ATTACHMENT";
  String selectedPlace = "ADD PLACE";
  String selectedAccountFrom = "Loading..."; // From Account
  String selectedAccountTo = "Loading..."; // To Account (For transfer)
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isIncome = true;
  bool isTransfer = false; // New flag for transfer
  final TextEditingController noteController = TextEditingController();
  final TextEditingController payeeController = TextEditingController();

  // Additional fields for Warranty and Status
  String selectedWarranty = "None";
  String selectedStatus = "Cleared";

  @override
  void initState() {
    super.initState();
    isIncome = widget.selectedCategory == 'INCOME';
    isTransfer =
        widget.selectedCategory == 'TRANSFER'; // Detect if it's a transfer
    selectedLabel = widget.category; // Set the selected category as the label
    _payeeFocusNode.addListener(() {
      if (!_payeeFocusNode.hasFocus) {
        // Hide suggestions when the payee field loses focus
        setState(() {
          payeeSuggestions.clear();
        });
      }
    });
    _loadDefaultAccounts();
    _loadPreviousPayees();
  }

  Future<void> _loadDefaultAccounts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        selectedAccountFrom = "User not logged in";
        selectedAccountTo = "User not logged in";
      });
      return;
    }

    try {
      // Load the default "from" account
      final docFrom = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('selectedAccounts')
          .doc('fromAccount')
          .get();
      if (docFrom.exists) {
        setState(() {
          selectedAccountFrom =
              docFrom.data()?['accountName'] ?? "No default from account";
        });
      }

      // Load the default "to" account for transfers
      final docTo = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('selectedAccounts')
          .doc('toAccount')
          .get();
      if (docTo.exists) {
        setState(() {
          selectedAccountTo =
              docTo.data()?['accountName'] ?? "No default to account";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          selectedAccountFrom = "Error loading account";
          selectedAccountTo = "Error loading account";
        });
      }
    }
  }

  Future<void> _updateAccountBalance(String paymentType, double amount,
      {bool isDeduction = false}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .where('accountName', isEqualTo: paymentType)
          .get();

      for (var doc in querySnapshot.docs) {
        final currentBalance =
            (doc.data()['initialValue'] as num?)?.toDouble() ?? 0.0;
        final newBalance =
            isDeduction ? currentBalance - amount : currentBalance + amount;

        await doc.reference.update({'initialValue': newBalance});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update account balance: $e")),
      );
    }
  }

  Future<void> _saveToFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in!")),
      );
      return;
    }

    final double? amount = double.tryParse(widget.amount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Amount must be greater than zero.")),
      );
      return;
    }

    // Check if the account has sufficient balance for expenses and transfers
    if (!isIncome && !await _hasSufficientFunds(selectedAccountFrom, amount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Insufficient account balance.")),
      );
      return;
    }

    final data = {
      'category': isIncome ? 'Income' : (isTransfer ? 'Transfer' : 'Expense'),
      'label': selectedLabel,
      'attachment': selectedAttachment,
      'place': selectedPlace,
      'date': selectedDate?.toIso8601String(),
      'time': selectedTime?.format(context),
      'timestamp': FieldValue.serverTimestamp(),
      'amount': amount,
      'userId': user.uid,
      'paymentTypeFrom': selectedAccountFrom, // For transfer
      'paymentTypeTo': isTransfer ? selectedAccountTo : null, // For transfer
      'note': noteController.text, // Save the note
      'payee': payeeController.text, // Save the payee
    };

    try {
      // Save transaction to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add(data);

      // Update the account balances based on type
      if (isIncome) {
        await _updateAccountBalance(selectedAccountFrom, amount);
      } else if (isTransfer) {
        // Deduct from 'from' account and add to 'to' account for transfers
        await _updateAccountBalance(selectedAccountFrom, amount,
            isDeduction: true);
        await _updateAccountBalance(selectedAccountTo, amount,
            isDeduction: false);
      } else {
        await _updateAccountBalance(selectedAccountFrom, amount,
            isDeduction: true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaction saved and accounts updated!")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save data: $error")),
      );
    }
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

  @override
  void dispose() {
    payeeController.dispose();
    _payeeFocusNode.dispose();
    super.dispose();
  }

  void _validateAndProceed() {
    if (payeeController.text.isEmpty) {
      // Show error if the payee name is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payee name is required')),
      );
    } else {
      // Proceed with logic (e.g., submit the form or navigate to another page)
      // ...
      print('Proceed with payee: ${payeeController.text}');
    }
  }

  List<String> payeeSuggestions = []; // Store payee suggestions
  List<String> previousPayees = []; // Store previous payees
  FocusNode _payeeFocusNode = FocusNode();



  Future<void> _loadPreviousPayees() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      previousPayees = prefs.getStringList('previousPayees') ?? [];
    });
  }

  // Save the payee to SharedPreferences
  Future<void> _savePayee(String payeeName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!previousPayees.contains(payeeName)) {
      previousPayees.add(payeeName); // Add new payee to the list
      await prefs.setStringList('previousPayees', previousPayees);
    }
  }


  @override
  final _formKey = GlobalKey<FormState>(); 
  
  Widget build(BuildContext context) {
    final double? amount = double.tryParse(widget.amount);

    // Check if the amount is valid and greater than 0
    if (amount == null || amount <= 0) {
      // Show an error message before navigating back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Amount should be greater than 0')),
        );
        Navigator.pop(context); // Navigate back to the previous page
      });
      return SizedBox.shrink(); // Return an empty widget until navigation happens
    }

    String displayAmount = isIncome
        ? '+${widget.amount}'
        : (isTransfer ? 'Transfer: ${widget.amount}' : '-${widget.amount}');

    return Scaffold(
      appBar: AppBar(
        title: Text(displayAmount),
        backgroundColor: Colors.yellow,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              if (_formKey.currentState?.validate() == true) {
                // Proceed with saving data if form is valid
                await _savePayee(payeeController.text); // Save payee name
                await _saveToFirestore();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: GestureDetector(
        // Detect taps outside the input field to dismiss the keyboard and suggestions
        onTap: () {
          FocusScope.of(context).unfocus();
        },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButton<String>(
                value: isIncome
                    ? 'Income'
                    : (isTransfer ? 'Transfer' : 'Expense'),
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
                  });
                },
              ),
              _buildTextField("Note", "Description", noteController),
              if (!isTransfer) _buildStaticField('Category', selectedLabel),

              // Payee text field with suggestion logic
              if (!isTransfer)
                TextFormField(
                  controller: payeeController,
                  focusNode: _payeeFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Payee',
                    hintText: 'Enter payee name',
                    
                    suffixIcon: Icon(Icons.person, color: Colors.grey),
                  ),
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  onChanged: (value) {
                    setState(() {
                      payeeSuggestions = previousPayees
                          .where((payee) =>
                              payee.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Payee name is required';
                    }
                    return null;
                  },
                ),

              SizedBox(height: 8.0),

              // Display the suggestions only when the list is not empty
              if (payeeSuggestions.isNotEmpty)
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10.0,
                            spreadRadius: 1.0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: payeeSuggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Icon(Icons.person, color: Colors.grey[600]),
                            title: Text(
                              payeeSuggestions[index],
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                            onTap: () {
                              setState(() {
                                payeeController.text =
                                    payeeSuggestions[index];
                                payeeSuggestions.clear(); // Clear suggestions once selected
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // Other form fields
              if (isTransfer)
                Column(
                  children: [
                    _buildStaticField("From Account", selectedAccountFrom),
                    _buildStaticField("To Account", selectedAccountTo, isTransfer: true),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeButton(
                      "Date",
                      selectedDate == null
                          ? "Select Date"
                          : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                      _pickDate,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTimeButton(
                      "Time",
                      selectedTime == null
                          ? "Select Time"
                          : selectedTime!.format(context),
                      _pickTime,
                    ),
                  ),
                ],
              ),
              if (!isTransfer)
                _buildStaticField("Account", selectedAccountFrom),
              if (!isTransfer)
                _buildDropDownField(
                    "Warranty", selectedWarranty, ["None", "Applicable"]),
              if (!isTransfer)
                _buildDropDownField(
                    "Status", selectedStatus, ["Cleared", "Not Cleared"]),
              if (!isTransfer)
                _buildAddButton(
                    "Place", selectedPlace, () => _pickPlace(context)),
              _buildAddButton(
                  "Attachments", selectedAttachment, _pickAttachment),
            ],
          ),
        ),
      ),
    ));
  }


  Widget _buildTextField(
      String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required'; // Display error if field is empty
          }
          return null; // No error if input is valid
        },
      ),
    );
  }

  Widget _buildAddButton(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(value),
          trailing: Icon(Icons.add),
          onTap: onTap,
        ),
      ],
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

  Widget _buildDropDownField(String choice, String value, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: choice),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            if (choice == "Warranty") {
              selectedWarranty = newValue!;
            } else if (choice == "Status") {
              selectedStatus = newValue!;
            }
          });
        },
      ),
    );
  }

  Widget _buildStaticField(String label, String value,
      {bool isTransfer = false}) {
    return ListTile(
      title: Text(value),
      trailing: isTransfer ? Icon(Icons.account_balance_wallet_outlined) : null,
    );
  }

  Future<bool> _hasSufficientFunds(String paymentType, double amount) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .where('accountName', isEqualTo: paymentType)
          .get();

      for (var doc in querySnapshot.docs) {
        final currentBalance =
            (doc.data()['initialValue'] as num?)?.toDouble() ?? 0.0;
        return currentBalance >= amount; // Check if the balance is sufficient
      }
    } catch (e) {
      return false;
    }
    return false;
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

  void _pickPlace(BuildContext context) {
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
