import 'package:flutter/material.dart';
import 'package:ftp_client/controllers/ftp_client_manager.dart';

class FTPConnectForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final FTPClientManager ftpClientManager;
  final VoidCallback onConnected;

  const FTPConnectForm({
    super.key,
    required this.formKey,
    required this.ftpClientManager,
    required this.onConnected,
  });

  @override
  State<FTPConnectForm> createState() => _FTPConnectFormState();
}

class _FTPConnectFormState extends State<FTPConnectForm> {
  bool _isLoading = false;
  String host = '192.168.1.5';
  String port = '15114';
  String user = 'anonymous';
  String pass = '';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Host'),
            onChanged: (value) => host = value,
            initialValue: host,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Port'),
            initialValue: port,
            onChanged: (value) => port = value,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Username'),
            initialValue: 'anonymous',
            onChanged: (value) => user = value,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (value) => pass = value,
            obscureText: true,
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    try {
                      setState(() {
                        _isLoading = true;
                      });
                      await widget.ftpClientManager.connect(
                        host: host,
                        port: port,
                        user: user,
                        pass: pass,
                      );
                      widget.onConnected();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to connect, $e')),
                      );
                    }
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: const Text('Connect'),
                ),
        ],
      ),
    );
  }
}
