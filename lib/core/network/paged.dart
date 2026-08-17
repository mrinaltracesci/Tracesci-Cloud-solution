import 'api_response.dart';

class Paged<T> {
  final List<T> items;
  final PageMeta meta;

  const Paged({required this.items, required this.meta});

  factory Paged.empty() => Paged<T>(items: const [], meta: PageMeta.empty());

  bool get isEmpty => items.isEmpty;

  bool get hasMore => meta.hasMore;

  Paged<T> merge(Paged<T> next) {
    return Paged<T>(
      items: [...items, ...next.items],
      meta: next.meta,
    );
  }
}
