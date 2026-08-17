import '../../../core/network/paged.dart';
import '../../../core/state/view_state.dart';
import '../data/reward_repository.dart';
import '../models/reward_models.dart';

class RewardProvider extends LoadableNotifier {
  final RewardRepository repository;

  RewardProvider(this.repository);

  RewardSummary? _summary;
  List<RewardScheme> _catalog = const [];
  Paged<LedgerEntry> _ledger = Paged<LedgerEntry>.empty();
  Paged<RewardOrder> _orders = Paged<RewardOrder>.empty();
  bool _actionBusy = false;

  RewardSummary? get summary => _summary;

  List<RewardScheme> get catalog => _catalog;

  List<LedgerEntry> get ledger => _ledger.items;

  List<RewardOrder> get orders => _orders.items;

  bool get actionBusy => _actionBusy;

  double get balance => _summary?.balance ?? 0;

  Future<void> loadSummary({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _summary = await repository.summary();
      setStatus(ViewStatus.success);
    });
  }

  Future<void> loadCatalog({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _catalog = await repository.catalog();
      setStatus(_catalog.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> loadLedger({bool refresh = false, String? type}) async {
    await guard(refreshing: refresh, () async {
      _ledger = await repository.ledger(page: 1, type: type);
      setStatus(_ledger.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<void> loadOrders({bool refresh = false}) async {
    await guard(refreshing: refresh, () async {
      _orders = await repository.orders(page: 1);
      setStatus(_orders.isEmpty ? ViewStatus.empty : ViewStatus.success);
    });
  }

  Future<RedeemResult> redeemCoupon(String code, {int? scanId}) async {
    _actionBusy = true;
    safeNotify();
    try {
      final result = await repository.redeemCoupon(
        couponCode: code,
        scanId: scanId,
      );
      await loadSummary(refresh: true);
      return result;
    } finally {
      _actionBusy = false;
      safeNotify();
    }
  }

  Future<RedeemResult> redeemCash({
    required int schemeId,
    required double points,
    required String upiId,
    String? brand,
  }) async {
    _actionBusy = true;
    safeNotify();
    try {
      final result = await repository.redeemCash(
        schemeId: schemeId,
        points: points,
        upiId: upiId,
        brand: brand,
      );
      await loadSummary(refresh: true);
      return result;
    } finally {
      _actionBusy = false;
      safeNotify();
    }
  }

  Future<RewardOrder> placeOrder({
    required int schemeId,
    required double points,
    required String name,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    String? brand,
  }) async {
    _actionBusy = true;
    safeNotify();
    try {
      final order = await repository.placeOrder(
        schemeId: schemeId,
        points: points,
        name: name,
        address: address,
        city: city,
        state: state,
        pinCode: pinCode,
        brand: brand,
      );
      await loadSummary(refresh: true);
      return order;
    } finally {
      _actionBusy = false;
      safeNotify();
    }
  }
}
