import '../../../core/network/api_exception.dart';
import '../../../core/network/paged.dart';
import '../../../core/state/view_state.dart';
import '../../inspector/models/case_models.dart';
import '../data/brand_repository.dart';
import '../models/brand_models.dart';

class BrandProvider extends LoadableNotifier {
  final BrandRepository repository;

  BrandProvider(this.repository);

  BrandDashboard? _dashboard;
  Paged<BrandProduct> _products = Paged<BrandProduct>.empty();
  Paged<BrandScan> _scans = Paged<BrandScan>.empty();
  Paged<BrandAlert> _alerts = Paged<BrandAlert>.empty();
  List<NetworkNode> _network = const [];
  List<MapPoint> _scanPoints = const [];
  String _search = '';
  String? _alertStatus;
  bool _loadingMore = false;

  BrandDashboard? get dashboard => _dashboard;

  List<BrandProduct> get products => _products.items;

  List<BrandScan> get scans => _scans.items;

  List<BrandAlert> get alerts => _alerts.items;

  List<NetworkNode> get network => _network;

  List<MapPoint> get scanPoints => _scanPoints;

  String get search => _search;

  String? get alertStatus => _alertStatus;

  bool get loadingMore => _loadingMore;

  bool get hasMoreProducts => _products.hasMore;

  Future<void> loadDashboard({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _dashboard = await repository.dashboard();
      setStatus(ViewStatus.success);
    });
  }

  Future<void> loadProducts({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _products = await repository.products(page: 1, search: _search);
      setStatus(_products.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> loadMoreProducts() async {
    if (_loadingMore || !_products.hasMore) return;

    _loadingMore = true;
    safeNotify();

    try {
      final next = await repository.products(
        page: _products.meta.page + 1,
        search: _search,
      );
      _products = _products.merge(next);
    } catch (_) {
      _loadingMore = false;
    }

    _loadingMore = false;
    safeNotify();
  }

  void setSearch(String value) {
    if (_search == value) return;
    _search = value;
    loadProducts();
  }

  Future<void> loadScans({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _scans = await repository.scans(page: 1);
      setStatus(_scans.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> loadAlerts({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _alerts = await repository.alerts(page: 1, status: _alertStatus);
      setStatus(_alerts.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  void setAlertStatus(String? value) {
    if (_alertStatus == value) return;
    _alertStatus = value;
    loadAlerts();
  }

  Future<void> loadNetwork({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _network = await repository.network();
      setStatus(_network.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> loadScanMap({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _scanPoints = await repository.scanMap();
      setStatus(_scanPoints.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<BrandProductDetail?> product(int id) async {
    try {
      return await repository.product(id);
    } on ApiException {
      return null;
    }
  }
}
