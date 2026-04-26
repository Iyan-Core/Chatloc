import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';

import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_button.dart';

class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  ConsumerState<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  GoogleMapController? _mapController;
  LatLng? _selected;
  String? _address;
  bool _loading = true;
  bool _isLive = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final pos = await ref.read(locationServiceProvider).getCurrentPosition();
    if (pos == null || !mounted) return;
    setState(() {
      _selected = LatLng(pos.latitude, pos.longitude);
      _loading = false;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_selected!, 15),
    );
    _resolveAddress(_selected!);
  }

  Future<void> _resolveAddress(LatLng pos) async {
    final addr = await ref.read(locationServiceProvider)
        .getAddressFromCoordinates(pos.latitude, pos.longitude);
    if (mounted) setState(() => _address = addr);
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      _selected = pos;
      _address = null;
    });
    _resolveAddress(pos);
  }

  void _send() {
    if (_selected == null) return;
    Navigator.pop(context, {
      'lat': _selected!.latitude,
      'lng': _selected!.longitude,
      'address': _address,
      'isLive': _isLive,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Text(
                  'Share Location',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: (c) {
                          _mapController = c;
                          if (_selected != null) {
                            c.animateCamera(
                              CameraUpdate.newLatLngZoom(_selected!, 15),
                            );
                          }
                        },
                        initialCameraPosition: CameraPosition(
                          target: _selected ?? const LatLng(-6.2088, 106.8456),
                          zoom: 14,
                        ),
                        onTap: _onMapTap,
                        markers: _selected != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('selected'),
                                  position: _selected!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueViolet,
                                  ),
                                ),
                              }
                            : {},
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                      ),

                      // Center on me button
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'center_me',
                          backgroundColor: Colors.white,
                          onPressed: _loadCurrent,
                          child: const Icon(
                            Iconsax.location,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Bottom panel
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Address row
                Row(
                  children: [
                    const Icon(Iconsax.location4, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _address ?? (_selected != null ? 'Resolving address…' : 'Tap map to select'),
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Live toggle
                Row(
                  children: [
                    const Icon(Icons.sensors, size: 18, color: Colors.orange),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share live location',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Updates for 30 minutes',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isLive,
                      onChanged: (v) => setState(() => _isLive = v),
                      activeColor: AppTheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Send button
                SizedBox(
                  width: double.infinity,
                  child: LoadingButton(
                    onPressed: _selected != null ? _send : () {},
                    isLoading: _sending,
                    label: _isLive ? '📡  Send Live Location' : '📍  Send Location',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
