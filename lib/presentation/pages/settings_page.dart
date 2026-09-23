import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/cache_manager.dart';
import '../providers/settings_provider.dart';
import '../providers/download_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.actionCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.cacheCleared),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFDD644),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navSettings),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildSectionHeader(AppStrings.sectionReading),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.readerMode,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'webtoon',
                            label: Text(AppStrings.modeWebtoon),
                          ),
                          ButtonSegment(
                            value: 'manga',
                            label: Text(AppStrings.modeManga),
                          ),
                        ],
                        selected: {settings.readerMode},
                        onSelectionChanged: (selected) {
                          settings.setReaderMode(selected.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.mangaDirection,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'rtl',
                            label: Text(AppStrings.directionRTL),
                          ),
                          ButtonSegment(
                            value: 'ltr',
                            label: Text(AppStrings.directionLTR),
                          ),
                        ],
                        selected: {settings.mangaDirection},
                        onSelectionChanged: (selected) {
                          settings.setMangaDirection(selected.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text(AppStrings.portraitLock),
                trailing: Switch(
                  value: settings.isPortraitLocked,
                  onChanged: (val) {
                    settings.setPortraitLock(val);
                  },
                ),
              ),
              const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),
              _buildSectionHeader(AppStrings.sectionStorage),
              Builder(
                builder: (context) {
                  final downloadProvider = Provider.of<DownloadProvider?>(context);
                  if (downloadProvider == null) return const SizedBox.shrink();
                  return ListTile(
                    title: const Text(AppStrings.comicDownloads),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          StorageHelper.formatBytes(downloadProvider.totalDownloadsSizeBytes),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => context.push('/downloads'),
                          child: const Text(AppStrings.actionManage),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text(AppStrings.coverCache),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      settings.isCalculating
                          ? AppStrings.calculating
                          : StorageHelper.formatBytes(settings.thumbCacheBytes),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _showConfirmDialog(
                        context,
                        title: AppStrings.confirmDelete,
                        onConfirm: () => settings.clearThumbnailCache(),
                      ),
                      child: const Text(AppStrings.actionDelete),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text(AppStrings.readerCache),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      settings.isCalculating
                          ? AppStrings.calculating
                          : StorageHelper.formatBytes(settings.readerCacheBytes),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _showConfirmDialog(
                        context,
                        title: AppStrings.confirmDelete,
                        onConfirm: () => settings.clearReaderCache(),
                      ),
                      child: const Text(AppStrings.actionDelete),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text(AppStrings.totalCache),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      settings.isCalculating
                          ? AppStrings.calculating
                          : StorageHelper.formatBytes(settings.totalCacheBytes),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _showConfirmDialog(
                        context,
                        title: AppStrings.confirmDeleteAll,
                        onConfirm: () => settings.clearAllCache(),
                      ),
                      child: const Text(AppStrings.actionDeleteAll),
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
