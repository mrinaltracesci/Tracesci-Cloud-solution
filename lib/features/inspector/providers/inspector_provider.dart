import '../../../core/network/api_exception.dart';
import '../../../core/network/paged.dart';
import '../../../core/state/view_state.dart';
import '../data/inspector_repository.dart';
import '../models/case_models.dart';

class InspectorProvider extends LoadableNotifier {
  final InspectorRepository repository;

  InspectorProvider(this.repository);

  InspectorDashboard? _dashboard;
  Paged<CaseCard> _cases = Paged<CaseCard>.empty();
  List<MapPoint> _points = const [];
  String? _statusFilter;
  String? _typeFilter;
  String _search = '';
  bool _loadingMore = false;
  bool _actionBusy = false;

  InspectorDashboard? get dashboard => _dashboard;

  List<CaseCard> get cases => _cases.items;

  List<MapPoint> get points => _points;

  String? get statusFilter => _statusFilter;

  String? get typeFilter => _typeFilter;

  String get search => _search;

  bool get loadingMore => _loadingMore;

  bool get actionBusy => _actionBusy;

  bool get hasMore => _cases.hasMore;

  Future<void> loadDashboard({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _dashboard = await repository.dashboard();
      setStatus(ViewStatus.success);
    });
  }

  Future<void> loadCases({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _cases = await repository.cases(
        page: 1,
        status: _statusFilter,
        type: _typeFilter,
        search: _search,
      );
      setStatus(_cases.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> loadMoreCases() async {
    if (_loadingMore || !_cases.hasMore) return;

    _loadingMore = true;
    safeNotify();

    try {
      final next = await repository.cases(
        page: _cases.meta.page + 1,
        status: _statusFilter,
        type: _typeFilter,
        search: _search,
      );
      _cases = _cases.merge(next);
    } catch (_) {
      _loadingMore = false;
    }

    _loadingMore = false;
    safeNotify();
  }

  void setStatusFilter(String? value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    loadCases();
  }

  void setTypeFilter(String? value) {
    if (_typeFilter == value) return;
    _typeFilter = value;
    loadCases();
  }

  void setSearch(String value) {
    if (_search == value) return;
    _search = value;
    loadCases();
  }

  Future<void> loadMap({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _points = await repository.map(status: _statusFilter);
      setStatus(_points.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<CaseDetail?> caseDetail(int id) async {
    try {
      return await repository.caseDetail(id);
    } on ApiException {
      return null;
    }
  }

  Future<String> updateCase({
    required int id,
    required String status,
    required String comments,
  }) async {
    _actionBusy = true;
    safeNotify();
    try {
      final message = await repository.updateCase(
        id: id,
        status: status,
        comments: comments,
      );
      await loadCases(refresh: true);
      return message;
    } finally {
      _actionBusy = false;
      safeNotify();
    }
  }

  Future<SeizeResult> seize({
    required String type,
    required String code,
  }) async {
    _actionBusy = true;
    safeNotify();
    try {
      return await repository.seize(type: type, code: code);
    } finally {
      _actionBusy = false;
      safeNotify();
    }
  }
}
