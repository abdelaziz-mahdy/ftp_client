import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_ftp/pure_ftp.dart';

typedef ProgressCallback = void Function(double progress);
typedef SnackBarCallback = void Function(FtpFile file, String message);

class DownloadManager {
  final List<FtpEntry> _downloadQueue = [];
  bool _isDownloading = false;
  int totalFiles = 0;
  int downloadedFiles = 0;
  int totalSize = 0;
  int downloadedSize = 0;

  Future<void> addToQueue(
      FtpEntry entry,
      FtpClient ftpConnect,
      SnackBarCallback snackBarCallback,
      ProgressCallback progressCallback) async {
    if (entry is FtpFile) {
      _downloadQueue.add(entry);
      totalFiles++;
      totalSize += entry.info?.size ?? 0;
    } else if (entry is FtpDirectory) {
      final entries = await ftpConnect.fs.listDirectory(directory: entry);
      for (var subEntry in entries) {
        await addToQueue(
            subEntry, ftpConnect, snackBarCallback, progressCallback);
      }
    }

    if (!_isDownloading) {
      _startDownload(ftpConnect, snackBarCallback, progressCallback);
    }
  }

  Future<void> _startDownload(
      FtpClient ftpConnect,
      SnackBarCallback snackBarCallback,
      ProgressCallback progressCallback) async {
    _isDownloading = true;

    while (_downloadQueue.isNotEmpty) {
      final entry = _downloadQueue.removeAt(0);
      try {
        if (entry is FtpFile) {
          await _downloadFile(
              entry, ftpConnect, snackBarCallback, progressCallback);
        }
      } catch (e) {
        snackBarCallback(entry as FtpFile, e.toString());
      }
    }

    _isDownloading = false;
  }

  Future<void> _downloadFile(
      FtpFile file,
      FtpClient ftpConnect,
      SnackBarCallback snackBarCallback,
      ProgressCallback progressCallback) async {
    Directory? downloadsDirectory = await getDownloadsDirectory();
    DateTime startTime = DateTime.now();

    List<int> bytes = await ftpConnect.fs.downloadFile(file,
        onReceiveProgress: (receivedBytes, totalBytes, percent) {
      DateTime currentTime = DateTime.now();
      Duration elapsed = currentTime.difference(startTime);
      double speed = receivedBytes / elapsed.inSeconds;
      print(
          "downloaded: $receivedBytes of $totalBytes, $percent% calculated ${receivedBytes / totalBytes * 100}%, speed: ${(speed / 1024 / 1024).toStringAsFixed(2)} MB/second");

      downloadedSize = receivedBytes;
      progressCallback(receivedBytes / file.info!.size!);
    });

    await File('${downloadsDirectory!.path}/${file.name}').writeAsBytes(bytes);

    downloadedFiles++;
    downloadedSize += file.info?.size ?? 0;

    snackBarCallback(file, 'Downloaded: ${file.name}');
    progressCallback(1.0);
  }
  bool isDownloading(FtpEntry entry) {
    return entry is FtpFile && _downloadQueue.contains(entry) || entry is FtpDirectory && _downloadQueue.contains(entry);
  }
}
