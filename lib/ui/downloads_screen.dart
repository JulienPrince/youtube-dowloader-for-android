import 'dart:async';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../data/download_repository.dart';
import '../models/download_task.dart';
import '../models/download_format.dart';
import '../theme/app_theme.dart';

class DownloadsScreen extends StatefulWidget {
  final DownloadRepository repo;
  final Future<void> Function(DownloadTask task)? onRetry;
  const DownloadsScreen({super.key, required this.repo, this.onRetry});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late Future<List<DownloadTask>> _future = widget.repo.getAll();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Rafraîchit en continu pour voir la progression et le passage en "Terminés".
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final future = widget.repo.getAll();
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('Mes téléchargements', style: TextStyle(fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Tout effacer',
              onPressed: _clearAll,
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          ],
          bottom: TabBar(
            indicatorColor: c.accent,
            labelColor: c.text,
            unselectedLabelColor: c.muted,
            tabs: const [Tab(text: 'En cours'), Tab(text: 'Terminés'), Tab(text: 'Erreurs')],
          ),
        ),
        body: FutureBuilder<List<DownloadTask>>(
          future: _future,
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final all = snap.data!;
            bool isActive(DownloadTask t) =>
                t.status == DownloadStatus.queued ||
                t.status == DownloadStatus.downloading ||
                t.status == DownloadStatus.converting;
            return TabBarView(children: [
              _list(all.where(isActive).toList(), _activeRow),
              _list(all.where((t) => t.status == DownloadStatus.done).toList(), _doneRow),
              _list(all.where((t) => t.status == DownloadStatus.failed).toList(), _errorRow),
            ]);
          },
        ),
      ),
    );
  }

  Widget _list(List<DownloadTask> tasks, Widget Function(BuildContext, DownloadTask) row) {
    if (tasks.isEmpty) {
      return Center(child: Text('Rien ici', style: TextStyle(color: context.c.muted)));
    }
    final c = context.c;
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, _) => Divider(height: 0.5, color: c.border),
      itemBuilder: (ctx, i) {
        final t = tasks[i];
        return Dismissible(
          key: ValueKey(t.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: c.error.withValues(alpha: 0.12),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: Icon(Icons.delete_outline, color: c.error),
          ),
          onDismissed: (_) async {
            await widget.repo.delete(t.id);
            _refresh();
          },
          child: row(ctx, t),
        );
      },
    );
  }

  Future<void> _clearAll() async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: const Text('Tout effacer ?'),
        content: const Text('Efface la liste des téléchargements (les fichiers déjà '
            'enregistrés ne sont pas supprimés).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.repo.clearAll();
      _refresh();
    }
  }

  Future<void> _openFile(DownloadTask t) async {
    final path = t.localPath;
    if (path == null) return;
    final res = await OpenFilex.open(path);
    if (res.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lecture impossible : ${res.message}')));
    }
  }

  Widget _thumb(BuildContext ctx, DownloadTask t) {
    final c = ctx.c;
    return Container(
      width: 56, height: 35, alignment: Alignment.center,
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(8)),
      child: Icon(t.format == DownloadFormat.mp3 ? Icons.music_note : Icons.movie,
          size: 16, color: c.muted),
    );
  }

  Widget _activeRow(BuildContext ctx, DownloadTask t) {
    final c = ctx.c;
    final converting = t.status == DownloadStatus.converting;
    final queued = t.status == DownloadStatus.queued;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _thumb(ctx, t),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text, height: 1.3)),
            const SizedBox(height: 3),
            Text(t.format.name.toUpperCase(), style: TextStyle(fontSize: 11, color: c.muted)),
          ])),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 3,
            value: (converting || queued) ? null : t.progress,
            backgroundColor: c.border,
            valueColor: AlwaysStoppedAnimation(c.accent),
          ),
        ),
        const SizedBox(height: 6),
        Text(queued ? 'En file' : converting ? 'Conversion MP3…' : '${(t.progress * 100).round()}%',
            style: TextStyle(fontSize: 11, color: c.muted)),
      ]),
    );
  }

  Widget _doneRow(BuildContext ctx, DownloadTask t) {
    final c = ctx.c;
    return InkWell(
      onTap: () => _openFile(t),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          _thumb(ctx, t),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(height: 2),
            Text('${t.format.name.toUpperCase()} · ${t.localPath?.split('/').last ?? ''}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: c.muted)),
          ])),
          Icon(Icons.play_circle_outline, size: 20, color: c.accent),
        ]),
      ),
    );
  }

  Widget _errorRow(BuildContext ctx, DownloadTask t) {
    final c = ctx.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 52, height: 32, alignment: Alignment.center,
          decoration: BoxDecoration(
              color: c.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.error_outline, size: 18, color: c.error),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 2),
          Text(t.error ?? 'Échec', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: c.error)),
        ])),
        if (widget.onRetry != null)
          IconButton(
            icon: Icon(Icons.refresh, size: 18, color: c.text2),
            tooltip: 'Réessayer',
            onPressed: () async {
              await widget.repo.delete(t.id);
              _refresh();
              await widget.onRetry!(t);
            },
          ),
      ]),
    );
  }
}
