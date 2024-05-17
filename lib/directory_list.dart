import 'package:flutter/material.dart';
import 'package:ftp_client/download_manager.dart';
import 'package:ftp_client/ftp_client_manager.dart';
import 'package:pure_ftp/pure_ftp.dart';

class DirectoryList extends StatefulWidget {
  final FTPClientManager ftpClientManager;
  final DownloadManager downloadManager;

  const DirectoryList({
    super.key,
    required this.ftpClientManager,
    required this.downloadManager,
  });

  @override
  State<DirectoryList> createState() => _DirectoryListState();
}

class _DirectoryListState extends State<DirectoryList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.ftpClientManager.entries.length,
      itemBuilder: (context, index) {
        final entry = widget.ftpClientManager.entries[index];
        return ListTile(
          leading: Icon(entry.isDirectory ? Icons.folder : Icons.file_copy),
          title: Text(entry.name),
          onTap: () async {
            if (entry.isDirectory) {
              if (entry.name == '..') {
                await widget.ftpClientManager.ftpConnect!.changeDirectoryUp();
                await widget.ftpClientManager.listDirectory();
              } else {
                await widget.ftpClientManager
                    .listDirectory(entry as FtpDirectory);
              }
              setState(() {});
            } else {
              _showDownloadDialog(context, entry as FtpFile);
            }
          },
        );
      },
    );
  }

  void _showDownloadDialog(BuildContext context, FtpFile file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Download File'),
          content: Text('Do you want to download ${file.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.downloadManager.addToQueue(
                    file, widget.ftpClientManager.ftpConnect!, context);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
