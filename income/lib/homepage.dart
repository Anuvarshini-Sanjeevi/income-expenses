import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:income/setting.dart';
import 'package:income/transaction.dart';
import 'account.dart';
import 'budget.dart';
import 'calculator.dart';
import 'profile.dart';
import 'profileedit.dart';
import 'statistics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
Future<Map<String, double>> fetchIncomeAndExpenses() async {
  try {
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    QuerySnapshot incomeSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('category', isEqualTo: 'Income')
        .get();
    QuerySnapshot expenseSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('category', isEqualTo: 'Expense')
        .get();

    for (var doc in incomeSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('amount')) {
        totalIncome += double.parse(data['amount'].toString());
      }
    }

    for (var doc in expenseSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('amount')) {
        totalExpense += double.parse(data['amount'].toString());
      }
    }

    return {'income': totalIncome, 'expense': totalExpense};
  } catch (e) {
    print('Error fetching data: $e');
    throw e;
  }
}

class Homepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.gupterTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isFabPressed = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      userId = user?.uid;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isFabPressed = false;
    });
  }

  void _onFabPressed() {
    setState(() {
      _isFabPressed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {},
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: userId == null
                  ? CircularProgressIndicator()
                  : _isFabPressed
                      ? _buildFabContent()
                      : _getSelectedWidget(_selectedIndex),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                label: 'Statistics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Budget',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
          ),
          floatingActionButton: Opacity(
            opacity: 1,
            child: FloatingActionButton(
              onPressed: _onFabPressed,
              child: Icon(Icons.add, color: Colors.white, size: 45),
              backgroundColor: const Color.fromARGB(243, 255, 191, 0),
              shape: CircleBorder(),
              elevation: 0,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        ));
  }

  Widget _getSelectedWidget(int index) {
    switch (index) {
      case 0:
        return _buildHomeContent(context, userId!);
      case 1:
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Statistics(
            type: 'example',
            recordConfirmation: 'example',
            category: 'example',
            currency: 'example',
            paymentType: 'example',
            status: 'example',
            includeTransfers: true,
            includeDebts: false,
          ),
        );
      case 2:
        return BudgetingScreen();
      case 3:
        return ProfilePage();
      default:
        return _buildHomeContent(context, userId!);
    }
  }

  Widget _buildHomeContent(BuildContext context, String userId) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserGreeting(userId: userId),
          const SizedBox(height: 5),
          ListOfAccountsSection(),
          SizedBox(height: 10),
          LineChartSample2(),
          SizedBox(height: 10),
          TopSpending(),
          RecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildFabContent() {
    return AddIncomeExpense();
  }
}

class UserGreeting extends StatelessWidget {
  final String userId;

  UserGreeting({required this.userId});
  Future<Map<String, dynamic>> fetchUserData() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    throw Exception('User is not logged in');
  }

  final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

  if (!userDoc.exists) {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'name': 'User',
      'email': FirebaseAuth.instance.currentUser!.email,
      'profileImageUrl': 'https://static.vecteezy.com/system/resources/thumbnails/002/318/271/small_2x/user-profile-icon-free-vector.jpg',
    });

    final updatedDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return updatedDoc.data() as Map<String, dynamic>;
  }

  return userDoc.data() as Map<String, dynamic>;
}

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error fetching data: ${snapshot.error}'));
        }
        final userData = snapshot.data ?? {};
        final name = userData['name'] ?? 'User';
        final email = userData['email'] ?? 'email@example.com';
        final profileImageUrl = userData['profileImageUrl'] ??
            'https://static.vecteezy.com/system/resources/thumbnails/002/318/271/small_2x/user-profile-icon-free-vector.jpg';

        return SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ProfileEditPage(userId: userId)),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(profileImageUrl),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hello $name!',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        getGreeting(),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200, width: 3),
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.settings, color: Colors.blue, size: 30),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsPage(
                                  userId: userId,
                                )),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScrollablePage extends StatelessWidget {
  final String type;
  final String recordConfirmation;
  final String category;
  final String currency;
  final String paymentType;
  final String status;
  final bool includeTransfers;
  final bool includeDebts;

  ScrollablePage({
    required this.type,
    required this.recordConfirmation,
    required this.category,
    required this.currency,
    required this.paymentType,
    required this.status,
    required this.includeTransfers,
    required this.includeDebts,
  });

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class ListOfAccountsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Using MediaQuery for dynamic padding and margin
    double containerMarginTop = MediaQuery.of(context).size.height * 0.02; // 2% of the screen height
    double containerPadding = MediaQuery.of(context).size.width * 0.025; // 2.5% of the screen width

    return Container(
      margin: EdgeInsets.only(top: containerMarginTop),
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'List of accounts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _fetchAccountsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error fetching accounts'));
              }

              List<Widget> accountCards = [];
              double totalBalance = 0;

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                accountCards = snapshot.data!.docs.map<Widget>((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  int colorInt;
                  if (data['color'] is String) {
                    colorInt =
                        int.tryParse(data['color'] as String, radix: 16) ?? 0xFF0000FF;
                  } else {
                    colorInt = (data['color'] as int? ?? 0xFF0000FF);
                  }
                  Color color = Color(colorInt);

                  String accountName = data['accountName'] ?? '';

                  double initialValue = 0.0;
                  if (data['initialValue'] is String) {
                    initialValue =
                        double.tryParse(data['initialValue'] as String) ?? 0.0;
                  } else {
                    initialValue =
                        (data['initialValue'] as num?)?.toDouble() ?? 0.0;
                  }
                  String initialValueFormatted = '₹${initialValue.toStringAsFixed(2)}';

                  totalBalance += initialValue;

                  return AccountCard(
                    color: color,
                    label: accountName,
                    amount: initialValueFormatted,
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.01, // 1% height
                      horizontal: MediaQuery.of(context).size.width * 0.02,  // 2% width
                    ),
                    margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.01), // 1% width
                  );
                }).toList();
              }

              accountCards.add(AddAccountButton());

              bool hasMoreCards = accountCards.length > 5;
              List<Widget> displayedCards = accountCards.take(5).toList();

              if (hasMoreCards) {
                displayedCards.add(
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child: Container(
                                color: Colors.white,
                                child: SingleChildScrollView(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight: MediaQuery.of(context).size.height * 0.8, // 80% height
                                    ),
                                    child: AllAccountsPage(accountCards: accountCards),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02), // 2% width
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue, width: 1),
                      ),
                      child: Text(
                        'Show More',
                        style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (!displayedCards.any((widget) => widget is AddAccountButton)) {
                displayedCards.add(AddAccountButton());
              }

              return Column(
                children: [
                  GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: displayedCards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: MediaQuery.of(context).size.width * 0.01, // 1% width
                      mainAxisSpacing: MediaQuery.of(context).size.height * 0.01, // 1% height
                      childAspectRatio: 1 / 0.5,
                    ),
                    itemBuilder: (context, index) {
                      return displayedCards[index];
                    },
                  ),
                  TotalBalanceCard(totalBalance: totalBalance),
                ],
              );
            },
          ),
        ],
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
}


class AddAccountButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double buttonWidth = MediaQuery.of(context).size.width * 0.4; 
    double textSizeAdd = MediaQuery.of(context).size.width * 0.02; // Dynamic text size for "ADD"
    double textSizeAccount = MediaQuery.of(context).size.width * 0.018; // Dynamic text size for "ACCOUNT"

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewAccountScreen()),
        );
      },
      child: Container(
        width: buttonWidth,
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.only(left: 4, top: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADD',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: textSizeAdd, // Applying MediaQuery to text size
                    ),
                  ),
                  Text(
                    'ACCOUNT',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: textSizeAccount, // Applying MediaQuery to text size
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
              padding: EdgeInsets.all(3),
              child: Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}


class AccountCard extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;
  final EdgeInsets padding;
  final EdgeInsets margin;

  AccountCard({
    required this.color,
    required this.label,
    required this.amount,
    this.padding = const EdgeInsets.all(12),
    this.margin = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width * 0.3;
    double cardHeight = MediaQuery.of(context).size.height * 0.15;
    double fontSizeLabel = MediaQuery.of(context).size.width * 0.035; // Scaled based on screen width
    double fontSizeAmount = MediaQuery.of(context).size.width * 0.04; // Slightly larger font for the amount

    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: fontSizeLabel,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSizeAmount,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class AllAccountsPage extends StatelessWidget {
  final List<Widget> accountCards;

  AllAccountsPage({required this.accountCards});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Accounts'),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        itemCount: accountCards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 3.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 1 / 0.4,
        ),
        itemBuilder: (context, index) {
          return accountCards[index];
        },
      ),
    );
  }
}

class TotalBalanceCard extends StatelessWidget {
  final double? totalBalance;

  TotalBalanceCard({this.totalBalance});

  Future<Map<String, double>> fetchIncomeAndExpenses() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in!");
    }

    String uid = user.uid;

    try {
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(days: 1));

      QuerySnapshot<Map<String, dynamic>> transactionsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('transactions')
              .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
              .where('timestamp', isLessThanOrEqualTo: endOfMonth)
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

  Future<double> calculateTotalBalance() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in!");
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .get();

      double balanceSum = 0.0;
      for (var doc in querySnapshot.docs) {
        final dynamic initialValue = doc.data()['initialValue'];
        double currentBalance = 0.0;

        if (initialValue is num) {
          currentBalance = initialValue.toDouble();
        } else if (initialValue is String) {
          currentBalance = double.tryParse(initialValue) ?? 0.0;
        }

        balanceSum += currentBalance;
      }

      return balanceSum;
    } catch (e) {
      throw Exception("Failed to calculate total balance: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: calculateTotalBalance(),
      builder: (context, totalBalanceSnapshot) {
        if (totalBalanceSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (totalBalanceSnapshot.hasError) {
          return Center(child: Text('Error: ${totalBalanceSnapshot.error}'));
        } else if (!totalBalanceSnapshot.hasData ||
            totalBalanceSnapshot.data == null) {
          return const Center(child: Text('No data available'));
        } else {
          return FutureBuilder<Map<String, double>>(
            future: fetchIncomeAndExpenses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('No data available'));
              } else {
                double income = snapshot.data!['income']!;
                double expense = snapshot.data!['expense']!;
                double balance = income - expense;

                double total = income + expense;
                double expenseProportion = total != 0 ? expense / total : 0.0;

                return Container(
                  margin: const EdgeInsets.only(top: 25),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(243, 255, 191, 0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Text(
                          'Total Balance',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '₹${totalBalanceSnapshot.data!.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Budgeted Monthly Expenses",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Stack(
                          children: [
                            Container(
                              height: 25,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(width: 2, color: Colors.white),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(34)),
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(34)),
                                child: LinearProgressIndicator(
                                  value: income != 0 ? expense / income : 0.0,
                                  minHeight: 36,
                                  backgroundColor: Colors.white,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.transparent),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                height: 30,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(34)),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor:
                                        income != 0 ? expense / income : 0.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Color.fromARGB(255, 165, 163, 163),
                                            Colors.black,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(34),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "₹${expense.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const Spacer(),
                              Text(
                                '₹${income.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Wrap(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SizedBox(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.335,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            children: [
                                              Container(
                                                width: 30,
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Color.fromARGB(
                                                      79, 182, 184, 236),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const IconTheme(
                                                  data: IconThemeData(
                                                    size: 24,
                                                  ),
                                                  child: Icon(
                                                      Icons.arrow_upward,
                                                      color:
                                                          Colors.greenAccent),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 5),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Income',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13),
                                              ),
                                              Text(
                                                '₹${income.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 85, 201, 91),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SizedBox(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.335,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            children: [
                                              Container(
                                                width: 30,
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Color.fromARGB(
                                                      79, 182, 184, 236),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const IconTheme(
                                                  data: IconThemeData(
                                                    size: 24,
                                                  ),
                                                  child: Icon(
                                                      Icons.arrow_downward,
                                                      color: Colors.redAccent),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Text(
                                                'Expense',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13),
                                              ),
                                              Text(
                                                '₹${expense.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 245, 117, 101),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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
                );
              }
            },
          );
        }
      },
    );
  }
}

class LineChartSample2 extends StatefulWidget {
  @override
  _LineChartSample2State createState() => _LineChartSample2State();
}

class _LineChartSample2State extends State<LineChartSample2> {
  List<Color> gradientColors = [
    const Color.fromARGB(255, 246, 218, 133),
    Colors.amber,
  ];

  int daysFilter = 30;

  @override
  Widget build(BuildContext context) {
   
     
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(243, 255, 191, 0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: DropdownButton<int>(
              value: daysFilter,
              dropdownColor: const Color.fromARGB(255, 255, 255, 255),
              items: const [
                DropdownMenuItem(
                    value: 7,
                    child: Text('Last 7 days',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold))),
                DropdownMenuItem(
                    value: 30,
                    child: Text('Last 30 days',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold))),
                DropdownMenuItem(
                    value: 90,
                    child: Text('Last 90 days',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold))),
              ],
              onChanged: (value) {
                setState(() {
                  daysFilter = value!;
                });
              },
            ),
          ),
         SingleChildScrollView(
  scrollDirection: Axis.vertical, 
  child: Column( 
    children: [
      SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 300,
        child: FutureBuilder<LineChartData>(
          future: fetchChartData(daysFilter),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error loading data: ${snapshot.error}'),
              );
            } else if (snapshot.hasData) {
              return AnimatedLineChart(snapshot.data!);
            } else {
              return const Center(child: Text('No data available'));
            }
          },
        ),
      ),
    ],
  ),
)

        ],
      );
    
  }

  Future<LineChartData> fetchChartData(int days) async {
    try {
      final now = DateTime.now();
      final startDate =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: days));

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }
      final String userId = currentUser.uid;

      final transactionsSnapshots = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .get();

      Map<DateTime, double> dailyTotals = Map.fromIterable(
        List.generate(
            days + 1, (index) => startDate.add(Duration(days: index))),
        key: (date) => date,
        value: (date) => 0.0,
      );

      for (var doc in transactionsSnapshots.docs) {
        var data = doc.data();
        if (data.containsKey('timestamp') &&
            data['timestamp'] is Timestamp &&
            data.containsKey('amount') &&
            data.containsKey('category')) {
          var timestamp = (data['timestamp'] as Timestamp).toDate();
          var amount = data['amount'];

          if (amount is String) {
            amount = double.parse(amount);
          }

          if (amount is num) {
            double value = amount.toDouble();
            if (data['category'] == 'Expense') {
              value = -value;
            }

            DateTime dayKey =
                DateTime(timestamp.year, timestamp.month, timestamp.day);
            if (dailyTotals.containsKey(dayKey)) {
              dailyTotals[dayKey] = dailyTotals[dayKey]! + value;
            }
          }
        }
      }

      List<FlSpot> spots = dailyTotals.entries.map((entry) {
        double xValue = entry.key.difference(startDate).inDays.toDouble();
        return FlSpot(xValue, entry.value);
      }).toList();

      spots.sort((a, b) => a.x.compareTo(b.x));
      double minX = spots.first.x;
      double maxX = spots.last.x;
      double minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

      return LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(colors: gradientColors),
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: gradientColors
                    .map((color) => color.withOpacity(0.3))
                    .toList(),
              ),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipBorder: BorderSide.none,
          ),
          touchSpotThreshold: 10,
          handleBuiltInTouches: true,
        ),
      );
    } catch (e) {
      throw Exception('Failed to fetch chart data: $e');
    }
  }
}

class AnimatedLineChart extends StatefulWidget {
  final LineChartData data;
  const AnimatedLineChart(this.data, {Key? key}) : super(key: key);

  @override
  _AnimatedLineChartState createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            minX: widget.data.minX,
            maxX: widget.data.maxX,
            minY: widget.data.minY,
            maxY: widget.data.maxY,
            lineBarsData: [
              LineChartBarData(
                spots: widget.data.lineBarsData[0].spots,
                isCurved: true,
                gradient: widget.data.lineBarsData[0].gradient,
                barWidth: 2,
                isStrokeCapRound: true,
                belowBarData: widget.data.lineBarsData[0].belowBarData,
                dotData: widget.data.lineBarsData[0].dotData,
                isStepLineChart: widget.data.lineBarsData[0].isStepLineChart,
                showingIndicators: [],
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipPadding: const EdgeInsets.all(8),
                tooltipBorder: BorderSide.none,
              ),
              touchSpotThreshold: 10,
              handleBuiltInTouches: true,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class TopSpending extends StatefulWidget {
  @override
  _TopSpendingState createState() => _TopSpendingState();
}

class _TopSpendingState extends State<TopSpending> {
  String _selectedPeriod = 'Last 30 days';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: const Text(
                'Top Spending’s',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(243, 255, 191, 0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        icon: const Icon(
                          Icons.keyboard_double_arrow_down,
                          size: 20,
                          color: Colors.black,
                        ),
                        iconSize: 24,
                        elevation: 16,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        underline: Container(
                          height: 0,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPeriod = newValue!;
                          });
                        },
                        items: <String>[
                          'Last 7 days',
                          'Last 30 days',
                          'Last 90 days'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: _getUserTransactions(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              final data = snapshot.requireData;
              final groupedTransactions = _groupAndSumTransactions(data.docs);
              final filteredTransactions =
                  _filterGroupedTransactions(groupedTransactions);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filteredTransactions.map((entry) {
                    final category = entry['label'] ?? 'Unknown';
                    final amount = entry['amount'] ?? 0.0;
                    IconData icon;
                    switch (category) {
                      case 'Rent/Mortgage':
                        icon = Icons.home;
                        break;
                      case 'Property Taxes':
                        icon = Icons.account_balance;
                        break;
                      case 'Home Insurance':
                        icon = Icons.shield;
                        break;
                      case 'Maintenance/Repairs':
                        icon = Icons.build;
                        break;
                      case 'Electricity':
                        icon = Icons.electric_bolt;
                        break;
                      case 'Water':
                        icon = Icons.water_drop;
                        break;
                      case 'Gas':
                        icon = Icons.local_gas_station;
                        break;
                      case 'Internet':
                        icon = Icons.wifi;
                        break;
                      case 'Phone':
                        icon = Icons.phone;
                        break;
                      case 'Car Payment':
                        icon = Icons.directions_car;
                        break;
                      case 'Gas/Fuel':
                        icon = Icons.local_gas_station;
                        break;
                      case 'Public Transportation':
                        icon = Icons.directions_bus;
                        break;
                      case 'Parking Fees':
                        icon = Icons.local_parking;
                        break;
                      case 'Groceries':
                        icon = Icons.local_grocery_store;
                        break;
                      case 'Dining Out':
                        icon = Icons.restaurant;
                        break;
                      case 'Coffee/Snacks':
                        icon = Icons.local_cafe;
                        break;
                      case 'Health Insurance':
                        icon = Icons.health_and_safety;
                        break;
                      case 'Auto Insurance':
                        icon = Icons.directions_car;
                        break;
                      case 'Home/Renters Insurance':
                        icon = Icons.home;
                        break;
                      case 'Doctor Visits':
                        icon = Icons.local_hospital;
                        break;
                      case 'Medications':
                        icon = Icons.medical_services;
                        break;
                      case 'Credit Card Payments':
                        icon = Icons.credit_card;
                        break;
                      case 'Student Loans':
                        icon = Icons.school;
                        break;
                      case 'Emergency Fund':
                        icon = Icons.savings;
                        break;
                      case 'Movies':
                        icon = Icons.movie;
                        break;
                      case 'Concerts/Shows':
                        icon = Icons.music_note;
                        break;
                      case 'Subscriptions':
                        icon = Icons.subscriptions;
                        break;
                      case 'Haircuts/Salon':
                        icon = Icons.cut;
                        break;
                      case 'Clothing/Shoes':
                        icon = Icons.shopping_bag;
                        break;
                      case 'Tuition':
                        icon = Icons.school;
                        break;
                      case 'Books/Supplies':
                        icon = Icons.book;
                        break;
                      case 'Gifts Given':
                        icon = Icons.card_giftcard;
                        break;
                      case 'Charitable Donations':
                        icon = Icons.volunteer_activism;
                        break;
                      case 'Flights':
                        icon = Icons.flight;
                        break;
                      case 'Accommodation':
                        icon = Icons.hotel;
                        break;
                      case 'Pet Expenses':
                        icon = Icons.pets;
                        break;
                      case 'Office Supplies':
                        icon = Icons.business_center;
                        break;
                      default:
                        icon = Icons.shopping_cart;
                        break;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TopSpendingItem(
                        icon: icon,
                        title: category,
                        amount: '₹$amount',
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getUserTransactions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('category', isEqualTo: 'Expense')
          .snapshots();
    } else {
      return const Stream.empty();
    }
  }

  List<Map<String, dynamic>> _groupAndSumTransactions(
      List<QueryDocumentSnapshot> transactions) {
    final Map<String, Map<String, dynamic>> groupedData = {};

    for (var doc in transactions) {
      final data = doc.data() as Map<String, dynamic>;
      final label = data['label'] ?? 'Unknown';
      final amount = double.tryParse(data['amount'].toString()) ?? 0.0;

      if (groupedData.containsKey(label)) {
        groupedData[label]!['amount'] += amount;
      } else {
        groupedData[label] = {
          'category': data['category'] ?? 'Unknown',
          'label': label,
          'amount': amount,
        };
      }
    }

    return groupedData.values.toList();
  }

  List<Map<String, dynamic>> _filterGroupedTransactions(
      List<Map<String, dynamic>> groupedTransactions) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'Last 7 days':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'Last 90 days':
        startDate = now.subtract(Duration(days: 90));
        break;
      case 'Last 30 days':
      default:
        startDate = now.subtract(Duration(days: 30));
    }

    final filteredTransactions = groupedTransactions.where((entry) {
      final timestamp = entry['timestamp'] != null
          ? (entry['timestamp'] as Timestamp).toDate()
          : DateTime.now();
      return timestamp.isAfter(startDate);
    }).toList();

    filteredTransactions.sort((a, b) {
      final amountA = _parseAmount(a['amount']);
      final amountB = _parseAmount(b['amount']);
      return amountB.compareTo(amountA);
    });

    return filteredTransactions.take(5).toList();
  }

  double _parseAmount(dynamic amount) {
    if (amount is double) {
      return amount;
    } else if (amount is int) {
      return amount.toDouble();
    } else if (amount is String) {
      return double.tryParse(amount) ?? 0.0;
    } else {
      return 0.0;
    }
  }
}

class TopSpendingItem extends StatelessWidget {
  const TopSpendingItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.amount,
    this.width = 100,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String amount;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(243, 255, 191, 0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 50,
            color: Colors.black,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              amount,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentTransactions extends StatefulWidget {
  const RecentTransactions({Key? key}) : super(key: key);

  @override
  _RecentTransactionsState createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<RecentTransactions> {
  bool _viewAll = false;

  void _toggleViewAll() {
    if (_viewAll) {
      setState(() {
        _viewAll = !_viewAll;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ShowMore()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('User not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data?.docs ?? [];
        transactions.sort((a, b) {
          final dateA = (a.data() as Map<String, dynamic>)['date'];
          final dateB = (b.data() as Map<String, dynamic>)['date'];
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          DateTime parsedDateA;
          DateTime parsedDateB;
          if (dateA is Timestamp) {
            parsedDateA = dateA.toDate();
          } else if (dateA is String) {
            parsedDateA = DateTime.parse(dateA);
          } else {
            return 1; 
          }

          if (dateB is Timestamp) {
            parsedDateB = dateB.toDate();
          } else if (dateB is String) {
            parsedDateB = DateTime.parse(dateB);
          } else {
            return -1; 
          }

          return parsedDateB.compareTo(parsedDateA);
        });

        final displayedTransactions =
            _viewAll ? transactions : transactions.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 16.0, right: 16.0, bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: _toggleViewAll,
                    child: Container(
                      margin: EdgeInsets.only(left: 0),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(243, 255, 191, 0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _viewAll ? '   View less  ' : '   View all  ',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            _viewAll
                                ? Icons.keyboard_double_arrow_up
                                : Icons.keyboard_double_arrow_down,
                            size: 20,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'LAST 30 DAYS',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ...displayedTransactions.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final category = data['category'] ?? 'Unknown';
              final date = data['date'] != null
                  ? getFormattedDate(data['date'])
                  : 'Unknown Date';

              final amount = data['amount'] ?? 0.0;
              final isIncome = category == 'Income';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TransactionItem(
                  icon: _getIconForCategory(category),
                  title: data['label'] ?? 'No Label',
                  subtitle: data['place'] ?? 'No Place',
                  amount: (isIncome ? '+₹' : '-₹') + amount.toString(),
                  date: date,
                  amountColor: isIncome
                      ? Colors.green
                      : Colors.red, 
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Income':
        return Icons.attach_money;
      case 'Expense':
        return Icons.money_off;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}-${date.month}-${date.year}';
    }
  }

  String getFormattedDate(dynamic dateField) {
    if (dateField is Timestamp) {
      return _formatDate(dateField.toDate());
    } else if (dateField is String) {
      final DateTime parsedDate = DateTime.parse(dateField);
      return _formatDate(parsedDate);
    } else {
      return 'Unknown Date'; 
    }
  }
}

class ShowMore extends StatefulWidget {
  const ShowMore({Key? key}) : super(key: key);

  @override
  _ShowMoreState createState() => _ShowMoreState();
}

class _ShowMoreState extends State<ShowMore> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('User not logged in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('All Transactions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var transactions = snapshot.data?.docs ?? [];
          if (transactions.isEmpty) {
            return Center(child: Text('No transactions available'));
          }

          transactions.sort((a, b) {
            final dateA = (a.data() as Map<String, dynamic>)['date'];
            final dateB = (b.data() as Map<String, dynamic>)['date'];

            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;

            DateTime parsedDateA;
            DateTime parsedDateB;

            // Convert both dates to DateTime
            parsedDateA = _convertToDate(dateA);
            parsedDateB = _convertToDate(dateB);

            return parsedDateB.compareTo(parsedDateA); // Sort descending
          });

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final data = transaction.data() as Map<String, dynamic>;

              final category = data['category'] ?? 'Unknown';
              final date = data['date'] != null
                  ? _formatDate(data['date'])
                  : 'Unknown Date';
              final amount = data['amount'] ?? 0.0;
              final isIncome = category == 'Income';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TransactionItem(
                  icon: _getIconForCategory(category),
                  title: data['label'] ?? 'No Label',
                  subtitle: data['place'] ?? 'No Place',
                  amount: (isIncome ? '+₹' : '-₹') + amount.toString(),
                  date: date,
                  amountColor: isIncome ? Colors.green : Colors.red,
                  onTap: () => _editTransactionAmount(
                      transaction),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Income':
        return Icons.attach_money;
      case 'Expense':
        return Icons.money_off;
      default:
        return Icons.help; // Default icon for unknown categories
    }
  }

  DateTime _convertToDate(dynamic dateField) {
    if (dateField is Timestamp) {
      return dateField.toDate();
    } else if (dateField is String) {
      try {
        return DateTime.parse(dateField);
      } catch (e) {
        return DateTime.now(); // Fallback date
      }
    } else {
      return DateTime.now(); // Fallback date
    }
  }

  String _formatDate(dynamic dateField) {
    DateTime date = _convertToDate(dateField);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    if (date.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (date.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return '${date.day}-${date.month}-${date.year}';
    }
  }

  // void _editTransactionAmount(DocumentSnapshot transaction) {
  //   final data = transaction.data() as Map<String, dynamic>;
  //   final TextEditingController _amountController =
  //       TextEditingController(text: data['amount'].toString());

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Edit Transaction Amount'),
  //         content: TextField(
  //           controller: _amountController,
  //           keyboardType: TextInputType.number,
  //           decoration: InputDecoration(
  //             labelText: 'Amount',
  //             hintText: 'Enter new amount',
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Close the dialog
  //             },
  //             child: Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //               final newAmount =
  //                   double.tryParse(_amountController.text) ?? data['amount'];
  //               await FirebaseFirestore.instance
  //                   .collection('users')
  //                   .doc(FirebaseAuth.instance.currentUser!.uid)
  //                   .collection('transactions')
  //                   .doc(transaction.id)
  //                   .update({
  //                 'amount': newAmount
  //               }); // Update the amount in Firestore
  //               Navigator.of(context).pop(); // Close the dialog
  //             },
  //             child: Text('Save'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  void _editTransactionAmount(DocumentSnapshot transaction) {
  final data = transaction.data() as Map<String, dynamic>;
  
  // Extract data needed for PlusPageedit
  final selectedCategory = data['category'] ?? 'Expense'; // Default to 'Expense'
  final amount = data['amount']?.toString() ?? '0.0';
  final category = data['label'] ?? 'No Label';
  final transactionId = transaction.id;

  // Navigate to PlusPageedit
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PlusPageEdit(
        transactionId: transactionId,
      ),
    ),
  );
}

}

class TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final Color amountColor;
  final Function()? onTap; // Callback when tapped

  const TransactionItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.amountColor,
    this.onTap, // Accept the callback function
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Make the item clickable
      onTap: onTap, // Trigger the callback when tapped
      child: ListTile(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Color.fromARGB(243, 255, 191, 0),
            child: Icon(
              icon,
              color: Colors.black,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              amount,
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(
                color: Color.fromARGB(255, 139, 138, 138),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
