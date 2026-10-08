import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the phone currently has a network connection.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  bool online(List<ConnectivityResult> r) => r.isNotEmpty && !r.contains(ConnectivityResult.none);
  yield online(await Connectivity().checkConnectivity());
  yield* Connectivity().onConnectivityChanged.map(online);
});
