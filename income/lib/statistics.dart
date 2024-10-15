import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'budget.dart';
import 'calculator.dart';
import 'profile.dart';
import 'package:image/image.dart' as img;
import 'filter.dart';
import 'homepage.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class bottomnav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.gupterTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: bottom(),
    );
  }
}

class bottom extends StatefulWidget {
  @override
  _bottomState createState() => _bottomState();
}

class _bottomState extends State<bottom> {
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
        onPopInvoked: (didPop) {
          // logic
        },
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

class Statistics extends StatefulWidget {
  final String? type;
  final String? recordConfirmation;
  final String? category;
  final String? currency;
  final String? paymentType;
  final String? status;
  final bool includeTransfers;
  final bool includeDebts;

  Statistics({
    this.type,
    this.recordConfirmation,
    this.category,
    this.currency,
    this.paymentType,
    this.status,
    required this.includeTransfers,
    required this.includeDebts,
  });

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  String selectedButton = 'Today'; // Default selected button
  late TooltipBehavior _tooltipBehavior;
  final GlobalKey _spendingChartKey = GlobalKey();
  double income = 0.0;
  double expense = 0.0;
  double progressValue = 0.0;
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: false);
    fetchIncomeAndExpenses();
  }

  Future<void> fetchIncomeAndExpenses() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in!");
      }

      String uid = user.uid;

      DateTime now = DateTime.now();
    
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth =
          DateTime(now.year, now.month + 1, 0); 

      Timestamp startTimestamp = Timestamp.fromDate(startOfMonth);
      Timestamp endTimestamp = Timestamp.fromDate(endOfMonth);

      QuerySnapshot<Map<String, dynamic>> transactionsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('transactions')
              .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
              .where('timestamp', isLessThanOrEqualTo: endTimestamp)
              .get();

      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var doc in transactionsSnapshot.docs) {
        String category = doc['category'];
        double amount = double.tryParse(doc['amount'].toString()) ?? 0.0;

        if (category == 'Income') {
          totalIncome += amount;
        } else if (category == 'Expense') {
          totalExpense += amount;
        }
      }

      setState(() {
        income = totalIncome;
        expense = totalExpense;
        progressValue = totalIncome > 0 ? totalExpense / totalIncome : 0.0;
      });
    } catch (e) {
      print("Failed to fetch data: $e");
    }
  }

  void _onButtonPressed(String buttonText) {
    setState(() {
      selectedButton = buttonText;
    });
  }

  Future<List<ChartData>> _fetchDayWiseData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (selectedButton) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        break;
      case 'Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Year':
        startDate = DateTime(now.year - 1, 1, 1); // One year back from now
        endDate = now; // Up to the current date
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        break;
    }

    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDate)
        .get();

    Map<String, double> dataMap = {};

    for (var doc in querySnapshot.docs) {
      DateTime date;

      if (doc['timestamp'] is String) {
        date = DateTime.parse(doc['timestamp']);
      } else if (doc['timestamp'] is Timestamp) {
        date = (doc['timestamp'] as Timestamp).toDate();
      } else {
        throw Exception("Invalid timestamp format");
      }

      double amount;

      if (doc['amount'] is String) {
        amount =
            double.tryParse((doc['amount'] as String).replaceAll(',', '')) ??
                0.0;
      } else if (doc['amount'] is double) {
        amount = doc['amount'] as double;
      } else if (doc['amount'] is int) {
        amount = (doc['amount'] as int).toDouble();
      } else {
        amount = 0.0;
      }

      String formattedDate;
      if (selectedButton == 'Today') {
        formattedDate = DateFormat('HH').format(date);
      } else if (selectedButton == 'Week') {
        formattedDate = DateFormat('EEEE').format(date);
      } else if (selectedButton == 'Month') {
        formattedDate = DateFormat('MMM yyyy').format(date); // Month and year
      } else if (selectedButton == 'Year') {
        formattedDate =
            DateFormat('yyyy').format(date); // Year for custom range
      } else {
        formattedDate = date.toString();
      }

      dataMap.update(formattedDate, (existingAmount) => existingAmount + amount,
          ifAbsent: () => amount);
    }

    List<ChartData> chartData = [];
    if (selectedButton == 'Today') {
      for (int hour = 0; hour < 24; hour++) {
        String hourStr = hour.toString().padLeft(2, '0');
        chartData.add(
          ChartData(dateTime: hourStr, amount: dataMap[hourStr] ?? 0.0),
        );
      }
    } else if (selectedButton == 'Week') {
      List<String> daysOfWeek = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      for (var day in daysOfWeek) {
        chartData.add(
          ChartData(dateTime: day, amount: dataMap[day] ?? 0.0),
        );
      }
    } else if (selectedButton == 'Month') {
      List<String> months = [
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
      for (var month in months) {
        String monthYear = '$month ${now.year}'; // Add year to month
        chartData.add(
          ChartData(dateTime: monthYear, amount: dataMap[monthYear] ?? 0.0),
        );
      }
    } else if (selectedButton == 'Year') {
      for (int year = now.year - 1; year <= now.year; year++) {
        chartData.add(
          ChartData(
              dateTime: year.toString(),
              amount: dataMap[year.toString()] ?? 0.0),
        );
      }
    }

    return chartData;
  }

  Future<Map<String, dynamic>> _fetchExpenses() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in!");
    }

    String uid = user.uid;

    try {
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc('monthly')
          .get();

      if (expensesSnapshot.exists) {
        print('Expenses data: ${expensesSnapshot.data()}');
        return expensesSnapshot.data()!;
      } else {
        print('No data found for monthly expenses.');
        return {};
      }
    } catch (e) {
      print('Error fetching expenses: $e');
      return {};
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(top: 45, left: 20, right: 20),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(243, 186, 47, 1),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  final data = snapshot.data!;
                  final totalExpenses = data['totalExpenses'] ?? 0.0;
                  final expenseLimit = data['expenseLimit'] ?? 1.0;
                  final progress = totalExpenses / expenseLimit;

                  return Column(
  children: [
   
      
     Container(
        margin: const EdgeInsets.all(25),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(243, 186, 47, 1),
          border: Border.all(
            color: const Color.fromRGBO(243, 186, 47, 1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(243, 186, 47, 1).withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                'Total Expenses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '\$${totalExpenses.toStringAsFixed(2)}/\$${expenseLimit.toStringAsFixed(2)} per month',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Stack(
                children: [
                  Container(
                    height: 25,
                    decoration: BoxDecoration(
                      border: Border.all(width: 2, color: Colors.white),
                      borderRadius: BorderRadius.all(Radius.circular(34)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(34)),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 36,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      height: 30,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(34)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progressValue,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Color.fromARGB(255, 165, 163, 163),
                                  Colors.black
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
            ],
          ),
        ),
      ),
    
    Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Chart',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.share, color: Colors.grey),
                onPressed: () async {
                  await _captureAndSharePng();
                },
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 40,
            width: 480, // Adjust width as needed
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _buildButton('Today'),
                SizedBox(width: 1),
                _buildButton('Week'),
                SizedBox(width: 1),
                _buildButton('Month'),
                SizedBox(width: 1),
                _buildButton('Year'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: FutureBuilder<List<ChartData>>(
              future: _fetchDayWiseData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final chartData = snapshot.data!;

                  return RepaintBoundary(
  key: _globalKey, // Ensure _globalKey is defined
  child: Container(
    color: Colors.white,
    margin: const EdgeInsets.all(10),
    child: SfCartesianChart(
      primaryXAxis: CategoryAxis(
        title: AxisTitle(text: 'Date'),
        labelRotation: 45,
        majorGridLines: MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        isVisible: false,
        majorGridLines: MajorGridLines(width: 0),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries>[
        LineSeries<ChartData, String>(
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.dateTime,
          yValueMapper: (ChartData data, _) => data.amount,
          name: 'Expenses',
          color: Color.fromARGB(255, 250, 228, 27),
          dataLabelSettings: DataLabelSettings(isVisible: false),
          markerSettings: MarkerSettings(
            isVisible: true,
            color: Color.fromARGB(255, 222, 202, 17),
            borderWidth: 2,
            width: 5,
            height: 5,
            shape: DataMarkerType.circle,
          ),
        ),
      ],
    ),
  ),
);

                } else {
                  return Center(child: Text('No data available'));
                }
              },
            ),
          ),
        ],
      ),
    ),
  ],
);

               
    
                } else {
                  return Text('No data available');
                }
              },
            ),
            StatisticsSection(),
            MyHomePage(),
            IncomeExpensesDetails(),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCard(BuildContext context, GlobalKey key) async {
    try {
      await Future.delayed(Duration.zero);
      RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      if (boundary.debugNeedsPaint) {
        await Future.delayed(Duration(milliseconds: 20));
        boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      }
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw 'Failed to capture image.';
      }
      Uint8List jpegBytes = byteData.buffer.asUint8List();
      final directory = (await getApplicationDocumentsDirectory()).path;
      final imgFile = File('$directory/screenshot.jpeg');
      await imgFile.writeAsBytes(jpegBytes);
      final storageRef =
          FirebaseStorage.instance.ref().child('screenshots/screenshot.jpeg');
      final uploadTask = storageRef.putFile(imgFile);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      await Share.share('Check out this chart! $downloadUrl');
    } catch (e) {
      print(e.toString());
    }
  }

  Widget _buildButton(String label) {
    bool isHovered = false; // Track hover state

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
        });
      },
      child: ElevatedButton(
        onPressed: () => _onButtonPressed(label),
        style: ElevatedButton.styleFrom(
          foregroundColor: isHovered || selectedButton == label
              ? Colors.black
              : const Color.fromARGB(255, 0, 0, 0),
          backgroundColor: isHovered || selectedButton == label
              ? Colors.amber
              : Colors.white, // Text color
          side: BorderSide(
            color: isHovered || selectedButton == label
                ? const Color.fromARGB(255, 255, 255, 255)
                : Colors.black, // Border color
            width: 1, // Border width
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners
          ),
        ),
        child: Text(label),
      ),
    );
  }

  // Widget _buildButton(String buttonText) {
  //   return Expanded(
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 5),
  //       child: ElevatedButton(
  //         onPressed: () => _onButtonPressed(buttonText),
  //         style: ElevatedButton.styleFrom(
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(25),
  //             side: BorderSide(
  //               color: Colors.black, // Black border color
  //               width: 1, // Border width
  //             ),
  //           ),
  //           padding: const EdgeInsets.symmetric(vertical: 15),
  //           backgroundColor: selectedButton == buttonText
  //               ? const Color.fromRGBO(243, 186, 47, 1)
  //               : Colors.white,
  //           foregroundColor:
  //               selectedButton == buttonText ? Colors.white : Colors.black,
  //         ),
  //         child: Text(
  //           buttonText,
  //           style: const TextStyle(
  //             fontSize: 14,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

class StatisticsSection extends StatefulWidget {
  @override
  _StatisticsSectionState createState() => _StatisticsSectionState();
}

class _StatisticsSectionState extends State<StatisticsSection> {
  final GlobalKey _categoriesChartKey = GlobalKey();
    final GlobalKey _globalKey = GlobalKey();
  String selectedButton = 'Day';
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color.fromARGB(255, 252, 249, 249),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildCategoriesStream(),
        ],
      ),
    );
  }

  /// Builds the categories pie chart section with the RepaintBoundary
  Widget _buildCategoriesStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('transactions')
          .where('category', isEqualTo: 'Expense')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        List<QueryDocumentSnapshot> transactions = snapshot.data!.docs;
        Map<String, double> categories = {};
        double totalExpense = 0.0;

        for (var doc in transactions) {
          final data = doc.data() as Map<String, dynamic>;
          final label = data['label'] ?? 'Unknown';
          final amount = double.tryParse(data['amount'].toString()) ?? 0.0;

          categories[label] = (categories[label] ?? 0) + amount;
          totalExpense += amount;
        }

        List<PieChartSectionData> pieSections = categories.entries.map((entry) {
          final color = Colors.primaries[
              categories.keys.toList().indexOf(entry.key) % Colors.primaries.length];
          final percentage = ((entry.value / totalExpense) * 100).toStringAsFixed(1);
          return PieChartSectionData(
            value: entry.value,
            color: color,
            title: '$percentage%',
          );
        }).toList();

        return RepaintBoundary(
          key: _globalKey,  // This key will capture the entire widget
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoriesHeader(),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: pieSections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoriesLegend(categories),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the header for the categories chart
  Widget _buildCategoriesHeader() {
    DateTime now = DateTime.now();
    String dateRange =
        "${DateFormat('MM-dd-yyyy').format(now.subtract(Duration(days: 7)))} - ${DateFormat('MM-dd-yyyy').format(now)}";

    return Column(
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  dateRange,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color.fromARGB(255, 49, 43, 43),
                  ),
                ),
              ],
            ),
            Spacer(),
             IconButton(
                icon: Icon(Icons.share, color: Colors.grey),
                onPressed: () async {
                  await _captureAndSharePng();
                },
              ),
          ],
        ),
      ],
    );
  }

  /// Builds the legend for the categories chart
  Widget _buildCategoriesLegend(Map<String, double> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.entries.map((entry) {
        final color = Colors.primaries[
            categories.keys.toList().indexOf(entry.key) % Colors.primaries.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.key} (₹${entry.value.toStringAsFixed(2)})',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
class ChartData {
  final String dateTime;
  final double amount;

  ChartData({required this.dateTime, required this.amount});
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}


class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isTrendSelected = true;
  final GlobalKey _globalKey = GlobalKey(); // Key for capturing the widget
  int _currentYear = DateTime.now().year;
  String? uid;

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in!");
    }

    uid = user.uid; // Store the user's UID
  }

  bool _isInSelectedYear(DocumentSnapshot doc, int selectedYear) {
    if (doc['date'] != null) {
      DateTime transactionDate;
      try {
        // Try to parse the date string
        transactionDate = DateTime.parse(doc['date']);
      } catch (e) {
        // Handle the error if parsing fails
        print('Error parsing date: $e');
        return false;
      }
      return transactionDate.year == selectedYear;
    }
    return false;
  }

  List<_ChartData> _processTransactions(
      List<DocumentSnapshot> incomeTransactions,
      List<DocumentSnapshot> expenseTransactions) {
    List<_ChartData> chartData = [];
    Map<DateTime, double> weeklyIncomeMap = {};
    Map<DateTime, double> weeklyExpenseMap = {};
    Map<DateTime, double> monthlyIncomeMap = {};
    Map<DateTime, double> monthlyExpenseMap = {};

    // Helper function to get the start of the week
    DateTime _getStartOfWeek(DateTime date) {
      int weekday = date.weekday;
      return date.subtract(Duration(days: weekday - 1));
    }

    // Process income transactions
    for (var doc in incomeTransactions) {
      if (doc['date'] != null && doc['amount'] != null) {
        DateTime date;
        try {
          date = DateTime.parse(doc['date']);
        } catch (e) {
          print('Error parsing date: $e');
          continue;
        }

        double amount;
        try {
          amount = doc['amount'] is String
              ? double.parse(doc['amount'])
              : doc['amount'].toDouble();
        } catch (e) {
          print('Error converting amount: $e');
          continue;
        }

        DateTime startOfWeek =
            _getStartOfWeek(DateTime(date.year, date.month, date.day));
        weeklyIncomeMap[startOfWeek] =
            (weeklyIncomeMap[startOfWeek] ?? 0) + amount;

        DateTime monthStart = DateTime(date.year, date.month, 1);
        monthlyIncomeMap[monthStart] =
            (monthlyIncomeMap[monthStart] ?? 0) + amount;
      }
    }

    // Process expense transactions
    for (var doc in expenseTransactions) {
      if (doc['date'] != null && doc['amount'] != null) {
        DateTime date;
        try {
          date = DateTime.parse(doc['date']);
        } catch (e) {
          print('Error parsing date: $e');
          continue;
        }

        double amount;
        try {
          amount = doc['amount'] is String
              ? double.parse(doc['amount'])
              : doc['amount'].toDouble();
        } catch (e) {
          print('Error converting amount: $e');
          continue;
        }

        DateTime startOfWeek =
            _getStartOfWeek(DateTime(date.year, date.month, date.day));
        weeklyExpenseMap[startOfWeek] =
            (weeklyExpenseMap[startOfWeek] ?? 0) + amount;

        DateTime monthStart = DateTime(date.year, date.month, 1);
        monthlyExpenseMap[monthStart] =
            (monthlyExpenseMap[monthStart] ?? 0) + amount;
      }
    }

    DateTime? previousDate;
    double cumulativeIncome = 0;
    double cumulativeExpense = 0;

    if (isTrendSelected) {
      // For Trend View: Weekly Data
      weeklyIncomeMap.forEach((date, income) {
        double expense = weeklyExpenseMap[date] ?? 0;
        double cashFlow = income - expense;

        chartData.add(_ChartData(date, income, expense, cashFlow));
      });

      weeklyExpenseMap.forEach((date, expense) {
        if (!weeklyIncomeMap.containsKey(date)) {
          double income = 0;
          double cashFlow = income - expense;

          chartData.add(_ChartData(date, income, expense, cashFlow));
        }
      });
    } else {
      // For Cumulative View: Monthly Data
      monthlyIncomeMap.forEach((date, income) {
        double expense = monthlyExpenseMap[date] ?? 0;
        cumulativeIncome += income;
        cumulativeExpense += expense;
        double cashFlow = cumulativeIncome - cumulativeExpense;

        chartData.add(
            _ChartData(date, cumulativeIncome, cumulativeExpense, cashFlow));
      });
    }

    return chartData;
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid!) // Use the stored UID
          .collection('transactions')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Filter transactions for the current and previous year
        final incomeTransactions = snapshot.data!.docs
            .where((doc) =>
                doc['category'] == 'Income' &&
                _isInSelectedYear(doc, _currentYear))
            .toList();
        final expenseTransactions = snapshot.data!.docs
            .where((doc) =>
                doc['category'] == 'Expense' &&
                _isInSelectedYear(doc, _currentYear))
            .toList();

        List<_ChartData> chartData =
            _processTransactions(incomeTransactions, expenseTransactions);

        return Center(
          child: RepaintBoundary(
            key: _globalKey,
            child: Container(
              height: 700,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cash Flow Trend',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                               IconButton(
                icon: Icon(Icons.share, color: Colors.grey),
                onPressed: () async {
                  await _captureAndSharePng();
                },
              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                              'In which periods was I saving more or less money?'),
                          const SizedBox(height: 8),
                          const Text("This Year",
                              style:
                                  TextStyle(fontSize: 15, color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                double paddingValue = constraints.maxWidth *
                                    0.1; // 10% of the available width
                                paddingValue = paddingValue.clamp(16.0,
                                    50.0); // Ensure padding is within a reasonable range

                                return Row(
                                  children: [
                                    Expanded(
                                        child: Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.blue),
                                                color: isTrendSelected
                                                    ? Colors.blue
                                                    : Colors.transparent,
                                                borderRadius: const BorderRadius
                                                    .horizontal(
                                                    left: Radius.circular(20)),
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    isTrendSelected = true;
                                                  });
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      20.0),
                                                  child: Center(
                                                    child: Text(
                                                      'Trend',
                                                      style: TextStyle(
                                                        color: isTrendSelected
                                                            ? Colors.white
                                                            : Colors.blue,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.blue),
                                                color: isTrendSelected
                                                    ? Colors.transparent
                                                    : Colors.blue,
                                                borderRadius: const BorderRadius
                                                    .horizontal(
                                                    right: Radius.circular(20)),
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    isTrendSelected = false;
                                                  });
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      20.0),
                                                  child: Center(
                                                    child: Text(
                                                      'Cumulative',
                                                      style: TextStyle(
                                                        color: isTrendSelected
                                                            ? Colors.blue
                                                            : Colors.white,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      majorTickLines: const MajorTickLines(size: 25),
                      dateFormat: DateFormat('MMM yyyy'),
                      intervalType: DateTimeIntervalType.months,
                      interval: 3,
                    ),
                    primaryYAxis: NumericAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      majorTickLines: const MajorTickLines(size: 3),
                    ),
                    series: <CartesianSeries<dynamic, dynamic>>[
                      StackedColumnSeries<_ChartData, dynamic>(
                        dataSource: chartData,
                        xValueMapper: (_ChartData data, _) => data.date,
                        yValueMapper: (_ChartData data, _) => data.incomes,
                        color: Color.fromARGB(255, 21, 216, 154),
                      ),
                      StackedColumnSeries<_ChartData, dynamic>(
                        dataSource: chartData,
                        xValueMapper: (_ChartData data, _) => data.date,
                        yValueMapper: (_ChartData data, _) => data.expenses,
                        color: Color.fromARGB(255, 227, 45, 45),
                      ),
                      SplineSeries<_ChartData, dynamic>(
                        dataSource: chartData,
                        xValueMapper: (_ChartData data, _) => data.date,
                        yValueMapper: (_ChartData data, _) => data.cashFlow,
                        color: Colors.black,
                        width: 2,
                      ),
                    ],
                    legend: Legend(isVisible: false),
                  ),
                  const SizedBox(width: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LegendItem(
                          color: const Color.fromARGB(255, 16, 18, 20),
                          text: 'Cash Flow'),
                      const SizedBox(width: 20),
                      LegendItem(
                          color: const Color.fromARGB(255, 21, 216, 154),
                          text: 'Income'),
                      const SizedBox(width: 20),
                      LegendItem(
                          color: const Color.fromARGB(255, 232, 77, 47),
                          text: 'Expenses'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChartData {
  _ChartData(this.date, this.incomes, this.expenses, this.cashFlow);
  final DateTime date;
  final double incomes;
  final double expenses;
  final double cashFlow;
}

class IncomeExpensesDetails extends StatefulWidget {
  @override
  _IncomeExpensesDetailsState createState() => _IncomeExpensesDetailsState();
}

class _IncomeExpensesDetailsState extends State<IncomeExpensesDetails> {
  int _currentYear = DateTime.now().year;
   GlobalKey _globalKey = GlobalKey();
  double currentTotal = 0.0;
  double pastTotal = 0.0;
Future<void> _captureAndSharePng() async {
  try {
    RenderRepaintBoundary boundary = _globalKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Save to local file (PNG format to preserve transparency)
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/budget_image.png';
    File(imagePath).writeAsBytesSync(pngBytes);

    // Share the PNG image file directly
    await Share.shareFiles([imagePath], text: 'Check out my budget image!');
  } catch (e) {
    print(e.toString());
  }
}


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text("User not logged in"));
    }

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Filter transactions for the current and previous year
        final incomeTransactions = snapshot.data!.docs
            .where((doc) =>
                doc['category'] == 'Income' &&
                _isInSelectedYear(doc, _currentYear))
            .toList();
        final expenseTransactions = snapshot.data!.docs
            .where((doc) =>
                doc['category'] == 'Expense' &&
                _isInSelectedYear(doc, _currentYear))
            .toList();

        // Calculate totals for the selected year and the previous year
        currentTotal = _calculateTotalAmount(incomeTransactions) -
            _calculateTotalAmount(expenseTransactions);
        pastTotal =
            _fetchPastPeriodTotal(snapshot.data!.docs, _currentYear - 1);

        // Calculate percentage change and determine color
        String percentageChange =
            _calculatePercentageChange(currentTotal, pastTotal);
        Color percentageChangeColor =
            currentTotal >= pastTotal ? Colors.green : Colors.red;

        // Generate a list of years for the dropdown
        int currentYear = DateTime.now().year;
        List<int> years =
            List.generate(21, (index) => currentYear - 10 + index);

        return  RepaintBoundary(
              key: _globalKey,
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         
                            Text(
                              ' Income & Expenses Book in INR',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          
                        ],
                      ),
                      SizedBox(width: 45),
                    IconButton(
                icon: Icon(Icons.share, color: Colors.grey),
                onPressed: () async {
                  await _captureAndSharePng();
                },
              ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('  This Year', style: TextStyle(color: Colors.grey)),
                  Row(
                    children: [
                      Text(
                        ' ₹${(currentTotal).toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 135),
                      Column(
                        children: [
                          const Text('vs past period ',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            percentageChange, // Dynamic percentage change
                            style: TextStyle(
                                color: percentageChangeColor, fontSize: 34),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Income and Expenses Items
                  IncomeExpenseItem(
                    title: '      Income',
                    amount:
                        '₹${_calculateTotalAmount(incomeTransactions).toStringAsFixed(2)}',
                    percentage: _calculatePercentage(
                        _calculateTotalAmount(incomeTransactions), currentTotal),
                    percentageColor: Color.fromARGB(255, 56, 211, 149),
                    items: incomeTransactions.map((doc) {
                      return IncomeExpenseSubItem(
                        icon: Icons.paid,
                        title: doc['label'] ?? 'Unknown Income',
                        amount:
                            '${double.tryParse(doc['amount'].toString().replaceAll(',', ''))}',
                        percentage: _calculatePercentage(
                            double.tryParse(doc['amount'].toString()) ?? 0,
                            _calculateTotalAmount(incomeTransactions)),
                        percentageColor: Colors.green,
                      );
                    }).toList(),
                  ),
                  IncomeExpenseItem(
                    title: '      Expenses',
                    amount:
                        '₹${_calculateTotalAmount(expenseTransactions).toStringAsFixed(2)}',
                    percentage: _calculatePercentage(
                        _calculateTotalAmount(expenseTransactions), currentTotal),
                    percentageColor: Colors.red,
                    items: expenseTransactions.map((doc) {
                      return IncomeExpenseSubItem(
                        icon: _getIconForCategory(doc['label']),
                        title: doc['label'] ?? 'Unknown Expense',
                        amount:
                            '${double.tryParse(doc['amount'].toString().replaceAll(',', ''))}',
                        percentage: _calculatePercentage(
                            double.tryParse(doc['amount'].toString()) ?? 0,
                            _calculateTotalAmount(expenseTransactions)),
                        percentageColor: Colors.red,
                      );
                    }).toList(),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(30)),
                            ),
                            child: InkWell(
                              onTap: () => _changeYear(-1),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                                child: Icon(Icons.chevron_left, color: Colors.blue),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Color.fromARGB(255, 11, 113, 191)),
                              color: Color.fromARGB(255, 33, 148, 243),
                            ),
                            child: DropdownButton<int>(
                              value: years.contains(_currentYear)
                                  ? _currentYear
                                  : null,
                              onChanged: _selectYear,
                              items: years.map((year) {
                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Center(
                                    child: Text(year.toString(),
                                        style: TextStyle(fontSize: 16)),
                                  ),
                                );
                              }).toList(),
                              isExpanded: true,
                              dropdownColor: Color.fromARGB(255, 33, 148, 243),
                              icon:
                                  Icon(Icons.arrow_drop_down, color: Colors.white),
                              underline: SizedBox.shrink(),
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(20)),
                            ),
                            child: InkWell(
                              onTap: () => _changeYear(1),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                                child:
                                    Icon(Icons.chevron_right, color: Colors.blue),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isInSelectedYear(QueryDocumentSnapshot doc, int year) {
    dynamic timestampField = doc['timestamp'];

    DateTime date;

    if (timestampField is Timestamp) {
      // Convert Timestamp to DateTime
      date = timestampField.toDate();
    } else if (timestampField is String) {
      // Parse String to DateTime
      date = DateTime.parse(timestampField);
    } else {
      // Handle unexpected data type
      throw Exception('Unexpected timestamp field type');
    }

    return date.year == year;
  }

  double _calculateTotalAmount(List<QueryDocumentSnapshot> transactions) {
    double total = 0.0;
    for (var doc in transactions) {
      double amount =
          double.tryParse(doc['amount'].toString().replaceAll(',', '')) ?? 0.0;
      total += amount;
    }
    return total;
  }

  String _calculatePercentage(double amount, double total) {
    if (total == 0) return '0%';
    double percentage = (amount / total) * 100;
    return '${percentage.toStringAsFixed(2)}%';
  }

  String _calculatePercentageChange(double current, double past) {
    if (past == 0) return current > 0 ? "+100%" : "0%";
    double change = ((current - past) / past) * 100;
    return change >= 0
        ? "+${change.toStringAsFixed(2)}%"
        : "${change.toStringAsFixed(2)}%";
  }

  double _fetchPastPeriodTotal(
      List<QueryDocumentSnapshot> transactions, int pastYear) {
    double totalIncome = transactions
        .where((doc) =>
            doc['category'] == 'Income' && _isInSelectedYear(doc, pastYear))
        .fold(
            0.0,
            (sum, doc) =>
                sum +
                (double.tryParse(
                        doc['amount'].toString().replaceAll(',', '')) ??
                    0.0));

    double totalExpenses = transactions
        .where((doc) =>
            doc['category'] == 'Expense' && _isInSelectedYear(doc, pastYear))
        .fold(
            0.0,
            (sum, doc) =>
                sum +
                (double.tryParse(
                        doc['amount'].toString().replaceAll(',', '')) ??
                    0.0));

    return totalIncome - totalExpenses;
  }

  void _changeYear(int delta) {
    setState(() {
      _currentYear += delta;
    });
  }

  void _selectYear(int? year) {
    if (year != null && _currentYear != year) {
      setState(() {
        _currentYear = year;
      });
    }
  }

  IconData _getIconForCategory(String? category) {
    switch (category) {
      case 'Food & Drinks':
        return Icons.restaurant;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Housing':
        return Icons.home;
      case 'Transportation':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Healthcare':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }
}

class IncomeExpenseItem extends StatelessWidget {
  final String title;
  final String amount;
  final String percentage;
  final Color percentageColor;
  final List<IncomeExpenseSubItem> items;

  IncomeExpenseItem({
    required this.title,
    required this.amount,
    required this.percentage,
    required this.percentageColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 50),
                Text(
                  percentage,
                  style: TextStyle(color: percentageColor),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const Divider(),
        ),
        Column(
          children: items,
        ),
      ],
    );
  }
}

class IncomeExpenseSubItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;
  final String percentage;
  final Color percentageColor;

  IncomeExpenseSubItem({
    required this.icon,
    required this.title,
    required this.amount,
    required this.percentage,
    required this.percentageColor,
  });

  @override
  Widget build(BuildContext context) {
    double amountValue;
    try {
      amountValue = double.parse(
          amount.replaceAll(',', '')); // Handle commas in the amount string
    } catch (e) {
      amountValue = 0; // Set to 0 if parsing fails
    }

    double percentageValue;
    try {
      percentageValue = double.parse(percentage.replaceAll(
          '%', '')); // Handle percentage sign in the string
    } catch (e) {
      percentageValue = 0; // Set to 0 if parsing fails
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: SingleChildScrollView(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SizedBox(width: 15),
                Icon(icon, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            Row(
              children: [
                Text('₹${amountValue.toStringAsFixed(2)}'),
                const SizedBox(width: 80),
                Text(
                  '${percentageValue.toStringAsFixed(2)}%',
                  style: TextStyle(color: percentageColor),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
