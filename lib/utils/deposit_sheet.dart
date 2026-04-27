import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/cart_cubit.dart';

class DepositSheet {
  static void show(BuildContext context) {
    final customPriceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<CartCubit>(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'OBALY',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildSimpleRow(
                    context,
                    'SUDY (1000 Kč)',
                    () => context.read<CartCubit>().addKeg(false),
                    () => context.read<CartCubit>().addKeg(true),
                  ),
                  _buildSimpleRow(
                    context,
                    'BEDNY (100 Kč)',
                    () => context.read<CartCubit>().addCrate(false),
                    () => context.read<CartCubit>().addCrate(true),
                  ),
                  _buildSimpleRow(
                    context,
                    'LAHVE (3 Kč)',
                    () => context.read<CartCubit>().addBottle(false),
                    () => context.read<CartCubit>().addBottle(true),
                  ),
                  const Divider(height: 30),
                  const Text(
                    'SPECIÁLNÍ OBAL (Kč/ks)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customPriceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Částka',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          double? val = double.tryParse(customPriceCtrl.text);
                          if (val != null)
                            context.read<CartCubit>().addCustom(val, false);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          double? val = double.tryParse(customPriceCtrl.text);
                          if (val != null)
                            context.read<CartCubit>().addCustom(val, true);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ZAVŘÍT'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildSimpleRow(
    BuildContext context,
    String label,
    VoidCallback onMinus,
    VoidCallback onPlus,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red, size: 35),
            onPressed: onMinus,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green, size: 35),
            onPressed: onPlus,
          ),
        ],
      ),
    );
  }
}
