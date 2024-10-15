import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Category {
  String name;
  List<String> subcategories;

  Category({required this.name, required this.subcategories});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      name: map['name'] ?? 'Unknown Category',
      subcategories: List<String>.from(map['subcategories'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subcategories': subcategories,
    };
  }
}

List<Category> defaultIncomeCategories = [
  // (Income categories list remains the same)
];

List<Category> defaultExpenseCategories = [
  // (Expense categories list remains the same)
];

class CategoriesPage extends StatefulWidget {
  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Category> incomeCategories = [];
  List<Category> expenseCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _createDefaultCategories(User user) async {
    final categoriesRef = _firestore.collection('users').doc(user.uid).collection('category');

    final incomeRef = categoriesRef.doc('income');
    final expenseRef = categoriesRef.doc('expense');

    final incomeSnapshot = await incomeRef.get();
    final expenseSnapshot = await expenseRef.get();

    if (!incomeSnapshot.exists) {
      for (var category in defaultIncomeCategories) {
        await incomeRef.collection('items').add(category.toMap());
      }
    }

    if (!expenseSnapshot.exists) {
      for (var category in defaultExpenseCategories) {
        await expenseRef.collection('items').add(category.toMap());
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _createDefaultCategories(user); // Ensure default categories are created

        final incomeSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('category')
            .doc('income')
            .collection('items')
            .get();

        final expenseSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('category')
            .doc('expense')
            .collection('items')
            .get();

        final List<Category> loadedIncomeCategories = [];
        final List<Category> loadedExpenseCategories = [];

        for (var doc in incomeSnapshot.docs) {
          final data = doc.data();
          final category = Category.fromMap(data);
          loadedIncomeCategories.add(category);
        }

        for (var doc in expenseSnapshot.docs) {
          final data = doc.data();
          final category = Category.fromMap(data);
          loadedExpenseCategories.add(category);
        }

        setState(() {
          this.incomeCategories.clear();
          this.expenseCategories.clear();
          this.incomeCategories.addAll(loadedIncomeCategories);
          this.expenseCategories.addAll(loadedExpenseCategories);
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Income and Expense
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manage Categories'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Income'),
              Tab(text: 'Expense'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCategorySection('Income', incomeCategories),
            _buildCategorySection('Expense', expenseCategories),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddCategoryDialog();
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String type, List<Category> categories) {
    return ListView(
      children: categories.map((category) {
        return Dismissible(
          key: Key(category.name),
          background: Container(
            color: Colors.red,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _deleteCategory(type, category);
          },
          child: Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ExpansionTile(
              title: Text(category.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              children: [
                ...category.subcategories.map((subcategory) {
                  return ListTile(
                    title: Text(subcategory),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _showDeleteSubcategoryDialog(category, subcategory);
                      },
                    ),
                  );
                }).toList(),
                ListTile(
                  title: TextButton(
                    onPressed: () => _showAddSubcategoryDialog(category),
                    child: Text('Add Subcategory'),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _deleteCategory(String type, Category category) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('category')
          .doc(type.toLowerCase())
          .collection('items');

      final querySnapshot = await docRef.where('name', isEqualTo: category.name).get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        if (type == 'Income') {
          incomeCategories.remove(category);
        } else {
          expenseCategories.remove(category);
        }
      });
    }
  }

  void _showAddCategoryDialog() {
    final TextEditingController _categoryController = TextEditingController();
    String _categoryType = 'Income';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Category Name'),
              ),
              DropdownButton<String>(
                value: _categoryType,
                onChanged: (String? newValue) {
                  setState(() {
                    _categoryType = newValue!;
                  });
                },
                items: ['Income', 'Expense']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                _addCategory(_categoryType, _categoryController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addCategory(String type, String categoryName) async {
    final User? user = _auth.currentUser;
    if (user != null && categoryName.isNotEmpty) {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('category')
          .doc(type.toLowerCase())
          .collection('items');

      final newCategory = Category(name: categoryName, subcategories: []);
      await docRef.add(newCategory.toMap());

      setState(() {
        if (type == 'Income') {
          incomeCategories.add(newCategory);
        } else {
          expenseCategories.add(newCategory);
        }
      });
    }
  }

  void _showAddSubcategoryDialog(Category category) {
    final TextEditingController _subcategoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Subcategory'),
          content: TextField(
            controller: _subcategoryController,
            decoration: InputDecoration(labelText: 'Subcategory Name'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                _addSubcategory(category, _subcategoryController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addSubcategory(Category category, String subcategoryName) async {
    final User? user = _auth.currentUser;
    if (user != null && subcategoryName.isNotEmpty) {
      final type = incomeCategories.contains(category) ? 'income' : 'expense';
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('category')
          .doc(type)
          .collection('items');

      final querySnapshot = await docRef.where('name', isEqualTo: category.name).get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final updatedSubcategories = List<String>.from(category.subcategories)
          ..add(subcategoryName);

        await doc.reference.update({'subcategories': updatedSubcategories});

        setState(() {
          category.subcategories.add(subcategoryName);
        });
      }
    }
  }

  void _showDeleteSubcategoryDialog(Category category, String subcategoryName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Subcategory'),
          content: Text(
              'Are you sure you want to delete the subcategory "$subcategoryName"?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                _deleteSubcategory(category, subcategoryName);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteSubcategory(Category category, String subcategoryName) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final type = incomeCategories.contains(category) ? 'income' : 'expense';
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('category')
          .doc(type)
          .collection('items');

      final querySnapshot = await docRef.where('name', isEqualTo: category.name).get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final updatedSubcategories = List<String>.from(category.subcategories)
          ..remove(subcategoryName);

        await doc.reference.update({'subcategories': updatedSubcategories});

        setState(() {
          category.subcategories.remove(subcategoryName);
        });
      }
    }
  }
}
