import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';

enum ViewStatus { idle, loading, refreshing, success, empty, error }

class LoadableNotifier extends ChangeNotifier {
  ViewStatus _status = ViewStatus.idle;
  String _errorMessage = '';
  ApiFailureKind? _errorKind;
  bool _disposed = false;

  ViewStatus get status => _status;

  String get errorMessage => _errorMessage;

  ApiFailureKind? get errorKind => _errorKind;

  bool get isIdle => _status == ViewStatus.idle;

  bool get isLoading => _status == ViewStatus.loading;

  bool get isRefreshing => _status == ViewStatus.refreshing;

  bool get isBusy => isLoading || isRefreshing;

  bool get isError => _status == ViewStatus.error;

  bool get isEmpty => _status == ViewStatus.empty;

  bool get hasData => _status == ViewStatus.success || _status == ViewStatus.empty;

  bool get isNetworkError => _errorKind == ApiFailureKind.network;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @protected
  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @protected
  void setStatus(ViewStatus value) {
    _status = value;
    if (value != ViewStatus.error) {
      _errorMessage = '';
      _errorKind = null;
    }
    safeNotify();
  }

  @protected
  void setError(Object error) {
    _status = ViewStatus.error;
    if (error is ApiException) {
      _errorMessage = error.message;
      _errorKind = error.kind;
    } else {
      _errorMessage = 'Something went wrong. Please try again.';
      _errorKind = ApiFailureKind.unknown;
    }
    safeNotify();
  }

  @protected
  Future<void> guard(
    Future<void> Function() action, {
    bool refreshing = false,
  }) async {
    setStatus(refreshing ? ViewStatus.refreshing : ViewStatus.loading);
    try {
      await action();
    } catch (error) {
      setError(error);
    }
  }
}
