import 'package:flutter/material.dart';
import '../data/download_repository.dart';

class DownloadsScreen extends StatelessWidget {
  final DownloadRepository repo;
  const DownloadsScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Téléchargements')),
      body: const Center(child: Text('Aucun téléchargement')),
    );
  }
}
