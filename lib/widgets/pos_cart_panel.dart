import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/cart_cubit.dart';
import '../cubits/auth_cubit.dart';
import '../services/api_service.dart';
import '../utils/deposit_sheet.dart';

class PosCartPanel extends StatelessWidget {
  final ApiService apiService;
  final VoidCallback onSaleComplete;

  const PosCartPanel({
    super.key,
    required this.apiService,
    required this.onSaleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: state.isRefundMode
                  ? Colors.red.shade100
                  : Colors.blue.shade50,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    state.isRefundMode ? '🔴 REŽIM VRATKY' : 'Aktuální účtenka',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: state.isRefundMode
                          ? Colors.red.shade900
                          : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      const Text('Vratka'),
                      Switch(
                        value: state.isRefundMode,
                        activeColor: Colors.red,
                        onChanged: state.loadedOrderId != null
                            ? null
                            : (val) =>
                                  context.read<CartCubit>().toggleRefundMode(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.items.isEmpty && _isDepositEmpty(state)
                  ? Center(
                      child: Text(
                        state.isRefundMode
                            ? 'Vyberte sudy k vrácení'
                            : 'Účtenka je prázdná',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView(
                      children: [
                        ...state.items.map(
                          (item) => ListTile(
                            title: Text(
                              '${item.product.brand} ${item.product.volume}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${state.isRefundMode ? "-" : ""}${item.quantity}x ${item.product.price} Kč',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${state.isRefundMode ? "-" : ""}${item.totalPrice.toStringAsFixed(2)} Kč',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: state.isRefundMode
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => context
                                      .read<CartCubit>()
                                      .removeProduct(item.product),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (state.kegsRented > 0)
                          _buildDepositItem(
                            context,
                            'Půjčený sud',
                            state.kegsRented,
                            1000.0,
                            () => context.read<CartCubit>().clearKegsRented(),
                          ),
                        if (state.kegsReturned > 0)
                          _buildDepositItem(
                            context,
                            'Vrácený sud',
                            state.kegsReturned,
                            -1000.0,
                            () => context.read<CartCubit>().clearKegsReturned(),
                          ),
                        if (state.cratesRented > 0)
                          _buildDepositItem(
                            context,
                            'Půjčená bedna',
                            state.cratesRented,
                            100.0,
                            () => context.read<CartCubit>().clearCratesRented(),
                          ),
                        if (state.cratesReturned > 0)
                          _buildDepositItem(
                            context,
                            'Vrácená bedna',
                            state.cratesReturned,
                            -100.0,
                            () =>
                                context.read<CartCubit>().clearCratesReturned(),
                          ),
                        if (state.bottlesRented > 0)
                          _buildDepositItem(
                            context,
                            'Půjčená lahev',
                            state.bottlesRented,
                            3.0,
                            () =>
                                context.read<CartCubit>().clearBottlesRented(),
                          ),
                        if (state.bottlesReturned > 0)
                          _buildDepositItem(
                            context,
                            'Vrácená lahev',
                            state.bottlesReturned,
                            -3.0,
                            () => context
                                .read<CartCubit>()
                                .clearBottlesReturned(),
                          ),
                      ],
                    ),
            ),
            _buildBottomPanel(context, state),
          ],
        );
      },
    );
  }

  bool _isDepositEmpty(CartState state) {
    return state.kegsRented == 0 &&
        state.kegsReturned == 0 &&
        state.cratesRented == 0 &&
        state.cratesReturned == 0 &&
        state.bottlesRented == 0 &&
        state.bottlesReturned == 0;
  }

  Widget _buildDepositItem(
    BuildContext context,
    String title,
    int qty,
    double price,
    VoidCallback onClear,
  ) {
    return ListTile(
      tileColor: Colors.amber.shade50,
      leading: const Icon(Icons.inventory_2, color: Colors.amber),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$qty ks x ${price.abs()} Kč'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(qty * price).toStringAsFixed(2)} Kč',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: price < 0 ? Colors.red : Colors.green,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, CartState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () => DepositSheet.show(context),
            icon: const Icon(Icons.inventory_2),
            label: Text(
              'OBALY (Sudy: ${state.kegsRented + state.kegsReturned}, Bedny: ${state.cratesRented + state.cratesReturned})',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.isRefundMode || state.finalTotalAmount < 0
                    ? 'Celkem vracet:'
                    : 'Celkem k úhradě:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${state.finalTotalAmount.toStringAsFixed(2)} Kč',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: state.finalTotalAmount < 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () => context.read<CartCubit>().clearCart(),
                  child: Text(
                    state.loadedOrderId != null ? 'ODLOŽIT' : 'VYMAZAT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    backgroundColor:
                        state.isRefundMode || state.finalTotalAmount < 0
                        ? Colors.red
                        : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (state.items.isEmpty && _isDepositEmpty(state))
                      ? null
                      : () => _handleCheckout(context, state),
                  child: Text(
                    state.isRefundMode || state.finalTotalAmount < 0
                        ? 'PROVÉST VRATKU'
                        : 'DOKONČIT PRODEJ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleCheckout(BuildContext context, CartState state) async {
    final authState = context.read<AuthCubit>().state;
    final userId = authState.userId ?? 1;

    try {
      if (state.isRefundMode) {
        final refundItems = state.items
            .map((i) => {"product_id": i.product.id, "quantity": i.quantity})
            .toList();
        await apiService.refundOrder(refundItems, state.finalTotalAmount);
      } else if (state.loadedOrderId != null) {
        await apiService.fulfillOrder(
          state.loadedOrderId!,
          state.items,
          state.finalTotalAmount,
        );
      } else {
        await apiService.createOrder(
          state.items,
          state.finalTotalAmount,
          state.kegsRented,
          state.kegsReturned,
          userId,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dokončeno!'),
            backgroundColor: Colors.green,
          ),
        );
        context.read<CartCubit>().clearCart();
        onSaleComplete();
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Chyba: $e')));
    }
  }
}
