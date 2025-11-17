import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../../config/api_keys.dart';

class MapboxWidget extends StatefulWidget {
  final LatLng? pickup;
  final LatLng? destination;
  final VoidCallback? onMapTap;
  final Function(LatLng)? onLocationSelected;

  const MapboxWidget({
    super.key,
    this.pickup,
    this.destination,
    this.onMapTap,
    this.onLocationSelected,
  });

  @override
  State<MapboxWidget> createState() => _MapboxWidgetState();
}

class _MapboxWidgetState extends State<MapboxWidget> {
  final MapController _mapController = MapController();

  // Default location (Hanoi)
  static const LatLng _defaultLocation = LatLng(21.0285, 105.8542);

  @override
  void didUpdateWidget(MapboxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickup != widget.pickup ||
        oldWidget.destination != widget.destination) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (widget.pickup != null && widget.destination != null) {
      // Fit bounds để hiển thị cả 2 điểm
      final bounds = LatLngBounds(
        LatLng(
          widget.pickup!.latitude < widget.destination!.latitude
              ? widget.pickup!.latitude
              : widget.destination!.latitude,
          widget.pickup!.longitude < widget.destination!.longitude
              ? widget.pickup!.longitude
              : widget.destination!.longitude,
        ),
        LatLng(
          widget.pickup!.latitude > widget.destination!.latitude
              ? widget.pickup!.latitude
              : widget.destination!.latitude,
          widget.pickup!.longitude > widget.destination!.longitude
              ? widget.pickup!.longitude
              : widget.destination!.longitude,
        ),
      );

      // Delay để map controller ready
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50),
            ),
          );
        }
      });
    } else if (widget.pickup != null) {
      // Chỉ có pickup
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _mapController.move(widget.pickup!, 15);
        }
      });
    }
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Pickup marker
    if (widget.pickup != null) {
      markers.add(
        Marker(
          point: widget.pickup!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 40,
          ),
        ),
      );
    }

    // Destination marker
    if (widget.destination != null) {
      markers.add(
        Marker(
          point: widget.destination!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    if (widget.pickup != null && widget.destination != null) {
      return [
        Polyline(
          points: [widget.pickup!, widget.destination!],
          color: const Color(0xFFFF7F50),
          strokeWidth: 5.0,
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        LatLng initialPosition = _defaultLocation;

        if (locationService.hasLocation) {
          final pos = locationService.currentPosition!;
          initialPosition = LatLng(pos.latitude, pos.longitude);
        }

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.pickup ?? initialPosition,
                initialZoom: 14.0,
                onTap: (tapPosition, point) {
                  widget.onLocationSelected?.call(point);
                  widget.onMapTap?.call();
                },
              ),
              children: [
                // ✅ Mapbox Tile Layer
                TileLayer(
                  urlTemplate:
                  'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=${ApiKeys.mapboxAccessToken}',
                  userAgentPackageName: 'com.example.driverme_app',
                  maxZoom: 19,
                ),

                // ✅ Polylines (đường nối)
                PolylineLayer(
                  polylines: _buildPolylines(),
                ),

                // ✅ Markers
                MarkerLayer(
                  markers: _buildMarkers(),
                ),

                // ✅ Attribution (bắt buộc cho Mapbox)
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'Mapbox',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),

            // Custom controls
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  _buildMapButton(
                    icon: Icons.my_location,
                    onPressed: () async {
                      final success =
                      await locationService.getCurrentLocation();
                      if (success && locationService.hasLocation) {
                        final pos = locationService.currentPosition!;
                        _mapController.move(
                          LatLng(pos.latitude, pos.longitude),
                          16,
                        );
                      } else if (locationService.errorMessage != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(locationService.errorMessage!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMapButton(
                    icon: Icons.zoom_in,
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildMapButton(
                    icon: Icons.zoom_out,
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    },
                  ),
                ],
              ),
            ),

            if (locationService.isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}