import 'package:flutter/material.dart';
import 'package:ftp_client/ftp_client_manager.dart';

class FTPConnectForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final FTPClientManager ftpClientManager;
  final VoidCallback onConnected;
  final bool _isLoading = false;

  const FTPConnectForm({
    super.key,
    required this.formKey,
    required this.ftpClientManager,
    required this.onConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Host'),
            onChanged: (value) => ftpClientManager.host = value,
            initialValue: ftpClientManager.host,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Port'),
            initialValue: ftpClientManager.port,
            onChanged: (value) => ftpClientManager.port = value,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Username'),
            initialValue: 'anonymous',
            onChanged: (value) => ftpClientManager.user = value,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (value) => ftpClientManager.pass = value,
            obscureText: true,
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    try {
                      await ftpClientManager.connect();
                      onConnected();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to connect, $e')));
                    }
                  },
                  child: const Text('Connect'),
                ),
        ],
      ),
    );
  }
}
