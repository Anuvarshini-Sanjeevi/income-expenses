import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityPage extends StatefulWidget {
  @override
  _SecurityPageState createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _isAppLockEnabled = false;
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAppLockStatus();
  }

  Future<void> _checkAppLockStatus() async {
    final pin = await _storage.read(key: 'app_pin');
    setState(() {
      _isAppLockEnabled = pin != null;
    });
  }

  Future<void> _toggleAppLock(bool? value) async {
    setState(() {
      _isAppLockEnabled = value ?? false;
    });

    if (_isAppLockEnabled) {
      _showSetPinDialog();
    } else {
      await _storage.delete(key: 'app_pin');
    }
  }

  void _showSetPinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _pinController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Enter PIN'),
              ),
              TextField(
                controller: _confirmPinController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm PIN'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _savePin,
              child: Text('Save PIN'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.isNotEmpty && pin == confirmPin) {
      await _storage.write(key: 'app_pin', value: pin);
      Navigator.pop(context);
    } else {
      // Handle error (e.g., show a dialog or message)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PINs do not match or are empty')),
      );
    }
  }

  Future<void> _verifyPin() async {
    final pin = await _storage.read(key: 'app_pin');
    if (pin == _pinController.text.trim()) {
      // PIN is correct
      Navigator.pop(context);
    } else {
      // Handle incorrect PIN
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protect your app with security settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'App Lock',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Switch(
                  value: _isAppLockEnabled,
                  onChanged: _toggleAppLock,
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_isAppLockEnabled) ...[
              ListTile(
                leading: Icon(Icons.lock),
                title: Text('Change PIN'),
                subtitle: Text('Change your app PIN'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Change PIN'),
                        content: TextField(
                          controller: _pinController,
                          obscureText: true,
                          decoration: InputDecoration(labelText: 'Enter PIN'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: _verifyPin,
                            child: Text('Verify PIN'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.fingerprint),
                title: Text('Enable Fingerprint'),
                subtitle: Text('Enable fingerprint authentication'),
                onTap: () {},
              ),
              Divider(),
            ],
            ListTile(
              leading: Icon(Icons.lock_open),
              title: Text('Disable Security'),
              subtitle: Text('Disable all security features'),
              onTap: () async {
                await _storage.delete(key: 'app_pin');
                setState(() {
                  _isAppLockEnabled = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
