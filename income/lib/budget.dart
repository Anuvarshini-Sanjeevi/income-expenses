import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:income/statistics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'dart:math';
import 'package:flutter/rendering.dart';
import 'package:percent_indicator/percent_indicator.dart';

class BudgetingScreen extends StatefulWidget {
  @override
  _BudgetingScreenState createState() => _BudgetingScreenState();
}

class Budget {
  String id;
  final String category;
  double planned;
  final String frequency;
  final Timestamp timestamp;
  final Timestamp? customDate;

  Budget({
    required this.id,
    required this.category,
    required this.frequency,
    this.planned = 0.0,
    required this.timestamp,
    this.customDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'planned': planned,
      'timestamp': timestamp,
      'frequency': frequency,
      'customDate': customDate,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, String id) {
    return Budget(
      id: id,
      category: map['category'] ?? 'Unknown Category',
      planned: (map['planned'] as double?) ?? 0.0,
      timestamp: map['timestamp'] ?? Timestamp.now(),
      frequency: map['frequency'] ?? 'Weekly',
      customDate: map['customDate'] as Timestamp?, // Custom date
    );
  }

  Budget copyWith({
    String? id,
    String? category,
    double? planned,
    Timestamp? timestamp,
    String? frequency,
    Timestamp? customDate,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      planned: planned ?? this.planned,
      timestamp: timestamp ?? this.timestamp,
      frequency: frequency ?? this.frequency,
      customDate: customDate ?? this.customDate,
    );
  }
}

class _BudgetingScreenState extends State<BudgetingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Budget> budgets = [];

  String? selectedCategory;
  List<String> filteredCategories = [];
  Map<String, double> categorySpent = {};
  double totalPlannedBudget = 0.0;
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<Map<String, dynamic>> categories = [];
  DateTime now = DateTime.now(); // Current date

  @override
  void initState() {
    super.initState();
    _loadBudgets();
    _fetchTotalIncome();
    fetchAndSumTransactionsByFrequency(userId, now);
    // fetchAndSumTransactionsForCurrentMonth(userId);
  }

  Future<void> _loadCategoriesAndBudgets() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final budgetSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('budget')
            .get();

        final expenseSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('category')
            .doc('expense')
            .collection('items')
            .get();

        final Map<String, double> categoryBudgets = {};
        final List<Map<String, dynamic>> fetchedCategories = [];

        for (var doc in budgetSnapshot.docs) {
          final String categoryName = doc.get('category');
          final double spent = doc.get('spent') ?? 0.0;
          categoryBudgets[categoryName] = spent;
        }

        for (var doc in expenseSnapshot.docs) {
          final String categoryName = doc.get('name');
          final List<dynamic> subcategories =
              doc.get('subcategories') as List<dynamic>;

          fetchedCategories.add({
            'categoryName': categoryName,
            'subcategories': subcategories.cast<String>(),
          });
        }

        setState(() {
          categories.clear();
          categories.addAll(fetchedCategories);
          filteredCategories = List.from(categories);
          categorySpent = categoryBudgets;
        });
      } catch (e) {
        print("Error fetching categories and budgets: $e");
      }
    }
  }

  Future<Map<String, double>> fetchAndSumTransactionsByFrequency(
      String userId, DateTime now) async {
    // Create a map to hold the frequency for each budget category
    Map<String, String> budgetFrequencies = {};

    // Fetch budgets and their frequencies
    final budgetSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('budget')
        .get();
    for (var doc in budgetSnapshot.docs) {
      String category = doc['category'];
      String freq = doc['frequency'] ??
          'monthly'; 
      budgetFrequencies[category] = freq; 
    }
    Map<String, double> categoryTotals = {};
    final transactionSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date',
            isGreaterThan:
                DateTime(now.year, now.month, 1)) 
        .get();
    for (var transaction in transactionSnapshot.docs) {
      String category = transaction['category'];
      double amount = transaction['amount'];
      String? categoryFrequency = budgetFrequencies[category];

      if (categoryFrequency != null) {
        if (!categoryTotals.containsKey(category)) {
          categoryTotals[category] = 0;
        }
        categoryTotals[category] = categoryTotals[category]! + amount;
      }
    }

    return categoryTotals;
  }

  Future<Map<String, double>> fetchCategorySpent(String frequency) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      throw Exception('User is not logged in');
    }

    DateTime now = DateTime.now(); // Current date
    return await fetchAndSumTransactionsByFrequency(userId, now);
  }

Future<void> _loadBudgets() async {  
  try {  
   final User? user = _auth.currentUser;  
   if (user != null) {  
    final DateTime now = DateTime.now();  
    final DateTime startOfMonth = DateTime(now.year, now.month, 1);  
    final DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);  
  
    final snapshot = await _firestore  
       .collection('users')  
       .doc(user.uid)  
       .collection('budget')  
       .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)  
       .where('timestamp', isLessThanOrEqualTo: endOfMonth)  
       .get();  
  
    final List<Budget> loadedBudgets = snapshot.docs.map((doc) {  
      final data = doc.data();  
      return Budget.fromMap(data, doc.id);  
    }).toList();  
  
    // Fetch budgets with a frequency of 'Yearly'  
    final yearlyBudgets = await _firestore  
       .collection('users')  
       .doc(user.uid)  
       .collection('budget')  
       .where('frequency', isEqualTo: 'Yearly')  
       .get();  
  
    for (var doc in yearlyBudgets.docs) {  
      final data = doc.data();  
      final budget = Budget.fromMap(data, doc.id);  
      if (budget.customDate != null) {  
       final customDate = budget.customDate!.toDate();  
       if (customDate.month == now.month) {  
        loadedBudgets.add(budget);  
       }  
      }  
    }  
  
    double total = 0.0;  
    for (var budget in loadedBudgets) {  
      total += budget.planned;  
    }  
  
    setState(() {  
      budgets.clear();  
      budgets.addAll(loadedBudgets);  
      totalPlannedBudget = total;  
    });  
  
    await _loadCategories();  
   }  
  } catch (e) {  
   print("Error loading budgets: $e");  
  }  
}

  DateTime _getStartOfMonthDate() {
    final now = DateTime.now();
    return DateTime(now.year, currentMonthIndex + 1, 1);
  }

  DateTime _getEndOfMonthDate() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, currentMonthIndex + 1, 1);
    return DateTime(now.year, currentMonthIndex + 2, 0);
  }

  void _editBudget(Budget budget) {
    String? selectedCategory = budget.category;
    final TextEditingController controller =
        TextEditingController(text: budget.planned.toString());
    String? selectedFrequency = budget.frequency;

    List<String> frequencies = ['Weekly', 'Monthly', 'Yearly'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Budget'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () async {
                        final selected =
                            await _navigateToAddCategoryPage(context);
                        if (selected != null) {
                          setState(() {
                            selectedCategory = selected;
                          });
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          selectedCategory ?? 'Select a category',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter planned budget',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select frequency',
                      ),
                      items: frequencies.map((String frequency) {
                        return DropdownMenuItem<String>(
                          value: frequency,
                          child: Text(frequency),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedFrequency = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a frequency' : null,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    if (selectedCategory != null &&
                        selectedFrequency != null &&
                        controller.text.isNotEmpty) {
                      final plannedBudget =
                          double.tryParse(controller.text) ?? 0.0;

                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_auth.currentUser?.uid)
                          .collection('budget')
                          .doc(budget.id)
                          .update({
                        'category': selectedCategory!,
                        'planned': plannedBudget,
                        'frequency': selectedFrequency!,
                      }).then((value) {
                        print('Budget Updated Successfully');
                        _loadBudgets();
                        Navigator.of(context).pop();
                      }).catchError((error) {
                        print('Failed to update budget: $error');
                      });
                    } else {
                      print(
                          'Please select a category, a frequency, and enter a budget.');
                    }
                  },
                  child: Text('Update', style: TextStyle(color: Colors.blue)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  int _selectedPercentage = 0;
  GlobalKey _globalKey = GlobalKey();
  double _totalIncome = 0.0;

  Future<void> _fetchTotalIncome() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in!");
      final uid = user.uid;
      final transactionsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .where('timestamp', isGreaterThanOrEqualTo: _getStartOfMonthDate())
          .where('timestamp', isLessThanOrEqualTo: _getEndOfMonthDate())
          .get();
      double income = 0.0;
      for (var doc in transactionsSnapshot.docs) {
        final category = doc['category'];
        final amount = double.tryParse(doc['amount'].toString()) ?? 0.0;
        if (category == 'Income') {
          income += amount;
        }
      }
      setState(() {
        _totalIncome = income;
      });
    } catch (e) {
      print("Failed to fetch total income: $e");
    }
  }

  Future<Map<String, double>> fetchIncomeAndExpenses() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in!");
    }

    String uid = user.uid;

    try {
      QuerySnapshot<Map<String, dynamic>> transactionsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('transactions')
              .where('timestamp',
                  isGreaterThanOrEqualTo: _getStartOfMonthDate())
              .where('timestamp', isLessThanOrEqualTo: _getEndOfMonthDate())
              .get();

      double income = 0.0;
      double expense = 0.0;

      for (var doc in transactionsSnapshot.docs) {
        String category = doc['category'];
        double amount = double.tryParse(doc['amount'].toString()) ?? 0.0;

        if (category == 'Income') {
          income += amount;
        } else if (category == 'Expense') {
          expense += amount;
        }
      }

      return {'income': income, 'expense': expense};
    } catch (e) {
      throw Exception("Failed to fetch data: $e");
    }
  }

  Future<double> fetchTotalExpense() async {
    double totalExpense = 0.0;
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('timestamp', isGreaterThanOrEqualTo: _getStartOfMonthDate())
          .where('timestamp', isLessThanOrEqualTo: _getEndOfMonthDate())
          .get();
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('amount')) {
          double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          totalExpense += amount;
        } else {
          print("Document missing 'amount' field or null: ${doc.id}");
        }
      }
    } catch (e) {
      print("Error fetching total expense: $e");
    }
    return totalExpense;
  }

  Future<void> _loadCategories() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('category')
            .doc('expense')
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

  void _showAddCategoryDialog(BuildContext context, Budget? budget) {
    String? selectedCategory;
    final TextEditingController _controller =
        TextEditingController(text: budget?.planned.toString() ?? '');
    String? selectedFrequency;
    List<String> frequencies = ['Weekly', 'Monthly', 'Yearly'];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Budget for Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () async {
                        final selected =
                            await _navigateToAddCategoryPage(context);
                        if (selected != null) {
                          setState(() {
                            selectedCategory = selected;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 10.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: Text(
                          selectedCategory ?? 'Select a category',
                          style: TextStyle(
                            fontSize: 16,
                            color: selectedCategory == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter planned budget',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select frequency',
                      ),
                      items: frequencies.map((String frequency) {
                        return DropdownMenuItem<String>(
                          value: frequency,
                          child: Text(frequency),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedFrequency = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    if (selectedCategory != null &&
                        selectedFrequency != null &&
                        _controller.text.isNotEmpty) {
                      final plannedBudget =
                          double.tryParse(_controller.text) ?? 0.0;
                      final newBudget = Budget(
                        id: '',
                        category: selectedCategory!,
                        planned: plannedBudget,
                        timestamp: Timestamp.now(),
                        frequency: selectedFrequency!,
                      );

                      _addBudgetWithFrequency(
                          newBudget, selectedFrequency!, null);
                      Navigator.of(context).pop();
                    } else {
                      print(
                          'Please select a category, a frequency, and enter a budget.');
                    }
                  },
                  child: Text('Add', style: TextStyle(color: Colors.blue)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addBudgetWithFrequency(
      Budget budget, String frequency, DateTime? selectedDate) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .collection('budget')
        .add({
      'category': budget.category,
      'planned': budget.planned,
      'timestamp': budget.timestamp ?? Timestamp.now(),
      'frequency': frequency,
      'customDate':
          selectedDate != null ? Timestamp.fromDate(selectedDate) : null,
    }).then((value) {
      print('Budget Added Successfully');
      _loadBudgets();
    }).catchError((error) {
      print('Failed to add budget: $error');
    });
  }

  Future<String?> _navigateToAddCategoryPage(BuildContext context) async {
    final selectedCategory = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCategoryPage(categories: categories),
      ),
    );
    return selectedCategory;
  }

  bool _shouldDisplayBudget(Budget budget, DateTime now) {
    switch (budget.frequency) {
      case 'Weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        return budget.timestamp != null &&
            budget.timestamp!.toDate().isAfter(startOfWeek) &&
            budget.timestamp!.toDate().isBefore(endOfWeek);
      case 'Monthly':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return budget.timestamp != null &&
            budget.timestamp!.toDate().isAfter(startOfMonth) &&
            budget.timestamp!.toDate().isBefore(endOfMonth);
      case 'Yearly':
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
        return budget.timestamp != null &&
            budget.timestamp!.toDate().isAfter(startOfYear) &&
            budget.timestamp!.toDate().isBefore(endOfYear);
      default:
        return false;
    }
  }

  Future<void> _captureAndSharePng() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/budget_image.png';
      File(imagePath).writeAsBytesSync(pngBytes);
      await Share.shareFiles([imagePath], text: 'Check out my budget image!');
    } catch (e) {
      print(e.toString());
    }
  }

  int currentMonthIndex = DateTime.now().month - 1;
  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now(); 
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {},
        child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => bottomnav()));
                },
              ),
              title: const Center(
                child: Text(
                  'Budgeting',
                  style: TextStyle(
                      fontSize: 25,
                      color: Colors.black,
                      fontWeight: FontWeight.w800),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.drive_folder_upload,
                    size: 30,
                    color: Colors.orange,
                  ),
                  onPressed: _captureAndSharePng,
                ),
              ],
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 60,
            ),
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: RepaintBoundary(
                    key: _globalKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.navigate_before,
                                            color: Colors.black,
                                            size: 29,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              currentMonthIndex =
                                                  (currentMonthIndex - 1) % 12;
                                              if (currentMonthIndex < 0) {
                                                currentMonthIndex += 12;
                                              }
                                              _loadBudgets();
                                              _fetchTotalIncome();
                                            });
                                          },
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(25.0),
                                            color: const Color.fromARGB(
                                                255, 243, 186, 47),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                            vertical: 0.5,
                                          ),
                                          child: TextButton(
                                            onPressed: () {},
                                            child: Text(
                                              months[currentMonthIndex],
                                              style: const TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.navigate_next,
                                            color: Colors.black,
                                            size: 29,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              currentMonthIndex =
                                                  (currentMonthIndex + 1) % 12;
                                              _loadBudgets();
                                              _fetchTotalIncome();
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Total Budget',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      '\$${totalPlannedBudget.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        color:
                                            Color.fromARGB(255, 243, 186, 47),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const VerticalDivider(
                              width: 1,
                            ),
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: FutureBuilder<Map<String, double>>(
                                  future: fetchIncomeAndExpenses(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularPercentIndicator(
                                        radius: 80.0,
                                        lineWidth: 17.0,
                                        animation: true,
                                        percent: 0.0,
                                        center: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Budget Spent Percentage',
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Budget Spent',
                                            ),
                                          ],
                                        ),
                                        circularStrokeCap:
                                            CircularStrokeCap.round,
                                        progressColor:
                                            Color.fromARGB(255, 250, 71, 130),
                                        backgroundColor:
                                            Color.fromARGB(255, 228, 212, 226),
                                      );
                                    } else {
                                      double expense =
                                          snapshot.data!['expense'] ?? 0.0;
                                      double totalPlannedBudget = 100.0;
                                      double percent =
                                          (totalPlannedBudget == 0.0)
                                              ? 0.0
                                              : expense / totalPlannedBudget;
                                      percent = percent > 1.0 ? 1.0 : percent;

                                      return CircularPercentIndicator(
                                        radius: 80.0,
                                        lineWidth: 17.0,
                                        animation: true,
                                        percent: percent,
                                        center: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${(percent * 100).toStringAsFixed(2)}%',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 21.0,
                                                color: Color.fromARGB(
                                                    255, 250, 71, 130),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${(expense).toStringAsFixed(2)}',
                                            ),
                                          ],
                                        ),
                                        circularStrokeCap:
                                            CircularStrokeCap.round,
                                        progressColor:
                                            const Color.fromARGB(255, 250, 71, 130),
                                        backgroundColor:
                                            const Color.fromARGB(255, 228, 212, 226),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BudgetInfoCard(
                              title: 'Total Income',
                              amount: '\$${_totalIncome.toStringAsFixed(2)}',
                              color: Colors.green,
                            ),
                            const SizedBox(width: 10),
                            BudgetInfoCard(
                              title: 'Total Budget',
                              amount:
                                  '\$${totalPlannedBudget.toStringAsFixed(2)}',
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FutureBuilder<Map<String, double>>(
                              future: fetchIncomeAndExpenses(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return BudgetInfoCard(
                                    title: 'Budget Spent',
                                    amount: 'Loading...',
                                    color: Colors.red,
                                  );
                                } else if (snapshot.hasError) {
                                  return BudgetInfoCard(
                                    title: 'Budget Spent',
                                    amount: 'Error',
                                    color: Colors.red,
                                  );
                                } else if (!snapshot.hasData ||
                                    snapshot.data == null) {
                                  return BudgetInfoCard(
                                    title: 'Budget Spent',
                                    amount: 'No data available',
                                    color: Colors.red,
                                  );
                                } else {
                                  double expense =
                                      snapshot.data!['expense'] ?? 0.0;
                                  return BudgetInfoCard(
                                    title: 'Budget Spent',
                                    amount: '\$${expense.toStringAsFixed(2)}',
                                    color: Colors.red,
                                  );
                                }
                              },
                            ),
                            SizedBox(width: 10),
                            FutureBuilder<Map<String, double>>(
                              future: fetchIncomeAndExpenses(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return BudgetInfoCard(
                                    title: 'Remaining Amount',
                                    amount: 'Loading...',
                                    color: Colors.green,
                                  );
                                } else if (snapshot.hasError) {
                                  return BudgetInfoCard(
                                    title: 'Remaining Amount',
                                    amount: 'Error',
                                    color: Colors.green,
                                  );
                                } else if (!snapshot.hasData ||
                                    snapshot.data == null) {
                                  return BudgetInfoCard(
                                    title: 'Remaining Amount',
                                    amount: 'No data available',
                                    color: Colors.green,
                                  );
                                } else {
                                  double expense =
                                      snapshot.data!['expense'] ?? 0.0;

                                  return BudgetInfoCard(
                                    title: 'Remaining Amount',
                                    amount:
                                        '\$${(totalPlannedBudget - expense).toStringAsFixed(2)}',
                                    color: Colors.green,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  _showAddCategoryDialog(context, null),
                              child: Container(
                                padding: EdgeInsets.all(13.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 7,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.add,
                                        color: const ui.Color.fromARGB(
                                            218, 0, 0, 0)),
                                    SizedBox(width: 12),
                                    Text(
                                      'Add new budget',
                                      style: TextStyle(
                                        color: const ui.Color.fromARGB(
                                            218, 0, 0, 0),
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        Text(
                          'Budget Diversification',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (budgets.isNotEmpty) {
                                  _selectedPercentage =
                                      (_selectedPercentage + 1) %
                                          budgets.length;
                                }
                              });
                            },
                            child: CustomPaint(
                              size: Size(250, 250),
                              painter: CirclePainter(
                                percentages: [
                                  for (var budget in budgets) ...[
                                    Percentage(
                                      percent:
                                          (budget.planned / totalPlannedBudget),
                                      color: getRandomColor(),
                                      category: budget.category,
                                    ),
                                  ],
                                ],
                                selectedPercentage: _selectedPercentage,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 70),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Budget Planner',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        FutureBuilder<Map<String, double>>(
                          future:
                              fetchAndSumTransactionsByFrequency(userId, now),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }
                            // Display the data once it is fetched successfully
                            else if (snapshot.hasData) {
                              Map<String, double> categoryTotals =
                                  snapshot.data!;

                              return Column(
                                children: [
                                  for (var budget in budgets) ...[
                                    budgetItem(
                                      title: budget.category,
                                      budgetSpent: categoryTotals
                                              .containsKey(budget.category)
                                          ? '₹${categoryTotals[budget.category]!.toStringAsFixed(2)}'
                                          : '₹0.00',
                                      budgetPlanned:
                                          '₹${budget.planned.toStringAsFixed(2)}',
                                      color: getRandomColor(),
                                      onTap: () => _editBudget(budget),
                                    ),
                                  ],
                                ],
                              );
                            }
                            // Fallback in case there's no data
                            else {
                              return Center(child: Text('No data available'));
                            }
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )));
  }
}

class BudgetInfoCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  BudgetInfoCard(
      {required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 16, color: Color.fromARGB(255, 136, 135, 135)),
            ),
            SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class Percentage {
  final double percent;
  final Color color;
  final String category;

  Percentage(
      {required this.percent, required this.color, required this.category});
}

class CirclePainter extends CustomPainter {
  final List<Percentage> percentages;
  final int selectedPercentage;

  CirclePainter({required this.percentages, required this.selectedPercentage});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    double startAngle = 0;
    for (int i = 0; i < percentages.length; i++) {
      paint.color = percentages[i].color;
      paint.strokeWidth = i == selectedPercentage ? 10 : 3;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width,
          height: size.height,
        ),
        startAngle,
        percentages[i].percent * 2 * pi,
        false,
        paint,
      );
      startAngle += percentages[i].percent * 2 * pi;
    }

    // Draw the percentage and category text in the center
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final percentageText =
        '${(percentages[selectedPercentage].percent * 100).toStringAsFixed(1)}%';
    final categoryText = percentages[selectedPercentage].category;

    textPainter.text = TextSpan(
      children: [
        TextSpan(
          text: percentageText,
          style: TextStyle(
              fontSize: 43, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        TextSpan(
          text: '\n$categoryText',
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ],
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2,
          size.height / 2 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => false;
}

Widget budgetItem({
  required String title,
  required String budgetSpent,
  required String budgetPlanned,
  required Color color,
  required VoidCallback onTap,
}) {
  double spent = double.parse(budgetSpent.replaceAll(RegExp(r'[^\d\.]'), ''));
  double planned =
      double.parse(budgetPlanned.replaceAll(RegExp(r'[^\d\.]'), ''));
  double remaining = planned - spent;

  return Container(
    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: Icon(Icons.add, color: Colors.green),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Spent',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  budgetSpent,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Planned',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  budgetPlanned,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remaining',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '₹ ${remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          borderRadius: BorderRadius.circular(10),
          value: spent / planned,
          color: color,
          backgroundColor: Colors.grey[300],
          minHeight: 8.5,
        ),
        SizedBox(height: 16),
      ],
    ),
  );
}

Color getRandomColor() {
  Random random = Random();
  return Color.fromARGB(
    255, // Opacity (you can change this if you want some transparency)
    random.nextInt(256), // Red
    random.nextInt(256), // Green
    random.nextInt(256), // Blue
  );
}

class AddCategoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> categories;

  AddCategoryPage({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Category'),
      ),
      body: ListView.builder(
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
                  Navigator.pop(context, sub); // Return selected subcategory
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
