import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Budget {
  String id;
  final String category;
  double planned;
  Timestamp? timestamp; 
  final String frequency;
  Timestamp? customDate; 

  Budget(
    {
    required this.id,
    required this.category,
    this.planned = 0.0,
    this.timestamp,
    required this.frequency,
    this.customDate,
  }
  );

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'planned': planned,
      'timestamp': timestamp, 
      'frequency': frequency,
      'customDate': customDate, // Custom date
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, String id) {
    return Budget(
      id: id,
      category: map['category'] ?? 'Unknown Category',
      planned: (map['planned'] as double?) ?? 0.0,
      timestamp: map['timestamp'] as Timestamp?,
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

class BudgetingPage extends StatefulWidget {
  @override
  _BudgetingPageState createState() => _BudgetingPageState();
}

class _BudgetingPageState extends State<BudgetingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Budget> budgets = [];
  List<Map<String, dynamic>> categories = [];

  String? selectedCategory; // Define selectedCategory
  List<String> subcategories = [];
  List<String> filteredCategories = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkAndClearBudgetsForNewMonth();
    _loadBudgets();
    _loadCategories();
  }

  Future<void> _checkAndClearBudgetsForNewMonth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastMonth = prefs.getInt('lastMonth');
    int currentMonth = DateTime.now().month;

    if (lastMonth == null || lastMonth != currentMonth) {
      setState(() {
        budgets.clear(); // Clear local budgets
      });
      prefs.setInt('lastMonth', currentMonth); // Update stored month
    }
  }

  Future<void> _loadBudgets() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget')
          .get();

      final List<Budget> loadedBudgets = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final budget = Budget.fromMap(data, doc.id);

            // Print out budget details for debugging
            print(
                "Fetched Budget: ${budget.category}, ${budget.planned}, ${budget.frequency}, ${budget.customDate}");

            // Determine if the budget should be displayed based on frequency
            if (_shouldDisplayBudget(budget, now)) {
              print("Budget displayed: ${budget.category}");
              return budget;
            } else {
              print("Budget not displayed: ${budget.category}");
              return null;
            }
          })
          .whereType<Budget>()
          .toList(); // Remove null values

      setState(() {
        budgets.clear();
        budgets.addAll(loadedBudgets);
        print("Budgets Loaded: $budgets"); // Debugging print statement
      });
    }
  }

  bool _shouldDisplayBudget(Budget budget, DateTime now) {
    switch (budget.frequency) {
      case 'Weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        // Check if the budget's timestamp falls within the current week
        return budget.timestamp != null &&
            budget.timestamp!.toDate().isAfter(startOfWeek) &&
            budget.timestamp!.toDate().isBefore(endOfWeek);
      case 'Monthly':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        // Check if the budget's timestamp falls within the current month
        return budget.timestamp != null &&
            budget.timestamp!.toDate().isAfter(startOfMonth) &&
            budget.timestamp!.toDate().isBefore(endOfMonth);
      case 'Yearly':
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
        // Check if the budget's timestamp falls within the current year
        return budget.timestamp != null &&
            budget.timestamp!.toDate().isAfter(startOfYear) &&
            budget.timestamp!.toDate().isBefore(endOfYear);
      default:
        return false;
    }
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

  Future<void> _showCategorySelectionDialog(BuildContext context) async {
    String? selectedCategory;
    List<String> categories = []; // Populate this list with your categories

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select a Category'),
              content: Container(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (BuildContext context, int index) {
                    String category = categories[index];
                    return RadioListTile<String>(
                      title: Text(category),
                      value: category,
                      groupValue: selectedCategory,
                      onChanged: (String? value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // Close dialog without selection
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(selectedCategory); // Return selected category
                  },
                  child: Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
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

  void _editBudget(Budget budget) {
    String? selectedCategory = budget.category;
    final TextEditingController _controller =
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
      'customDate': selectedDate != null
          ? Timestamp.fromDate(selectedDate)
          : null, // Add customDate field
    }).then((value) {
      print('Budget Added Successfully');
      _loadBudgets(); // Reload budgets to include the new one
    }).catchError((error) {
      print('Failed to add budget: $error');
    });
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
                        id: '', // Firestore will generate the ID
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

  void _deleteBudget(int index) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final budget = budgets[index];
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget')
          .doc(budget.id)
          .delete();
      setState(() {
        budgets.removeAt(index);
      });
      print('Budget deleted successfully');
    }
  }

  Future<void> _confirmDelete(int index) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Budget'),
          content: Text('Are you sure you want to delete this budget?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      _deleteBudget(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budgeting'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 30, color: Colors.black),
            onPressed: () => _showAddCategoryDialog(context, null),
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage your monthly budgets',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: budgets.isEmpty
                      ? Center(
                          child: Text(
                            'No budgets added yet.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: budgets.length,
                          itemBuilder: (context, index) {
                            final budget = budgets[index];
                            print(
                                "Rendering Budget: ${budget.category}, ${budget.planned}, ${budget.frequency}, ${budget.customDate}"); // Debugging print statement

                            return Dismissible(
                              key: Key(budget.id),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.delete, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                await _confirmDelete(index);
                                // Return false to prevent automatic dismissal
                                return false;
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(vertical: 8.0),
                                elevation: 4.0,
                                child: ListTile(
                                  title: Text(budget.category),
                                  subtitle: Text(
                                    'Planned: \$${budget.planned.toStringAsFixed(2)} - Frequency: ${budget.frequency}' +
                                        (budget.customDate != null
                                            ? ' - Custom Date: ${DateFormat('yyyy-MM-dd').format(budget.customDate!.toDate())}'
                                            : ''),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: const Color.fromARGB(
                                                255, 69, 69, 69)),
                                        onPressed: () => _editBudget(budget),
                                        tooltip: 'Edit Budget',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
