import 'package:flutter/material.dart';
import 'package:pure_ftp/pure_ftp.dart';

class FTPClientManager {
  bool isConnected = false;
  FtpClient? ftpConnect;
  ValueNotifier<List<FtpEntry>> entriesNotifier = ValueNotifier([]);
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  String? mainDirectory;
  Future<void> connect({
    String host = 'localhost',
    String port = '21',
    String user = 'anonymous',
    String pass = '',
  }) async {
    ftpConnect = FtpClient(
      socketInitOptions:
          FtpSocketInitOptions(host: host, port: int.parse(port)),
      authOptions: FtpAuthOptions(username: user, password: pass),
      logCallback: (message) {
        print(message);
      },
    );
    try {
      await ftpConnect!.connect();
      await ftpConnect!.socket.setTransferType(FtpTransferType.binary);
      isConnected = true;
      mainDirectory = ftpConnect!.currentDirectory.path;
      await listDirectory();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await ftpConnect?.disconnect();
    isConnected = false;
  }

  Future<void> checkConnection() async {
    isConnected = await ftpConnect!.isConnected();
  }

  Future<void> listDirectory([FtpDirectory? dir]) async {
    isLoadingNotifier.value = true;
    try {
      await checkConnection();

      if (dir != null) {
        bool result = await ftpConnect!.changeDirectory(dir.path);
        if (!result) {
          print('Failed to change directory');
        }
      }

      print("directory: ${ftpConnect!.currentDirectory}");
      final dirEntries = await ftpConnect!.fs.listDirectory();
      print("list: $dirEntries");

      dirEntries.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) {
          return -1;
        } else if (!a.isDirectory && b.isDirectory) {
          return 1;
        } else {
          return a.name.compareTo(b.name);
        }
      });

      if (dir != null && dir.path != mainDirectory) {
        dirEntries.insert(
          0,
          FtpDirectory(path: '..', client: ftpConnect!),
        );
      }

      entriesNotifier.value = dirEntries;
    } finally {
      isLoadingNotifier.value = false;
    }
  }
}
