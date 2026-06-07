import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profissional_page.dart'; // tela do profissional

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  LatLng minhaPosicao = LatLng(-25.4284, -49.2733);
  bool carregando = true;

  final Distance distance = const Distance();

  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  // 🔥 CARREGA TUDO
  Future<void> _carregarTudo() async {
    await _pegarLocalizacao();
    await _carregarProfissionais();
  }

  // 📍 PEGAR LOCALIZAÇÃO
  Future<void> _pegarLocalizacao() async {

    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => carregando = false);
      return;
    }

    Position pos = await Geolocator.getCurrentPosition();

    minhaPosicao = LatLng(pos.latitude, pos.longitude);
  }

  // 👥 CARREGAR PROFISSIONAIS
  Future<void> _carregarProfissionais() async {

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'profissional')
        .get();

    List<Marker> novosMarkers = [];

    for (var doc in snapshot.docs) {

      final data = doc.data();

      if (data['latitude'] != null && data['longitude'] != null) {

        final lat = data['latitude'];
        final lng = data['longitude'];

        final posProfissional = LatLng(lat, lng);

        // 📏 DISTÂNCIA
        final metros = distance(minhaPosicao, posProfissional);
        final km = (metros / 1000).toStringAsFixed(1);

        novosMarkers.add(
          Marker(
            point: posProfissional,
            width: 100,
            height: 80,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfissionalPage(data: data),
                  ),
                );
              },
              child: Column(
                children: [
                  const Icon(
                    Icons.person_pin_circle,
                    color: Colors.blue,
                    size: 40,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$km km",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    setState(() {
      markers = novosMarkers;
      carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa ConectaPro"),
      ),

      body: FlutterMap(
        options: MapOptions(
          initialCenter: minhaPosicao,
          initialZoom: 15,
        ),

        children: [

          // 🌍 MAPA
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.conectapro.app',
          ),

          // 📍 MARKERS
          MarkerLayer(
            markers: [

              // 🔴 SUA POSIÇÃO
              Marker(
                point: minhaPosicao,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_pin,
                  size: 40,
                  color: Colors.red,
                ),
              ),

              // 🔵 PROFISSIONAIS
              ...markers,
            ],
          ),
        ],
      ),
    );
  }
}