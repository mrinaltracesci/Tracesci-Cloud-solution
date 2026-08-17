import '../../../core/network/paged.dart';
import '../../../core/state/view_state.dart';
import '../data/alert_repository.dart';
import '../models/alert_item.dart';

class AlertProvider extends LoadableNotifier {
  final AlertRepository repository;

  AlertProvider(this.repository);

  Paged<AlertItem> _page = Paged<AlertItem>.empty();
  bool _canSeeProducts = false;
  int _mineCount = 0;
  int _productCount = 0;
  String? _scope;
  bool _loadingMore = false;

  List<AlertItem> get alerts => _page.items;

  bool get canSeeProducts => _canSeeProducts;

  int get mineCount => _mineCount;

  int get productCount => _productCount;

  String? get scope => _scope;

  bool get hasMore => _page.hasMore;

  bool get loadingMore => _loadingMore;

  Future<void> load({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      final (page, feed) = await repository.feed(page: 1, scope: _scope);
      _page = page;
      _canSeeProducts = feed.canSeeProducts;
      _mineCount = feed.mineCount;
      _productCount = feed.productCount;
      setStatus(_page.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_page.hasMore) return;

    _loadingMore = true;
    safeNotify();

    try {
      final (next, _) = await repository.feed(
        page: _page.meta.page + 1,
        scope: _scope,
      );
      _page = _page.merge(next);
    } catch (_) {
      _loadingMore = false;
    }

    _loadingMore = false;
    safeNotify();
  }

  void setScope(String? value) {
    if (_scope == value) return;
    _scope = value;
    load();
  }
}
