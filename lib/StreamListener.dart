import 'dart:async';

import 'package:flutter/material.dart';

abstract class PxlsStreamBuilderBase<T, S> extends StatefulWidget {
  const PxlsStreamBuilderBase({ super.key, this.stream });

  final Stream<T>? stream;

  S initial();
  S afterConnected(S current) => current;
  S afterData(S current, T data);
  S afterError(S current, Object error, StackTrace stackTrace) => current;
  S afterDone(S current) => current;
  S afterDisconnected(S current) => current;

  Widget build(BuildContext context, S currentSummary);

  @override
  State<PxlsStreamBuilderBase<T, S>> createState() => _PxlsStreamBuilderBaseState<T, S>();
}

class _PxlsStreamBuilderBaseState<T, S> extends State<PxlsStreamBuilderBase<T, S>> {
  StreamSubscription<T>? _subscription; // ignore: cancel_subscriptions
  late S _summary;

  @override
  void initState() {
    super.initState();
    _summary = widget.initial();
    _subscribe();
  }

  @override
  void didUpdateWidget(PxlsStreamBuilderBase<T, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      if (_subscription != null) {
        _unsubscribe();
        _summary = widget.afterDisconnected(_summary);
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) {
    var built = widget.build(context, _summary);
    _summary = const AsyncSnapshot.withData(ConnectionState.active, []) as S;
    return built;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (widget.stream != null) {
      _subscription = widget.stream!.listen((T data) {
        setState(() {
          _summary = widget.afterData(_summary, data);
        });
      }, onError: (Object error, StackTrace stackTrace) {
        setState(() {
          _summary = widget.afterError(_summary, error, stackTrace);
        });
      }, onDone: () {
        setState(() {
          _summary = widget.afterDone(_summary);
        });
      });
      _summary = widget.afterConnected(_summary);
    }
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }
  }
}

class PxlsStreamBuilder<T, S> extends PxlsStreamBuilderBase<T, AsyncSnapshot<S>> {
  const PxlsStreamBuilder({
    Key? key,
    required this.initialData,
    required this.fold,
    Stream<T>? stream,
    required this.builder,
  }) : super(key: key, stream: stream);

  final Fold<T, S> fold;

  final AsyncWidgetBuilder<S> builder;

  final S initialData;

  @override
  AsyncSnapshot<S> initial() =>
      AsyncSnapshot<S>.withData(ConnectionState.none, initialData);

  @override
  AsyncSnapshot<S> afterConnected(AsyncSnapshot<S> current) =>
      initial().inState(ConnectionState.waiting);

  @override
  AsyncSnapshot<S> afterData(AsyncSnapshot<S> current, T data) {
    return AsyncSnapshot<S>.withData(
        ConnectionState.active, fold(current.data as S, data));
  }

  @override
  AsyncSnapshot<S> afterError(
      AsyncSnapshot<S> current, Object error, StackTrace stackTrace) {
    return AsyncSnapshot<S>.withError(ConnectionState.active, error);
  }

  @override
  AsyncSnapshot<S> afterDone(AsyncSnapshot<S> current) =>
      current.inState(ConnectionState.done);

  @override
  AsyncSnapshot<S> afterDisconnected(AsyncSnapshot<S> current) =>
      current.inState(ConnectionState.none);

  @override
  Widget build(BuildContext context, AsyncSnapshot<S> currentSummary) =>
      builder(context, currentSummary);
}

typedef Fold<T, S> = S Function(S currentSummary, T newValue);
