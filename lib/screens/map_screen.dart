import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';

import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_util.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String? chatId;

  const MapScreen({super.key, this.chatId});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _loading = true;
  bool _sharingLive = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() => _loading = true);
    try {
      final pos = await ref.read(locationServiceProvider).getCurrentPosition();
      if (pos == null) {
        if (mounted) SnackbarUtil.showError(context, 'Location permission denied');
        return;
      }

      setState(() {
        _currentPosition = pos;
        _markers.add(
          Marker(
            markerId: const MarkerId('me'),
            position: LatLng(pos.latitude, pos.longitude),
            infoWindow: const InfoWindow(title: 'You are here'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude),
          16,
        ),
      );
    } catch (e) {
      if (mounted) SnackbarUtil.showError(context, 'Failed to get location');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _shareLocationToChat() async {
    if (_currentPosition == null) return;
    if (widget.chatId == null) {
      SnackbarUtil.showInfo(context, 'Open from a chat to share location');
      return;
    }

    final address = await ref.read(locationServiceProvider).getAddressFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

    if (!mounted) return;
    context.pop({'lat': _currentPosition!.latitude, 'lng': _currentPosition!.longitude, 'address': address});
  }

  @override
  Widget build(BuildContext context) {
    final initialPos = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2088, 106.8456); // Default Jakarta

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Map'),
        actions: [
          if (widget.chatId != null)
            TextButton.icon(
              onPressed: _shareLocationToChat,
              icon: const Icon(Iconsax.send_2, size: 18),
              label: const Text('Share'),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) {
              _mapController = c;
              if (_currentPosition != null) {
                c.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    16,
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: initialPos,
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
          ),

          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'center',
                  onPressed: () {
                    if (_currentPosition != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          16,
                        ),
                      );
                    }
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Iconsax.location, color: AppTheme.primary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'refresh',
                  onPressed: _loadLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.refresh, color: AppTheme.primary),
                ),
              ],
            ),
          ),

          // Live share toggle
          if (widget.chatId != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 80,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Iconsax.location4, size: 20, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Share live location',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: _sharingLive,
                        onChanged: (v) => setState(() => _sharingLive = v),
                        activeColor: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
