import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'injection/injection_container.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/products/presentation/bloc/product_bloc.dart';
import 'features/products/presentation/pages/products_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StartupApp());
}

class EcommerceApp extends StatelessWidget {
  const EcommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductBloc>(
          create: (_) => getIt<ProductBloc>()..add(const ProductsRequested()),
        ),
        BlocProvider<CartBloc>(
          create: (_) => getIt<CartBloc>()..add(const CartStarted()),
        ),
      ],
      child: MaterialApp(
        title: 'E-Commerce App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        ),
        home: const ProductsPage(),
      ),
    );
  }
}

/// A storage failure is recoverable without deleting or replacing the cart.
class StartupApp extends StatefulWidget {
  const StartupApp({super.key});
  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  late Future<void> _initialization = initDependencies();
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) {
            return const EcommerceApp();
          }
          return MaterialApp(
            home: Scaffold(
                body: Center(
                    child: snapshot.hasError
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                    'Unable to open cart storage. Your stored data has been preserved.',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                FilledButton(
                                    onPressed: () => setState(() {
                                          _initialization = initDependencies();
                                        }),
                                    child: const Text('Retry')),
                              ],
                            ))
                        : const CircularProgressIndicator())),
          );
        },
      );
}
