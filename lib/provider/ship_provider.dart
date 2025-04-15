import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/ship.dart';
import '../service/ship_service.dart';

class ShipListState {
  final bool isLoading;
  final List<Ship> ships;

  ShipListState({this.isLoading = false, this.ships = const []});

  factory ShipListState.initial() => ShipListState();
}

class ShipListNotifier extends StateNotifier<ShipListState> {
  ShipListNotifier() : super(ShipListState.initial());

  Future<void> fetchAll(String region) async {
    state = ShipListState(isLoading: true);
    final result = await ShipService.fetchAll(region);
    state = ShipListState(isLoading: false, ships: result);
  }

  void reset() {
    state = ShipListState.initial();
  }
}

final shipListProvider =
    StateNotifierProvider<ShipListNotifier, ShipListState>((ref) {
  return ShipListNotifier();
});
