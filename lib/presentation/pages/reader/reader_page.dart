import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/database/database_helper.dart';
import '../../providers/reader_provider.dart';
import '../../widgets/reader_overlay_widget.dart';
import 'reader_bottom_bar.dart';
import 'reader_manga.dart';
import 'reader_state_card.dart';
import 'reader_retryable_image.dart';

const _kAccent = Color(0xFFFDD644);

class ReaderPage extends StatefulWidget {
  final String chapterUrl;
  final bool fromDetail;

  const ReaderPage(
      {super.key, required this.chapterUrl, this.fromDetail = false});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  // ── Persistent settings cache across chapter navigations ──────────────────
  static String? _cachedReaderMode;
  static bool? _cachedIsRTL;
  static bool? _cachedShowOverlay;
  static double? _cachedBrightness;

  Timer? _loadingTimer;
  bool _isTimeout = false;
  late ReaderProvider _readerProvider;
  late ScrollController _scrollController;
  late PageController _pageController;

  bool _showControls = true;
  bool _isWebtoonMode = true;
  bool _isRTL = false;
  bool _showInfoOverlay = true;
  double _brightnessFilter = 0.0;
  int _currentPage = 0;

  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (_cachedReaderMode != null) {
      _isWebtoonMode = (_cachedReaderMode == 'webtoon');
    }
    if (_cachedIsRTL != null) _isRTL = _cachedIsRTL!;
    if (_cachedShowOverlay != null) _showInfoOverlay = _cachedShowOverlay!;
    if (_cachedBrightness != null) _brightnessFilter = _cachedBrightness!;

    if (_cachedReaderMode == null ||
        _cachedIsRTL == null ||
        _cachedShowOverlay == null ||
        _cachedBrightness == null) {
      _loadSavedSettings();
    }

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _pageController = PageController();
    _readerProvider = context.read<ReaderProvider>();
    _readerProvider.addListener(_onProviderChanged);
    _startLoad();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    final progress = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    if ((progress - _scrollProgress).abs() > 0.005) {
      setState(() => _scrollProgress = progress);
    }
  }

  Future<void> _loadSavedSettings() async {
    final db = DatabaseHelper.instance;
    final savedMode = await db.getSetting('reader_mode');
    final savedRtl = await db.getSetting('reader_direction');
    final savedOverlay = await db.getSetting('reader_show_overlay');
    final savedBrightness = await db.getSetting('reader_brightness_filter');
    final savedOrientation = await db.getSetting('reader_orientation_lock');

    if (savedOrientation == 'portrait') {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    if (mounted) {
      setState(() {
        if (savedMode != null) {
          _cachedReaderMode = savedMode;
          _isWebtoonMode = (savedMode == 'webtoon');
        }
        if (savedRtl != null) {
          _cachedIsRTL = (savedRtl == 'rtl');
          _isRTL = _cachedIsRTL!;
        }
        if (savedOverlay != null) {
          _cachedShowOverlay = (savedOverlay == 'true');
          _showInfoOverlay = _cachedShowOverlay!;
        }
        if (savedBrightness != null) {
          _cachedBrightness = double.tryParse(savedBrightness) ?? 0.0;
          _brightnessFilter = _cachedBrightness!;
        }
      });
    }
  }

  void _toggleRTL() {
    setState(() => _isRTL = !_isRTL);
    _cachedIsRTL = _isRTL;
    DatabaseHelper.instance
        .setSetting('reader_direction', _isRTL ? 'rtl' : 'ltr');
  }

  void _toggleInfoOverlay() {
    setState(() => _showInfoOverlay = !_showInfoOverlay);
    _cachedShowOverlay = _showInfoOverlay;
    DatabaseHelper.instance.setSetting(
        'reader_show_overlay', _showInfoOverlay ? 'true' : 'false');
  }

  void _onBrightnessChanged(double value) {
    setState(() => _brightnessFilter = value);
    _cachedBrightness = value;
    DatabaseHelper.instance
        .setSetting('reader_brightness_filter', value.toStringAsFixed(2));
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    SystemChrome.setEnabledSystemUIMode(
      _showControls ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _readerProvider.removeListener(_onProviderChanged);
    _scrollController.removeListener(_onScroll);
    _loadingTimer?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startLoad() {
    setState(() => _isTimeout = false);
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _readerProvider.isLoading) {
        setState(() => _isTimeout = true);
      }
    });
    _readerProvider.fetchReaderImages(widget.chapterUrl);
  }

  void _onProviderChanged() {
    if (!_readerProvider.isLoading) _loadingTimer?.cancel();
  }

  String get _actIndexStr => widget.chapterUrl
      .split('/')
      .lastWhere((e) => e.isNotEmpty, orElse: () => '');

  String _chapterLabel(ReaderProvider provider) {
    if (provider.detailComic != null) {
      final chapters = provider.detailComic!.chapters;
      final match =
          chapters.where((c) => c.link == widget.chapterUrl).firstOrNull;
      if (match != null) return match.title;
    }
    return 'Chapter $_actIndexStr';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 640;

    return Scaffold(
      appBar: _showControls
          ? ReaderAppBar(
              chapterUrl: widget.chapterUrl,
              isTablet: isTablet,
              isWebtoonMode: _isWebtoonMode,
              isRTL: _isRTL,
              showInfoOverlay: _showInfoOverlay,
              onToggleMode: () {
                setState(() => _isWebtoonMode = !_isWebtoonMode);
                _cachedReaderMode = _isWebtoonMode ? 'webtoon' : 'manga';
                DatabaseHelper.instance
                    .setSetting('reader_mode', _cachedReaderMode!);
              },
              onToggleRTL: _toggleRTL,
              onToggleInfoOverlay: _toggleInfoOverlay,
              chapterLabelBuilder: _chapterLabel,
            )
          : null,
      body: Stack(
        children: [
          // Main content
          RefreshIndicator(
            onRefresh: () async => _startLoad(),
            child: Consumer<ReaderProvider>(
              builder: (context, provider, child) {
                if (_isTimeout) {
                  return ReaderStateCard(
                    icon: Icons.signal_cellular_connected_no_internet_4_bar_rounded,
                    title: 'Jaringan Lambat / Stuck',
                    subtitle:
                        'Pemuatan melebihi 10 detik.\nCoba periksa koneksi internetmu.',
                    onRetry: _startLoad,
                  );
                }
                if (provider.isLoading) return _buildLoadingState();
                if (provider.readerImages.isEmpty) {
                  return ReaderStateCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Gagal Memuat Chapter',
                    subtitle:
                        'Tidak ada gambar ditemukan atau\nterjadi kesalahan saat mengambil data.',
                    onRetry: _startLoad,
                  );
                }

                if (!_isWebtoonMode) {
                  return MangaReader(
                    provider: provider,
                    pageController: _pageController,
                    isRTL: _isRTL,
                    currentPage: _currentPage,
                    onToggleControls: _toggleControls,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                  );
                }

                // Webtoon mode
                return Scrollbar(
                  controller: _scrollController,
                  interactive: true,
                  thickness: 6.0,
                  radius: const Radius.circular(3.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: provider.readerImages.length,
                        cacheExtent: 600.0,
                        itemBuilder: (context, index) {
                          return RetryableImage(
                            imageUrl: provider.readerImages[index],
                            pageIndex: index + 1,
                            onTap: _toggleControls,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Webtoon scroll progress bar
          if (_isWebtoonMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _scrollProgress > 0.0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: LinearProgressIndicator(
                  value: _scrollProgress,
                  minHeight: 3,
                  backgroundColor: Colors.white10,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_kAccent),
                ),
              ),
            ),

          // Dark tint brightness overlay
          if (_brightnessFilter > 0.0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: _brightnessFilter),
                ),
              ),
            ),

          // Clock & battery overlay
          if (_showInfoOverlay)
            const Positioned(
              bottom: 16,
              right: 16,
              child: ReaderOverlayWidget(),
            ),
        ],
      ),
      bottomNavigationBar: _showControls
          ? ReaderBottomBar(
              chapterUrl: widget.chapterUrl,
              fromDetail: widget.fromDetail,
              isTablet: isTablet,
              brightnessFilter: _brightnessFilter,
              onBrightnessChanged: _onBrightnessChanged,
              chapterLabelBuilder: _chapterLabel,
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Memuat chapter...',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mohon tunggu sebentar',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
