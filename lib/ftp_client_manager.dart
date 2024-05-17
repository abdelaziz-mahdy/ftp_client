import 'package:pure_ftp/pure_ftp.dart';

class FTPClientManager {
  String host = '192.168.1.5';
  String port = '15114';
  String user = 'anonymous';
  String pass = '';
  bool isConnected = false;
  FtpClient? ftpConnect;
  List<FtpEntry> entries = [];

  Future<void> connect() async {
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
      isConnected = true;
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

    if (dir != null && dir.path != '/') {
      dirEntries.insert(
        0,
        FtpDirectory(path: '..', client: ftpConnect!),
      );
    }

    entries = dirEntries;
  }
}
