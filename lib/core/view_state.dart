// UPDATED 10.3: sealed 4-state view type. NEW: loading-again after a dependency change (a different person signed in) is Loading, not old data
import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class ViewState<T> {
  const new();
}

final class ViewLoading<T> extends ViewState<T> {
  const new();
}

final class ViewEmpty<T> extends ViewState<T> {
  const new();
}

final class ViewData<T> extends ViewState<T> {
  const new(this.data);
  final T data;
}

final class ViewFailure<T> extends ViewState<T> {
  const new(this.error);
  final Object error;
}

ViewState<T> toViewState<T>(AsyncValue<T> v, {bool Function(T)? isEmpty}) {
  // Reloading because something we depend on changed (e.g. another person signed in): the old value is NOT theirs. Show loading.
  // A pull-to-refresh (isRefreshing) still keeps the old cards on screen.
  if (v.isLoading && !v.isRefreshing) return ViewLoading<T>();
  if (v.hasValue) {
    final d = v.requireValue;
    return (isEmpty?.call(d) ?? false) ? ViewEmpty<T>() : ViewData<T>(d);
  }
  if (v.hasError) return ViewFailure<T>(v.error!);
  return ViewLoading<T>();
}

// The data if there is trustworthy data right now, otherwise null (use for small side reads, like a role or a picker)
T? dataOf<T>(AsyncValue<T> v) => switch (toViewState(v)) {
  ViewData(:final data) => data,
  ViewLoading() || ViewEmpty() || ViewFailure() => null,
};
