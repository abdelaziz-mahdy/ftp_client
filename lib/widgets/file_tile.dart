import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:ftp_client/widgets/directory_list.dart';
import 'package:ftp_client/controllers/download_manager.dart';
import 'package:ftp_client/controllers/ftp_client_manager.dart';
import 'package:pure_ftp/pure_ftp.dart';

class FileTile extends StatefulWidget {
  final FtpEntry entry;
  final FTPClientManager ftpClientManager;
  final DownloadManager downloadManager;

  const FileTile({
    super.key,
    required this.entry,
    required this.ftpClientManager,
    required this.downloadManager,
  });

  @override
  _FileTileState createState() => _FileTileState();
}

class _FileTileState extends State<FileTile> {
  double downloadProgress = 0.0;

  void _updateProgress(double progress) {
    setState(() {
      downloadProgress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDirectory = entry.isDirectory;

    final subtitle = isDirectory
        ? null
        : 'Size: ${filesize(entry.info?.size ?? 0) ?? "unknown"}';

    return ListTile(
      leading: Icon(isDirectory ? Icons.folder : Icons.file_copy),
      title: Text(entry.name!),
      subtitle: isDirectory
          ? null
          : Text(subtitle! +
              (downloadProgress > 0
                  ? ' | Downloading: ${(downloadProgress * 100).toStringAsFixed(2)}%'
                  : '')),
      onTap: () async {
        if (isDirectory) {
          if (entry.name == '..') {
            await widget.ftpClientManager.ftpConnect!.changeDirectoryUp();
            await widget.ftpClientManager.listDirectory();
          } else {
            await widget.ftpClientManager.listDirectory(entry as FtpDirectory);
          }
        } else {
          _showDownloadDialog(context, entry as FtpFile);
        }
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
                  file,
                  widget.ftpClientManager.ftpConnect!,
                  context,
                  _updateProgress,
                );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
