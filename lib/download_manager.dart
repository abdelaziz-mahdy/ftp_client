import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_ftp/pure_ftp.dart';

class DownloadManager {
  final List<FtpFile> _downloadQueue = [];
  bool _isDownloading = false;

  Future<void> addToQueue(
      FtpFile file, FtpClient ftpConnect, BuildContext context) async {
    _downloadQueue.add(file);
    if (!_isDownloading) {
      _startDownload(ftpConnect, context);
    }
  }

  Future<void> _startDownload(
      FtpClient ftpConnect, BuildContext context) async {
    _isDownloading = true;

    while (_downloadQueue.isNotEmpty) {
      final file = _downloadQueue.removeAt(0);
      try {
        await _downloadFile(file, ftpConnect, context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download: ${file.name} $e')));
      }
    }

    _isDownloading = false;
  }

  Future<void> _downloadFile(
      FtpFile file, FtpClient ftpConnect, BuildContext context) async {
    Directory? downloadsDirectory = await getDownloadsDirectory();
    DateTime startTime = DateTime.now();

    List<int> bytes = await ftpConnect.fs.downloadFile(file,
        onReceiveProgress: (bytes, total, p) {
      DateTime currentTime = DateTime.now();
      Duration elapsed = currentTime.difference(startTime);
      double speed = bytes / elapsed.inSeconds;
      print(
          "downloaded: $bytes of $total, $p% calculated ${bytes / total * 100}%, speed: ${(speed / 1024 / 1024).toStringAsFixed(2)} MB/second");
    });

    File('${downloadsDirectory!.path}/${file.name}').writeAsBytes(bytes);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Downloaded: ${file.name}')));
  }
}
