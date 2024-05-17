import 'package:flutter/material.dart';
import 'ftp_client_manager.dart';
import 'download_manager.dart';
import 'ftp_connect_form.dart';
import 'directory_list.dart';

class FTPHomePage extends StatefulWidget {
  const FTPHomePage({super.key});

  @override
  _FTPHomePageState createState() => _FTPHomePageState();
}

class _FTPHomePageState extends State<FTPHomePage> {
  final _formKey = GlobalKey<FormState>();
  final FTPClientManager _ftpClientManager = FTPClientManager();
  final DownloadManager _downloadManager = DownloadManager();

  @override
  void dispose() {
    _ftpClientManager.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _ftpClientManager.isConnected
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  await _ftpClientManager.disconnect();
                  setState(() {});
                },
              )
            : null,
        title: const Text('FTP Connect App'),
        actions: [
          _ftpClientManager.isConnected
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    await _ftpClientManager.listDirectory();
                    setState(() {});
                  },
                )
              : Container(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _ftpClientManager.isConnected
            ? DirectoryList(
                ftpClientManager: _ftpClientManager,
                downloadManager: _downloadManager,
              )
            : FTPConnectForm(
                formKey: _formKey,
                ftpClientManager: _ftpClientManager,
                onConnected: () => setState(() {}),
              ),
      ),
    );
  }
}
