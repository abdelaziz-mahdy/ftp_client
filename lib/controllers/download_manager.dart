import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_ftp/pure_ftp.dart';

typedef ProgressCallback = void Function(double progress);

class DownloadManager {
  final List<FtpFile> _downloadQueue = [];
  bool _isDownloading = false;

  Future<void> addToQueue(FtpFile file, FtpClient ftpConnect, BuildContext context, ProgressCallback progressCallback) async {
    _downloadQueue.add(file);
    if (!_isDownloading) {
      _startDownload(ftpConnect, context, progressCallback);
    }
  }

  Future<void> _startDownload(FtpClient ftpConnect, BuildContext context, ProgressCallback progressCallback) async {
    _isDownloading = true;

    while (_downloadQueue.isNotEmpty) {
      final file = _downloadQueue.removeAt(0);
      try {
        await _downloadFile(file, ftpConnect, context, progressCallback);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download: ${file.name} $e')));
      }
    }

    _isDownloading = false;
  }

  Future<void> _downloadFile(FtpFile file, FtpClient ftpConnect, BuildContext context, ProgressCallback progressCallback) async {
    Directory? downloadsDirectory = await getDownloadsDirectory();
    DateTime startTime = DateTime.now();

    List<int> bytes = await ftpConnect.fs.downloadFile(file, onReceiveProgress: (receivedBytes, totalBytes, percent) {
      DateTime currentTime = DateTime.now();
      Duration elapsed = currentTime.difference(startTime);
      double speed = receivedBytes / elapsed.inSeconds;
      print("downloaded: $receivedBytes of $totalBytes, $percent% calculated ${receivedBytes / totalBytes * 100}%, speed: ${(speed / 1024 / 1024).toStringAsFixed(2)} MB/second");
      progressCallback(percent / 100);
    });

    File('${downloadsDirectory!.path}/${file.name}').writeAsBytes(bytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded: ${file.name}')));
    progressCallback(1.0);
  }
}
