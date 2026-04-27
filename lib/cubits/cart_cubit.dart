import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get totalPrice => double.parse(product.price) * quantity;
}

class CartState {
  final List<CartItem> items;
  final double itemsTotalAmount;
  final double finalTotalAmount;
  final int? loadedOrderId;
  final bool isRefundMode;

  final int kegsRented;
  final int kegsReturned;
  final int cratesRented;
  final int cratesReturned;
  final int bottlesRented;
  final int bottlesReturned;

  // NOVÉ: Mapy pro uložení libovolného množství speciálních částek
  // Klíč je cena (např. 50.0), hodnota je počet kusů
  final Map<double, int> customRented;
  final Map<double, int> customReturned;

  CartState({
    required this.items,
    this.itemsTotalAmount = 0.0,
    this.finalTotalAmount = 0.0,
    this.loadedOrderId,
    this.isRefundMode = false,
    this.kegsRented = 0,
    this.kegsReturned = 0,
    this.cratesRented = 0,
    this.cratesReturned = 0,
    this.bottlesRented = 0,
    this.bottlesReturned = 0,
    this.customRented = const {},
    this.customReturned = const {},
  });
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartState(items: []));

  void toggleRefundMode() =>
      emit(CartState(items: [], isRefundMode: !state.isRefundMode));

  void loadReservation(int orderId, List<CartItem> reservationItems) {
    double itemsTotal = reservationItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    emit(
      CartState(
        items: reservationItems,
        itemsTotalAmount: itemsTotal,
        finalTotalAmount: itemsTotal,
        loadedOrderId: orderId,
      ),
    );
  }

  // --- OVLÁDÁNÍ OBALŮ ---
  void addKeg(bool isRented) =>
      _update(kegR: isRented ? 1 : 0, kegRet: isRented ? 0 : 1);
  void addCrate(bool isRented) =>
      _update(crateR: isRented ? 1 : 0, crateRet: isRented ? 0 : 1);
  void addBottle(bool isRented) =>
      _update(botR: isRented ? 1 : 0, botRet: isRented ? 0 : 1);

  void addFullCrate(int bottleCount, bool isRented) {
    if (isRented)
      _update(crateR: 1, botR: bottleCount);
    else
      _update(crateRet: 1, botRet: bottleCount);
  }

  // --- MAZÁNÍ OBALŮ (KAŽDÝ ZVLÁŠŤ) ---
  void clearKegsRented() => _update(setKegR: 0);
  void clearKegsReturned() => _update(setKegRet: 0);
  void clearCratesRented() => _update(setCrateR: 0);
  void clearCratesReturned() => _update(setCrateRet: 0);
  void clearBottlesRented() => _update(setBotR: 0);
  void clearBottlesReturned() => _update(setBotRet: 0);

  // --- SPECIÁLNÍ ČÁSTKY ---
  void addCustom(double price, bool isRented) {
    if (isRented) {
      final cr = Map<double, int>.from(state.customRented);
      cr[price] = (cr[price] ?? 0) + 1;
      _update(cRent: cr);
    } else {
      final cr = Map<double, int>.from(state.customReturned);
      cr[price] = (cr[price] ?? 0) + 1;
      _update(cRet: cr);
    }
  }

  void removeCustomRented(double price) {
    final cr = Map<double, int>.from(state.customRented);
    cr.remove(price);
    _update(cRent: cr);
  }

  void removeCustomReturned(double price) {
    final cr = Map<double, int>.from(state.customReturned);
    cr.remove(price);
    _update(cRet: cr);
  }

  void _update({
    int kegR = 0,
    int kegRet = 0,
    int crateR = 0,
    int crateRet = 0,
    int botR = 0,
    int botRet = 0,
    int? setKegR,
    int? setKegRet,
    int? setCrateR,
    int? setCrateRet,
    int? setBotR,
    int? setBotRet,
    Map<double, int>? cRent,
    Map<double, int>? cRet,
  }) {
    _emitUpdatedState(
      state.items,
      setKegR ?? (state.kegsRented + kegR),
      setKegRet ?? (state.kegsReturned + kegRet),
      setCrateR ?? (state.cratesRented + crateR),
      setCrateRet ?? (state.cratesReturned + crateRet),
      setBotR ?? (state.bottlesRented + botR),
      setBotRet ?? (state.bottlesReturned + botRet),
      cRent ?? state.customRented,
      cRet ?? state.customReturned,
    );
  }

  // --- ZBOŽÍ (PIVO) ---
  void addProduct(Product product) {
    final List<CartItem> currentItems = List.from(state.items);
    final existingIndex = currentItems.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      if (state.isRefundMode ||
          currentItems[existingIndex].quantity < product.currentStock)
        currentItems[existingIndex].quantity += 1;
    } else {
      if (state.isRefundMode || product.currentStock > 0)
        currentItems.add(CartItem(product: product));
    }
    _emitUpdatedState(
      currentItems,
      state.kegsRented,
      state.kegsReturned,
      state.cratesRented,
      state.cratesReturned,
      state.bottlesRented,
      state.bottlesReturned,
      state.customRented,
      state.customReturned,
    );
  }

  void removeProduct(Product product) {
    final List<CartItem> currentItems = List.from(state.items);
    final existingIndex = currentItems.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      if (currentItems[existingIndex].quantity > 1)
        currentItems[existingIndex].quantity -= 1;
      else
        currentItems.removeAt(existingIndex);
    }
    _emitUpdatedState(
      currentItems,
      state.kegsRented,
      state.kegsReturned,
      state.cratesRented,
      state.cratesReturned,
      state.bottlesRented,
      state.bottlesReturned,
      state.customRented,
      state.customReturned,
    );
  }

  void clearCart() =>
      emit(CartState(items: [], isRefundMode: state.isRefundMode));

  void _emitUpdatedState(
    List<CartItem> items,
    int kR,
    int kRet,
    int cR,
    int cRet,
    int bR,
    int bRet,
    Map<double, int> cRent,
    Map<double, int> cRetMap,
  ) {
    double itemsTotal = items.fold(0, (sum, i) => sum + i.totalPrice);
    double beerTotal = state.isRefundMode ? -itemsTotal : itemsTotal;

    double depTotal =
        (kR - kRet) * 1000.0 + (cR - cRet) * 100.0 + (bR - bRet) * 3.0;
    cRent.forEach((price, qty) => depTotal += (price * qty));
    cRetMap.forEach((price, qty) => depTotal -= (price * qty));

    emit(
      CartState(
        items: items,
        itemsTotalAmount: itemsTotal,
        finalTotalAmount: beerTotal + depTotal,
        isRefundMode: state.isRefundMode,
        kegsRented: kR,
        kegsReturned: kRet,
        cratesRented: cR,
        cratesReturned: cRet,
        bottlesRented: bR,
        bottlesReturned: bRet,
        customRented: cRent,
        customReturned: cRetMap,
        loadedOrderId: state.loadedOrderId,
      ),
    );
  }
}
