import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class _Place {
  final String name;
  final String address;
  final String? hours;
  final LatLng position;

  const _Place({
    required this.name,
    required this.address,
    required this.position,
    this.hours,
  });
}

class MoneyChangerScreen extends StatefulWidget {
  const MoneyChangerScreen({super.key});

  @override
  State<MoneyChangerScreen> createState() => _MoneyChangerScreenState();
}

class _MoneyChangerScreenState extends State<MoneyChangerScreen> {
  static const _searchRadiusMeters = 10000;
  static final _overpassUri =
      Uri.parse('https://overpass-api.de/api/interpreter');

  LatLng? _userPosition;
  List<_Place> _places = [];
  bool _loadingLocation = true;
  bool _loadingPlaces = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locateAndSearch();
  }

  Future<void> _locateAndSearch() async {
    if (mounted) {
      setState(() {
        _loadingLocation = true;
        _error = null;
      });
    }

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Aktifkan layanan lokasi/GPS di pengaturan HP.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception(
            'Izin lokasi ditolak. Izinkan akses lokasi untuk CoinWise.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Izin lokasi ditolak permanen. Aktifkan izin lokasi CoinWise di Pengaturan HP.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      final userPosition = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _userPosition = userPosition;
        _loadingLocation = false;
        _loadingPlaces = true;
      });

      final places = await _fetchPlaces(userPosition);
      if (!mounted) return;
      setState(() {
        _places = places;
        _loadingPlaces = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _loadingPlaces = false;
        _error = error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'Lokasi atau data money changer gagal dimuat: $error';
      });
    }
  }

  Future<List<_Place>> _fetchPlaces(LatLng center) async {
    final query = '''
[out:json][timeout:20];
(
  nwr(around:$_searchRadiusMeters,${center.latitude},${center.longitude})["shop"="currency_exchange"];
  nwr(around:$_searchRadiusMeters,${center.latitude},${center.longitude})["amenity"="bureau_de_change"];
  nwr(around:$_searchRadiusMeters,${center.latitude},${center.longitude})["currency:exchange"="yes"];
);
out center tags;
''';

    final response = await http.post(
      _overpassUri,
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'CoinWise/1.0 (educational mobile app)',
      },
      body: {'data': query},
    ).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception(
          'Pencarian peta gagal (HTTP ${response.statusCode}). Coba lagi nanti.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = json['elements'] as List<dynamic>? ?? [];
    final placesById = <String, _Place>{};

    for (final element in elements) {
      final item = Map<String, dynamic>.from(element as Map);
      final tags = Map<String, dynamic>.from(item['tags'] as Map? ?? {});
      final coordinates = item['type'] == 'node'
          ? item
          : Map<String, dynamic>.from(item['center'] as Map? ?? {});
      final latitude = coordinates['lat'];
      final longitude = coordinates['lon'];
      if (latitude is! num || longitude is! num) continue;

      final street = tags['addr:street'] as String?;
      final houseNumber = tags['addr:housenumber'] as String?;
      final city = tags['addr:city'] as String?;
      final address = [
        if (street != null && street.isNotEmpty)
          [street, houseNumber]
              .whereType<String>()
              .where((part) => part.isNotEmpty)
              .join(' '),
        if (city != null && city.isNotEmpty) city,
      ].join(', ');

      final id = '${item['type']}/${item['id']}';
      placesById[id] = _Place(
        name: (tags['name'] as String?)?.trim().isNotEmpty == true
            ? (tags['name'] as String).trim()
            : 'Money changer tanpa nama',
        address: address.isEmpty
            ? 'Alamat tidak tercantum di OpenStreetMap'
            : address,
        hours: tags['opening_hours'] as String?,
        position: LatLng(latitude.toDouble(), longitude.toDouble()),
      );
    }

    final places = placesById.values.toList()
      ..sort((a, b) => _distance(center, a.position)
          .compareTo(_distance(center, b.position)));
    return places;
  }

  double _distance(LatLng from, LatLng to) => Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );

  String _distanceLabel(LatLng position) {
    final distance = _distance(_userPosition!, position);
    return distance < 1000
        ? '${distance.round()} m'
        : '${(distance / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final center = _userPosition;
    final places = [..._places];
    if (center != null) {
      places.sort((a, b) => _distance(center, a.position)
          .compareTo(_distance(center, b.position)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Changer Terdekat'),
        actions: [
          IconButton(
            tooltip: 'Perbarui lokasi dan tempat',
            onPressed:
                _loadingLocation || _loadingPlaces ? null : _locateAndSearch,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: center == null
                ? _locationStatus()
                : FlutterMap(
                    key: ValueKey('${center.latitude}_${center.longitude}'),
                    options: MapOptions(initialCenter: center, initialZoom: 14),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.coinwise',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                          for (final place in places)
                            Marker(
                              point: place.position,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on,
                                  color: AppColors.danger, size: 40),
                            ),
                        ],
                      ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution('© OpenStreetMap contributors')
                        ],
                      ),
                    ],
                  ),
          ),
          Expanded(
            flex: 5,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _loadingPlaces
                      ? 'Mencari money changer...'
                      : '${places.length} Money Changer di Sekitar',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  center == null
                      ? 'Lokasi GPS belum tersedia.'
                      : 'Lokasi GPS aktif • Data tempat dari OpenStreetMap dalam radius ${_searchRadiusMeters ~/ 1000} km.',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                if (_loadingPlaces) ...[
                  const SizedBox(height: 14),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_error!,
                            style: const TextStyle(color: AppColors.danger)),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _loadingLocation || _loadingPlaces
                              ? null
                              : _locateAndSearch,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (center != null &&
                    !_loadingPlaces &&
                    _error == null &&
                    places.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Belum ada money changer yang terdaftar di OpenStreetMap dalam radius ini. Data dapat berbeda menurut area.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                for (final place in places)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(place.address,
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.directions_walk,
                                  size: 16, color: AppColors.tealDark),
                              Text(' ${_distanceLabel(place.position)}'),
                            ],
                          ),
                          if (place.hours != null)
                            Text('Jam buka: ${place.hours}',
                                style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationStatus() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loadingLocation)
                const CircularProgressIndicator()
              else
                const Icon(Icons.location_off,
                    size: 40, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                _loadingLocation
                    ? 'Mencari lokasi GPS...'
                    : (_error ?? 'Lokasi belum tersedia.'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              if (!_loadingLocation) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _locateAndSearch,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Aktifkan / coba lagi'),
                ),
              ],
            ],
          ),
        ),
      );
}
