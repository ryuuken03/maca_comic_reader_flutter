import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/constants.dart';
import '../../providers/library_provider.dart';
import '../../providers/download_provider.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import 'collection_bookmark_tab.dart';
import 'collection_downloads_tab.dart';

class CollectionPage extends StatefulWidget {
  final int initialTabIndex;

  const CollectionPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(_handleTabSelection);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LibraryProvider>().fetchBookmarks();
      }
    });
  }

  void _handleTabSelection() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(CollectionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex.clamp(0, 1));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider>();
    final downloadProvider = context.watch<DownloadProvider>();
    final hasBookmarks = libraryProvider.bookmarks.isNotEmpty;
    final hasDownloads = downloadProvider.downloadedChapters.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navCollection),
        actions: [
          if (_tabController.index == 0 && hasBookmarks)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: AppStrings.deleteAllSaved,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => DeleteConfirmationDialog(
                    title: AppStrings.confirmDeleteSaved,
                    content: AppStrings.confirmDeleteAllSavedContent,
                    onConfirm: () =>
                        context.read<LibraryProvider>().clearBookmarks(),
                  ),
                );
              },
            ),
          if (_tabController.index == 1 && hasDownloads)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: AppStrings.actionDeleteAll,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => DeleteConfirmationDialog(
                    title: AppStrings.confirmDeleteAllDownloads,
                    content:
                        'Apakah Anda yakin ingin menghapus semua komik yang diunduh?',
                    onConfirm: () => downloadProvider.clearAllDownloads(),
                  ),
                );
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF1E1E1E),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppConstants.primaryColor,
              indicatorWeight: 3,
              labelColor: AppConstants.primaryColor,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  text: hasBookmarks
                      ? '${AppStrings.navBookmark} (${libraryProvider.bookmarks.length})'
                      : AppStrings.navBookmark,
                ),
                Tab(
                  text: hasDownloads
                      ? '${AppStrings.navDownloads} (${downloadProvider.downloadedChapters.length})'
                      : AppStrings.navDownloads,
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CollectionBookmarkTab(),
          CollectionDownloadsTab(),
        ],
      ),
    );
  }
}
