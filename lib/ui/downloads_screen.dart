import 'package:flutter/material.dart';
import '../data/download_repository.dart';
import '../models/download_task.dart';
import '../models/download_format.dart';
import '../theme/app_theme.dart';

class DownloadsScreen extends StatefulWidget {
  final DownloadRepository repo;
  const DownloadsScreen({super.key, required this.repo});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late Future<List<DownloadTask>> _future = widget.repo.getAll();
  void _refresh() => setState(() => _future = widget.repo.getAll());

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
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
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
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, _) => Divider(height: 0.5, color: context.c.border),
      itemBuilder: (ctx, i) => row(ctx, tasks[i]),
    );
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
    return Padding(
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
        Icon(Icons.check_circle, size: 18, color: c.accent),
      ]),
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
        Icon(Icons.refresh, size: 16, color: c.text2),
      ]),
    );
  }
}
