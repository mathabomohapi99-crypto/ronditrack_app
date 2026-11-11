// NEW: sealed 4-state view type + the function that turns an AsyncValue into it (Part 4)
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

// Old data stays "data" while a refresh is loading, so pull-to-refresh keeps the old cards on screen
ViewState<T> toViewState<T>(AsyncValue<T> v, {bool Function(T)? isEmpty}) {
  if (v.hasValue) {
    final d = v.requireValue;
    return (isEmpty?.call(d) ?? false) ? ViewEmpty<T>() : ViewData<T>(d);
  }
  if (v.hasError) return ViewFailure<T>(v.error!);
  return ViewLoading<T>();
}
