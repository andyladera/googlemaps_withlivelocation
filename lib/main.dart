import 'package:flutter/material.dart';
import 'package:googlemaps_withlivelocation/order_tracking_page.dart'; // Importa la nueva página

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Google Maps',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      // Establecemos OrderTrackingPage como la pantalla de inicio
      home: const OrderTrackingPage(),
    );
  }
}