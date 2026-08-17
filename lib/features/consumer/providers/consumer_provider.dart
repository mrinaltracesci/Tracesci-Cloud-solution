import '../../../core/network/api_exception.dart';
import '../../../core/network/paged.dart';
import '../../../core/state/view_state.dart';
import '../data/consumer_repository.dart';
import '../models/consumer_models.dart';

class ConsumerProvider extends LoadableNotifier {
  final ConsumerRepository repository;

  ConsumerProvider(this.repository);

  ConsumerHome? _home;
  Paged<ScanCard> _scans = Paged<ScanCard>.empty();
  Paged<ReportItem> _reports = Paged<ReportItem>.empty();
  List<AppNotification> _notifications = const [];
  bool _loadingMore = false;
  String? _genuineFilter;
  String _search = '';

  ConsumerHome? get home => _home;

  List<ScanCard> get scans => _scans.items;

  List<ReportItem> get reports => _reports.items;

  List<AppNotification> get notifications => _notifications;

  bool get loadingMore => _loadingMore;

  bool get hasMoreScans => _scans.hasMore;

  String? get genuineFilter => _genuineFilter;

  String get search => _search;

  Future<void> loadHome({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _home = await repository.home();
      setStatus(ViewStatus.success);
    });
  }

  Future<void> loadScans({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _scans = await repository.scans(
        page: 1,
        genuine: _genuineFilter,
        search: _search,
      );
      setStatus(_scans.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> loadMoreScans() async {
    if (_loadingMore || !_scans.hasMore) return;

    _loadingMore = true;
    safeNotify();

    try {
      final next = await repository.scans(
        page: _scans.meta.page + 1,
        genuine: _genuineFilter,
        search: _search,
      );
      _scans = _scans.merge(next);
    } catch (_) {
      _loadingMore = false;
    }

    _loadingMore = false;
    safeNotify();
  }

  void setGenuineFilter(String? value) {
    if (_genuineFilter == value) return;
    _genuineFilter = value;
    loadScans();
  }

  void setSearch(String value) {
    if (_search == value) return;
    _search = value;
    loadScans();
  }

  Future<void> loadReports({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _reports = await repository.reports(page: 1);
      setStatus(_reports.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _notifications = await repository.notifications();
      setStatus(
        _notifications.isEmpty ? ViewStatus.empty : ViewStatus.success,
      );
    });
  }

  Future<ScanDetail?> scanDetail(int scanId) async {
    try {
      return await repository.scanDetail(scanId);
    } on ApiException {
      return null;
    }
  }
}
