import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Imports
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:googlemaps_withlivelocation/constants.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  // (Coordenadas y Cámara - Sin cambios)
  static const LatLng _pSource = LatLng(37.4223, -122.0848);
  static const LatLng _pDestination = LatLng(37.3346, -121.8949);
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _pSource,
    zoom: 11.5,
  );

  // (Marcadores - Sin cambios)
  final Set<Marker> _markers = {};

  // (Lista de coordenadas - Sin cambios)
  List<LatLng> polylineCoordinates = [];

  // --- CORRECCIÓN EN LA FUNCIÓN getPolyPoints ---
  Future<void> getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    // (2:38) Llama al método para obtener la ruta
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      // --- CORRECCIÓN AQUÍ ---
      // 1. Pasamos la API key como un argumento nombrado
      googleApiKey: googleApiKey,
      // 2. Pasamos un objeto PolylineRequest en lugar de argumentos sueltos
      request: PolylineRequest(
        origin: PointLatLng(_pSource.latitude, _pSource.longitude), // Origen
        destination: PointLatLng(_pDestination.latitude, _pDestination.longitude), // Destino
        // Opcional: puedes especificar el modo de viaje
        mode: TravelMode.driving, 
      ),
      // --- FIN DE LA CORRECCIÓN ---
    );

    // (2:59) El resto de la función es igual
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        );
      }
      setState(() {});
    }
  }
  // --- FIN DE LA CORRECCIÓN DE LA FUNCIÓN ---

  @override
  void initState() {
    super.initState();
    _markers.add(
      const Marker(
        markerId: MarkerId('source'),
        position: _pSource,
        infoWindow: InfoWindow(title: 'Origen'),
      ),
    );
    _markers.add(
      const Marker(
        markerId: MarkerId('destination'),
        position: _pDestination,
        infoWindow: InfoWindow(title: 'Destino'),
      ),
    );
    getPolyPoints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seguimiento en Vivo"),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        markers: _markers,
        polylines: {
          Polyline(
            polylineId: const PolylineId("route"),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 6,
          ),
        },
      ),
    );
  }
}