import 'package:flutter/material.dart';

import '../state/view_state.dart';
import '../theme/app_colors.dart';
import 'state_views.dart';

class PagedListView<T> extends StatefulWidget {
  final List<T> items;
  final ViewStatus status;
  final String errorMessage;
  final bool isNetworkError;
  final bool loadingMore;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget emptyState;
  final Widget? skeleton;
  final EdgeInsetsGeometry padding;
  final double separatorHeight;
  final Widget? header;

  const PagedListView({
    super.key,
    required this.items,
    required this.status,
    required this.errorMessage,
    required this.onRefresh,
    required this.itemBuilder,
    required this.emptyState,
    this.isNetworkError = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onRetry,
    this.skeleton,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 32),
    this.separatorHeight = 12,
    this.header,
  });

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.loadingMore || widget.onLoadMore == null) {
      return;
    }

    final position = _controller.position;

    if (position.pixels >= position.maxScrollExtent - 320) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == ViewStatus.loading && widget.items.isEmpty) {
      return widget.skeleton ?? const ListSkeleton();
    }

    if (widget.status == ViewStatus.error && widget.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.62,
              child: ErrorView(
                message: widget.errorMessage,
                isNetwork: widget.isNetworkError,
                onRetry: widget.onRetry,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (widget.header != null) widget.header!,
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.58,
              child: widget.emptyState,
            ),
          ],
        ),
      );
    }

    final headerOffset = widget.header != null ? 1 : 0;
    final footerCount = widget.loadingMore ? 1 : 0;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        controller: _controller,
        padding: widget.padding,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.items.length + headerOffset + footerCount,
        separatorBuilder: (_, __) => SizedBox(height: widget.separatorHeight),
        itemBuilder: (context, index) {
          if (widget.header != null && index == 0) {
            return widget.header!;
          }

          final dataIndex = index - headerOffset;

          if (dataIndex >= widget.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            );
          }

          return widget.itemBuilder(
            context,
            widget.items[dataIndex],
            dataIndex,
          );
        },
      ),
    );
  }
}
