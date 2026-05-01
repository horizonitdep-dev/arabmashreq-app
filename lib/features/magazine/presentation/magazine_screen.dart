import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/magazine_issue_model.dart';
import '../../../shared/services/api_exception.dart';
import '../../../shared/services/service_providers.dart';
import '../../../shared/widgets/loading_list.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/states/app_state_view.dart';

final magazineIssuesProvider = FutureProvider<List<MagazineIssueModel>>((ref) {
  return ref.read(backendServiceProvider).fetchMagazineIssues();
});

class MagazineScreen extends ConsumerWidget {
  const MagazineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(magazineIssuesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المجلة الرقمية')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(magazineIssuesProvider),
        child: async.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  AppStateView(
                    icon: Icons.menu_book_outlined,
                    title: 'لا توجد أعداد منشورة',
                    message: 'سيتم عرض أعداد المجلة الرقمية هنا بعد نشرها.',
                  ),
                ],
              );
            }

            final featured = items.where((e) => e.isFeatured).toList();
            final normal = items.where((e) => !e.isFeatured).toList();

            return FutureBuilder<LocalStorage>(
              future: ref.read(localStorageProvider.future),
              builder: (context, snapshot) {
                final downloaded =
                    snapshot.data?.getDownloadedMagazineFiles() ??
                        const <int, String>{};

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  children: [
                    if (featured.isNotEmpty) ...[
                      const SectionHeader(title: 'العدد المميز'),
                      const SizedBox(height: 8),
                      ...featured.map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _IssueCard(
                            issue: issue,
                            isDownloaded: downloaded.containsKey(issue.id),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MagazineIssueDetailsScreen(issue: issue),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    SectionHeader(title: 'كل الأعداد (${items.length})'),
                    const SizedBox(height: 8),
                    ...normal.map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _IssueCard(
                          issue: issue,
                          isDownloaded: downloaded.containsKey(issue.id),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MagazineIssueDetailsScreen(issue: issue),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: LoadingList(itemHeight: 180, count: 4),
          ),
          error: (_, __) => ListView(
            children: const [
              SizedBox(height: 120),
              AppStateView(
                icon: Icons.error_outline,
                title: 'تعذر تحميل المجلة',
                message: 'تحقق من الاتصال وحاول مرة أخرى.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MagazineIssueDetailsScreen extends ConsumerStatefulWidget {
  const MagazineIssueDetailsScreen({super.key, required this.issue});

  final MagazineIssueModel issue;

  @override
  ConsumerState<MagazineIssueDetailsScreen> createState() =>
      _MagazineIssueDetailsScreenState();
}

class _MagazineIssueDetailsScreenState
    extends ConsumerState<MagazineIssueDetailsScreen> {
  bool _busy = false;
  bool _backgroundDownloading = false;
  double _progress = 0;
  String? _downloadedPath;

  @override
  void initState() {
    super.initState();
    _loadDownloadedPath();
  }

  Future<void> _loadDownloadedPath() async {
    final storage = await ref.read(localStorageProvider.future);
    final map = storage.getDownloadedMagazineFiles();
    final path = map[widget.issue.id];
    if (path == null || path.trim().isEmpty) return;

    final file = File(path);
    if (await file.exists() && mounted) {
      setState(() => _downloadedPath = path);
    }
  }

  Future<File> _resolveFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/magazines');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final safeSlug = widget.issue.slug.trim().isEmpty
        ? 'issue-${widget.issue.id}'
        : widget.issue.slug;
    return File('${folder.path}/$safeSlug.pdf');
  }

  Future<void> _download({
    required bool openAfter,
    bool background = false,
  }) async {
    if (_busy || _backgroundDownloading) return;

    final url = widget.issue.pdfUrl;
    if (url == null || url.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ملف PDF غير متوفر لهذا العدد.')),
      );
      return;
    }

    setState(() {
      _busy = !background;
      _backgroundDownloading = background;
      _progress = 0;
    });

    try {
      final file = await _resolveFilePath();
      final alreadyExists = await file.exists();

      if (!alreadyExists) {
        await ref.read(backendServiceProvider).trackMagazineDownload(
              widget.issue.id,
            );
        await ref.read(backendServiceProvider).downloadFile(
              url: url,
              savePath: file.path,
              onReceiveProgress: (received, total) {
                if (!mounted) return;
                if (total > 0) {
                  setState(() => _progress = received / total);
                }
              },
            );
      }

      final storage = await ref.read(localStorageProvider.future);
      await storage.setMagazineDownloadedPath(widget.issue.id, file.path);

      if (!mounted) return;
      setState(() => _downloadedPath = file.path);

      if (openAfter) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MagazinePdfViewerScreen(
              title: widget.issue.title,
              localFilePath: file.path,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تنزيل العدد بنجاح.')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تنزيل الملف حالياً.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _backgroundDownloading = false;
          _progress = 0;
        });
      }
    }
  }

  Future<void> _startBackgroundDownload() async {
    if (_busy || _backgroundDownloading) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بدأ التنزيل وسيستمر بالخلفية داخل التطبيق.'),
        ),
      );
    }

    unawaited(_download(openAfter: false, background: true));
  }

  Future<void> _deleteDownloadedFile() async {
    final path = _downloadedPath;
    if (path == null || path.trim().isEmpty) return;

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }

      final storage = await ref.read(localStorageProvider.future);
      await storage.removeMagazineDownloadedPath(widget.issue.id);

      if (!mounted) return;
      setState(() => _downloadedPath = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الملف المنزّل من الجهاز.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حذف الملف حالياً.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final dateText = issue.publishDate == null
        ? null
        : DateFormat('yyyy/MM/dd').format(issue.publishDate!);

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل العدد')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 110,
                    height: 145,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).dividerColor.withOpacity(0.2),
                      image: issue.coverImage != null
                          ? DecorationImage(
                              image: NetworkImage(issue.coverImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: issue.coverImage == null
                        ? const Icon(Icons.menu_book_outlined, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        if ((issue.issueNumber ?? '').trim().isNotEmpty)
                          Text('رقم العدد: ${issue.issueNumber}'),
                        if (dateText != null) Text('تاريخ النشر: $dateText'),
                        if (issue.pageCount != null)
                          Text('عدد الصفحات: ${issue.pageCount}'),
                        if (issue.fileSizeMb != null)
                          Text(
                            'حجم الملف: ${issue.fileSizeMb!.toStringAsFixed(2)} MB',
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (issue.isFeatured)
                              const Chip(label: Text('عدد مميز')),
                            if (_downloadedPath != null)
                              const Chip(
                                label: Text('تم التنزيل'),
                                avatar: Icon(Icons.download_done, size: 16),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if ((issue.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  issue.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_busy || _backgroundDownloading)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_backgroundDownloading
                        ? 'التنزيل يعمل بالخلفية...'
                        : 'جاري التحميل...'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      color: AppColors.gold,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_busy || _backgroundDownloading)
                      ? null
                      : () => _download(openAfter: true),
                  icon: const Icon(Icons.chrome_reader_mode_outlined),
                  label: const Text('قراءة داخل التطبيق'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_busy || _backgroundDownloading)
                      ? null
                      : _startBackgroundDownload,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('تنزيل للقراءة بدون إنترنت'),
                ),
              ),
            ],
          ),
          if (_downloadedPath != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_busy || _backgroundDownloading)
                        ? null
                        : _deleteDownloadedFile,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('حذف الملف المنزّل'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MagazinePdfViewerScreen extends StatefulWidget {
  const MagazinePdfViewerScreen({
    super.key,
    required this.title,
    required this.localFilePath,
  });

  final String title;
  final String localFilePath;

  @override
  State<MagazinePdfViewerScreen> createState() => _MagazinePdfViewerScreenState();
}

class _MagazinePdfViewerScreenState extends State<MagazinePdfViewerScreen> {
  late final PdfControllerPinch _controller;
  int _currentPage = 1;
  int _totalPages = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.localFilePath),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _totalPages > 0
                  ? 'صفحة $_currentPage من $_totalPages'
                  : 'جاري تحميل الملف...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: _errorMessage != null
          ? AppStateView(
              icon: Icons.picture_as_pdf_outlined,
              title: 'تعذر فتح ملف PDF',
              message: _errorMessage!,
            )
          : PdfViewPinch(
              controller: _controller,
              onDocumentLoaded: (document) {
                if (!mounted) return;
                setState(() => _totalPages = document.pagesCount);
              },
              onPageChanged: (page) {
                if (!mounted) return;
                setState(() => _currentPage = page);
              },
              onDocumentError: (error) {
                if (!mounted) return;
                setState(() => _errorMessage = error.toString());
              },
            ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.onTap,
    required this.isDownloaded,
  });

  final MagazineIssueModel issue;
  final VoidCallback onTap;
  final bool isDownloaded;

  @override
  Widget build(BuildContext context) {
    final dateText = issue.publishDate == null
        ? null
        : DateFormat('yyyy/MM/dd').format(issue.publishDate!);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 86,
                height: 114,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  image: issue.coverImage != null
                      ? DecorationImage(
                          image: NetworkImage(issue.coverImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: issue.coverImage == null
                    ? const Icon(Icons.menu_book_outlined)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (issue.isFeatured)
                          const Padding(
                            padding: EdgeInsetsDirectional.only(start: 6),
                            child: Icon(
                              Icons.star_rounded,
                              color: AppColors.gold,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if ((issue.issueNumber ?? '').trim().isNotEmpty)
                      Text(
                        issue.issueNumber!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (dateText != null)
                      Text(
                        dateText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if ((issue.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        issue.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'تحميلات: ${issue.downloadCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        if (isDownloaded)
                          const Icon(
                            Icons.download_done_rounded,
                            size: 18,
                            color: AppColors.gold,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
