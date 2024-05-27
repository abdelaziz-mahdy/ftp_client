import 'package:flutter/material.dart';
import 'package:ftp_client/controllers/download_manager.dart';
import 'package:ftp_client/widgets/file_tile.dart';
import 'package:ftp_client/controllers/ftp_client_manager.dart';
import 'package:pure_ftp/pure_ftp.dart';
import 'file_tile.dart';

class DirectoryList extends StatelessWidget {
  final FTPClientManager ftpClientManager;
  final DownloadManager downloadManager;

  const DirectoryList({
    super.key,
    required this.ftpClientManager,
    required this.downloadManager,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ftpClientManager.isLoadingNotifier,
      builder: (context, isLoading, _) {
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return ValueListenableBuilder(
            valueListenable: ftpClientManager.entriesNotifier,
            builder: (context, entries, _) {
              if (entries.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return FileTile(
                      entry: entry,
                      ftpClientManager: ftpClientManager,
                      downloadManager: downloadManager,
                    );
                  },
                );
              }
            },
          );
        }
      },
    );
  }
}
