import '../../../core/network/api_exception.dart';
import '../../../core/network/paged.dart';
import '../../../core/state/view_state.dart';
import '../data/supply_chain_repository.dart';
import '../models/supply_chain_models.dart';

class SupplyChainProvider extends LoadableNotifier {
  final SupplyChainRepository repository;

  SupplyChainProvider(this.repository);

  SupplyChainDashboard? _dashboard;
  Paged<ConsignmentCard> _consignments = Paged<ConsignmentCard>.empty();
  Paged<ChainAlert> _alerts = Paged<ChainAlert>.empty();
  Paged<ChainActivity> _activity = Paged<ChainActivity>.empty();
  List<Counterparty> _counterparties = const [];
  List<ChainStatusOption> _statuses = const [];
  String _filter = 'all';
  bool _loadingMore = false;
  bool _actionBusy = false;

  SupplyChainDashboard? get dashboard => _dashboard;

  List<ConsignmentCard> get consignments => _consignments.items;

  List<ChainAlert> get alerts => _alerts.items;

  List<ChainActivity> get activity => _activity.items;

  List<Counterparty> get counterparties => _counterparties;

  List<ChainStatusOption> get statuses => _statuses;

  String get filter => _filter;

  bool get loadingMore => _loadingMore;

  bool get actionBusy => _actionBusy;

  bool get hasMore => _consignments.hasMore;

  Future<void> loadDashboard({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _dashboard = await repository.dashboard();
      setStatus(ViewStatus.success);
    });
  }

  Future<void> loadConsignments({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _consignments = await repository.consignments(status: _filter, page: 1);
      setStatus(_consignments.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> loadMoreConsignments() async {
    if (_loadingMore || !_consignments.hasMore) return;

    _loadingMore = true;
    safeNotify();

    try {
      final next = await repository.consignments(
        status: _filter,
        page: _consignments.meta.page + 1,
      );
      _consignments = _consignments.merge(next);
    } catch (_) {
      _loadingMore = false;
    }

    _loadingMore = false;
    safeNotify();
  }

  void setFilter(String value) {
    if (_filter == value) return;
    _filter = value;
    loadConsignments();
  }

  Future<void> loadAlerts({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _alerts = await repository.alerts(page: 1);
      setStatus(_alerts.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> loadActivity({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _activity = await repository.activity(page: 1);
      setStatus(_activity.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> ensureMasters() async {
    if (_counterparties.isNotEmpty && _statuses.isNotEmpty) return;
    try {
      final results = await Future.wait([
        repository.counterparties(),
        repository.statuses(),
      ]);
      _counterparties = results[0] as List<Counterparty>;
      _statuses = results[1] as List<ChainStatusOption>;
      safeNotify();
    } on ApiException {
      return;
    }
  }

  Future<ConsignmentDetail?> consignment(String uniqueId) async {
    try {
      return await repository.consignment(uniqueId);
    } on ApiException {
      return null;
    }
  }

  Future<SupplyChainScanResult> scan({
    required String code,
    Map<String, dynamic>? location,
  }) {
    return repository.scan(code: code, location: location);
  }

  Future<String> performAction({
    required int scanId,
    required String action,
    int? user,
    String? comment,
    String? status,
  }) async {
    _actionBusy = true;
    safeNotify();
    try {
      final message = await repository.performAction(
        scanId: scanId,
        action: action,
        user: user,
        comment: comment,
        status: status,
      );
      await loadDashboard(refresh: true);
      return message;
    } finally {
      _actionBusy = false;
      safeNotify();
    }
  }
}
