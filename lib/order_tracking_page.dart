import 'dart:async'; // --- NUEVO --- (Para el GoogleMapController)
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:googlemaps_withlivelocation/constants.dart';

// --- NUEVO: Import para el paquete de ubicación ---
import 'package:location/location.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  // (Coordenadas y Cámara - Cambiadas)
  static const LatLng _pSource = LatLng(37.4223, -122.0848);
  static const LatLng _pDestination = LatLng(37.3346, -121.8949);
  
  // (Marcadores y Polilíneas - Sin cambios)
  final Set<Marker> _markers = {};
  List<LatLng> polylineCoordinates = [];

  // --- NUEVO: Variables de Estado para Ubicación en Vivo ---
  
  // (3:42) Variable para guardar la ubicación actual
  LocationData? currentLocation;
  
  // (5:56) Controlador para el Google Map
  // Lo usamos para animar la cámara
  GoogleMapController? _mapController;

  // (3:49) Instancia del paquete de ubicación
  final Location _locationService = Location();

  // (3:46) Función para obtener la ubicación y escuchar cambios
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // 1. Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        return; // El usuario no habilitó el servicio
      }
    }

    // 2. Verificar si se tienen permisos
    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return; // El usuario no dio permisos
      }
    }

    // 3. Obtener la ubicación inicial
    // (3:52)
    final locationData = await _locationService.getLocation();
    setState(() {
      // (3:54)
      currentLocation = locationData;
      _addCurrentLocationMarker();
    });

    // 4. Escuchar cambios de ubicación (¡Esto es el tracking!)
    // (5:44)
    _locationService.onLocationChanged.listen((LocationData newLocation) {
      setState(() {
        // (5:44) Actualiza la ubicación actual
        currentLocation = newLocation;
        _addCurrentLocationMarker();

        // (6:15) Anima la cámara para seguir al usuario
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(newLocation.latitude!, newLocation.longitude!),
                zoom: 16.5, // Un zoom más cercano para el seguimiento
              ),
            ),
          );
        }
      });
    });
  }

  // --- NUEVO: Función para añadir/actualizar el marcador de ubicación actual ---
  void _addCurrentLocationMarker() {
    if (currentLocation == null) return;

    // Removemos el marcador anterior para actualizarlo
    _markers.removeWhere((marker) => marker.markerId.value == 'currentLocation');
    
    // (4:09) Añadimos el nuevo marcador
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        infoWindow: const InfoWindow(title: 'Mi Ubicación'),
        // (Opcional) Cambiaremos este icono en el siguiente paso
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  // (Función getPolyPoints - Sin cambios)
  Future<void> getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleApiKey,
      request: PolylineRequest(
        origin: PointLatLng(_pSource.latitude, _pSource.longitude),
        destination: PointLatLng(_pDestination.latitude, _pDestination.longitude),
        mode: TravelMode.driving,
      ),
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // (3:09)
    getPolyPoints(); // Obtiene la ruta

    // (3:57)
    _getCurrentLocation(); // Obtiene la ubicación en vivo

    // Añade los marcadores estáticos (sin cambios)
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
  }

  // --- NUEVO: Liberar el controlador del mapa ---
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seguimiento en Vivo"),
      ),
      // --- NUEVO: Mostrar carga mientras se obtiene la ubicación ---
      body: currentLocation == null
          ? const Center(
              // (4:00)
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Obteniendo ubicación..."),
                ],
              ),
            )
          : GoogleMap(
              // --- NUEVO: (5:59) Asignar el controlador ---
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              // (4:21) La cámara inicial ahora es la ubicación del usuario
              initialCameraPosition: CameraPosition(
                target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
                zoom: 16.5,
              ),
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