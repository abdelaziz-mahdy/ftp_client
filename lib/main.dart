import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pure_ftp/pure_ftp.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FTPHomePage(),
    );
  }
}

class FTPHomePage extends StatefulWidget {
  @override
  _FTPHomePageState createState() => _FTPHomePageState();
}

class _FTPHomePageState extends State<FTPHomePage> {
  final _formKey = GlobalKey<FormState>();
  String host = '192.168.1.5';
  String port = '15114';
  String user = 'anonymous';
  String pass = '';
  bool isConnected = false;
  FtpClient? ftpConnect;
  List<FtpEntry> entries = [];
  bool _isLoading = false;
  Future<void> _connectToFTP() async {
    setState(() {
      _isLoading = true;
    });
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
      setState(() {
        isConnected = true;
        _isLoading = false;
      });
      _listDirectory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to connect, $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> checkConnection() async {
    bool result = await ftpConnect!.isConnected();
    setState(() {
      isConnected = result;
    });
  }

  Future<void> _listDirectory([FtpDirectory? dir]) async {
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
    // Sort directories first
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

    setState(() {
      entries = dirEntries;
    });
  }

  Future<void> _downloadFile(FtpFile file) async {
    await checkConnection();
    try {
      Directory? downloadsDirectory = await getDownloadsDirectory();
      print("file size: ${file.info!.size ?? ""}");

      // Record the start time
      DateTime startTime = DateTime.now();

      List<int> bytes = await ftpConnect!.fs.downloadFile(file,
          onReceiveProgress: (bytes, total, p) {
        // Calculate elapsed time
        DateTime currentTime = DateTime.now();
        Duration elapsed = currentTime.difference(startTime);

        // Calculate download speed in bytes per second
        double speed = bytes / elapsed.inSeconds;

        // Print progress and speed
        print(
            "downloaded: $bytes of $total, $p% calculated ${bytes / total * 100}%, speed: ${(speed / 1024 / 1024).toStringAsFixed(2)} MB/second");
      });

      File('${downloadsDirectory!.path}/${file.name}').writeAsBytes(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download: ${file.name} $e')));
      }
    }
  }

  @override
  void dispose() {
    ftpConnect?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: isConnected
            ? IconButton(
                icon: Icon(Icons.close),
                onPressed: () async {
                  await ftpConnect?.disconnect();
                  setState(() {
                    isConnected = false;
                  });
                },
              )
            : null,
        title: Text('FTP Connect App'),
        actions: [
          isConnected
              ? IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () async {
                    _listDirectory();
                  },
                )
              : Container(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isConnected ? _buildDirectoryList() : _buildConnectForm(),
      ),
    );
  }

  Widget _buildConnectForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Host'),
            onChanged: (value) => host = value,
            initialValue: host,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Port'),
            initialValue: port,
            onChanged: (value) => port = value,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Username'),
            initialValue: 'anonymous',
            onChanged: (value) => user = value,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Password'),
            onChanged: (value) => pass = value,
            obscureText: true,
          ),
          SizedBox(height: 20),
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _connectToFTP,
                  child: Text('Connect'),
                ),
        ],
      ),
    );
  }

  Widget _buildDirectoryList() {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.name == null) {
          return Container();
        } else {
          return ListTile(
            leading: Icon(entry.isDirectory ? Icons.folder : Icons.file_copy),
            title: Text(entry.name!),
            onTap: () async {
              if (entry.isDirectory) {
                if (entry.name == '..') {
                  await ftpConnect!.changeDirectoryUp();
                  _listDirectory();
                } else {
                  _listDirectory(entry as FtpDirectory);
                }
              } else {
                _showDownloadDialog(entry as FtpFile);
              }
            },
          );
        }
      },
    );
  }

  void _showDownloadDialog(FtpFile file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Download File'),
          content: Text('Do you want to download ${file.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadFile(file);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
