import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class Currency {
  String code;
  String name;
  double exchangeRate;

  Currency({
    required this.code,
    required this.name,
    this.exchangeRate = 1.0,
  });

  factory Currency.fromFirestore(Map<String, dynamic> data) {
    return Currency(
      code: data['code'],
      name: data['name'],
      exchangeRate: data['exchangeRate'].toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'exchangeRate': exchangeRate,
    };
  }
}

class CurrenciesPage extends StatefulWidget {
  final String userId; // Add userId to manage user-specific data

  CurrenciesPage({required this.userId});

  @override
  _CurrenciesPageState createState() => _CurrenciesPageState();
}

class _CurrenciesPageState extends State<CurrenciesPage> {
  List<Currency> currencies = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrencies();
  }

  Future<void> _fetchCurrencies() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('currencies')
        .get();
    
    final allCurrencies = querySnapshot.docs.map((doc) {
      return Currency.fromFirestore(doc.data());
    }).toList();

    setState(() {
      currencies = allCurrencies;
    });
  }

  void _navigateToAddCurrencyPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCurrencyPage(
          existingCodes: currencies.map((c) => c.code).toList(),
          onAddCurrency: _addCurrency,
          userId: widget.userId, // Pass the userId here
        ),
      ),
    );
  }

  void _navigateToAdjustExchangeRatePage(Currency currency) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdjustExchangeRatePage(
          currency: currency,
          onAdjustExchangeRate: _adjustExchangeRate,
        ),
      ),
    );
  }

  Future<void> _addCurrency(Currency currency) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('currencies')
        .doc(currency.code);

    await docRef.set(currency.toFirestore());

    setState(() {
      currencies.add(currency);
    });
  }

  Future<void> _adjustExchangeRate(String code, double newRate) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('currencies')
        .doc(code);

    await docRef.update({'exchangeRate': newRate});

    setState(() {
      currencies.firstWhere((currency) => currency.code == code).exchangeRate = newRate;
    });
  }

  Future<void> _deleteCurrency(int index) async {
    final currency = currencies[index];
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('currencies')
        .doc(currency.code);
    
    await docRef.delete();

    setState(() {
      currencies.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currencies'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: currencies.length,
          itemBuilder: (context, index) {
            final currency = currencies[index];
            return Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Dismissible(
                key: Key(currency.code),
                onDismissed: (direction) {
                  _deleteCurrency(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${currency.name} deleted')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  leading: Icon(Icons.monetization_on, color: Colors.black),
                  title: Text('${currency.code} - ${currency.name}'),
                  subtitle: Text('Exchange Rate: ${currency.exchangeRate.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: Colors.black),
                    onPressed: () => _navigateToAdjustExchangeRatePage(currency),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCurrencyPage,
        child: Icon(Icons.add),
        backgroundColor: Color.fromARGB(243, 255, 191, 0),
      ),
    );
  }
}



class AddCurrencyPage extends StatefulWidget {
  final List<String> existingCodes;
  final Function(Currency) onAddCurrency;
  final String userId; // Add userId to manage user-specific data

  AddCurrencyPage({
    required this.existingCodes,
    required this.onAddCurrency,
    required this.userId,
  });

  @override
  _AddCurrencyPageState createState() => _AddCurrencyPageState();
}

class _AddCurrencyPageState extends State<AddCurrencyPage> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedCode;
  List<Currency> _availableCurrencies = [];

  final Map<String, String> _currencyNames = {
    'USD': 'United States Dollar',
    'EUR': 'Euro',
    'INR': 'Indian Rupee',
    'GBP': 'British Pound',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'JPY': 'Japanese Yen',
    'NZD': 'New Zealand Dollar',
    // Add more currencies here
  };

  @override
  void initState() {
    super.initState();
    _fetchAvailableCurrencies();
  }

  Future<void> _fetchAvailableCurrencies() async {
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> rates = data['rates'];
        final List<Currency> currencies = rates.keys.map((code) {
          return Currency(
            code: code,
            name: _currencyNames[code] ?? 'Unknown Currency',
            exchangeRate: rates[code].toDouble(),
          );
        }).toList();
        setState(() {
          _availableCurrencies = currencies.where((currency) => !widget.existingCodes.contains(currency.code)).toList();
          _selectedCode = _availableCurrencies.isNotEmpty ? _availableCurrencies[0].code : null;
        });
      } else {
        throw Exception('Failed to load currencies');
      }
    } catch (e) {
      // Handle the error here
      print('Error fetching currencies: $e');
    }
  }

  void _addCurrency() async {
    if (_selectedCode != null && _nameController.text.trim().isNotEmpty) {
      final selectedCurrency = _availableCurrencies.firstWhere((currency) => currency.code == _selectedCode);
      final newCurrency = Currency(
        code: selectedCurrency.code,
        name: _nameController.text.trim(),
        exchangeRate: selectedCurrency.exchangeRate,
      );

      // Add currency to Firestore under user-specific document
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('currencies')
          .doc(newCurrency.code);
      await docRef.set(newCurrency.toFirestore());

      widget.onAddCurrency(newCurrency);
      Navigator.pop(context);
    } else {
      _showErrorDialog('Please select a currency and enter a name');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Currency'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add a new currency',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCode,
              items: _availableCurrencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency.code,
                  child: Text('${currency.code} - ${currency.name}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCode = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Currency Code',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Currency Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addCurrency,
              child: Text('Add Currency'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(243, 255, 191, 0),
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class AdjustExchangeRatePage extends StatefulWidget {
  final Currency currency;
  final Function(String, double) onAdjustExchangeRate;

  AdjustExchangeRatePage({required this.currency, required this.onAdjustExchangeRate});

  @override
  _AdjustExchangeRatePageState createState() => _AdjustExchangeRatePageState();
}

class _AdjustExchangeRatePageState extends State<AdjustExchangeRatePage> {
  late TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(text: widget.currency.exchangeRate.toString());
  }

  void _adjustExchangeRate() {
    final newRate = double.tryParse(_rateController.text.trim()) ?? widget.currency.exchangeRate;
    if (newRate > 0) {
      widget.onAdjustExchangeRate(widget.currency.code, newRate);
      Navigator.pop(context);
    } else {
      _showErrorDialog('Invalid exchange rate');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adjust Exchange Rate'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Adjust exchange rate for ${widget.currency.code}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Exchange Rate',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _adjustExchangeRate,
              child: Text('Adjust Rate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(243, 255, 191, 0),
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
