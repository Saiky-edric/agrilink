import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/order_model.dart';
import '../../core/theme/app_theme.dart';

/// Real-time map tracking widget for delivery orders
/// Shows farmer/delivery location moving towards buyer location
class OrderMapTracking extends StatefulWidget {
  final OrderModel order;
  final bool showRoute;
  final double height;

  const OrderMapTracking({
    super.key,
    required this.order,
    this.showRoute = true,
    this.height = 300,
  });

  @override
  State<OrderMapTracking> createState() => _OrderMapTrackingState();
}

class _OrderMapTrackingState extends State<OrderMapTracking> {
  final MapController _mapController = MapController();
  StreamSubscription<List<Map<String, dynamic>>>? _locationSubscription;
  LatLng? _deliveryLocation;
  LatLng? _buyerLocation;
  LatLng? _farmerLocation;
  DateTime? _lastUpdated;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _subscribeToLocationUpdates();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _initializeLocations() {
    // Set initial locations from order data
    if (widget.order.buyerLatitude != null && widget.order.buyerLongitude != null) {
      _buyerLocation = LatLng(widget.order.buyerLatitude!, widget.order.buyerLongitude!);
    }

    if (widget.order.farmerLatitude != null && widget.order.farmerLongitude != null) {
      _farmerLocation = LatLng(widget.order.farmerLatitude!, widget.order.farmerLongitude!);
    }

    if (widget.order.deliveryLatitude != null && widget.order.deliveryLongitude != null) {
      _deliveryLocation = LatLng(widget.order.deliveryLatitude!, widget.order.deliveryLongitude!);
      _lastUpdated = widget.order.deliveryLastUpdatedAt;
    } else {
      // If no delivery location yet, use farmer location as starting point
      _deliveryLocation = _farmerLocation;
    }

    setState(() => _isLoading = false);
  }

  void _subscribeToLocationUpdates() {
    // Subscribe to real-time location updates for this order
    _locationSubscription = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.order.id)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final orderData = data.first;
            final lat = orderData['delivery_latitude'] as double?;
            final lng = orderData['delivery_longitude'] as double?;
            final lastUpdated = orderData['delivery_last_updated_at'] as String?;

            if (lat != null && lng != null) {
              setState(() {
                _deliveryLocation = LatLng(lat, lng);
                if (lastUpdated != null) {
                  _lastUpdated = DateTime.parse(lastUpdated);
                }
              });

              // Animate map to new location
              _mapController.move(_deliveryLocation!, _mapController.camera.zoom);
            }
          }
        });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const distance = Distance();
    return distance.as(LengthUnit.Kilometer, start, end);
  }

  String _getEstimatedTime() {
    if (_deliveryLocation == null || _buyerLocation == null) {
      return 'Calculating...';
    }

    final distanceKm = _calculateDistance(_deliveryLocation!, _buyerLocation!);
    
    // Assume average speed of 30 km/h for delivery
    final hoursRemaining = distanceKm / 30;
    final minutesRemaining = (hoursRemaining * 60).round();

    if (minutesRemaining < 1) {
      return 'Arriving soon';
    } else if (minutesRemaining < 60) {
      return '$minutesRemaining min';
    } else {
      final hours = minutesRemaining ~/ 60;
      final mins = minutesRemaining % 60;
      return '${hours}h ${mins}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_deliveryLocation == null || _buyerLocation == null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Location tracking not available',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate center point and zoom level
    final bounds = LatLngBounds(
      _deliveryLocation!,
      _buyerLocation!,
    );
    final center = bounds.center;

    return Column(
      children: [
        // Map header with info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Tracking',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'ETA: ${_getEstimatedTime()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.straighten, size: 14, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '${_calculateDistance(_deliveryLocation!, _buyerLocation!).toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_lastUpdated != null)
                Chip(
                  label: Text(
                    _formatLastUpdated(_lastUpdated!),
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.green.shade50,
                  side: BorderSide(color: Colors.green.shade200),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),

        // Map
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                minZoom: 10,
                maxZoom: 18,
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.agrilink',
                ),

                // Route line (if enabled)
                if (widget.showRoute)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_deliveryLocation!, _buyerLocation!],
                        strokeWidth: 4,
                        color: Colors.blue.shade600,
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                      ),
                    ],
                  ),

                // Markers
                MarkerLayer(
                  markers: [
                    // Delivery location (moving)
                    Marker(
                      point: _deliveryLocation!,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Delivery',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Buyer location (destination)
                    Marker(
                      point: _buyerLocation!,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Your Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.home,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Farmer location (start point) - optional
                    if (_farmerLocation != null && _deliveryLocation != _farmerLocation)
                      Marker(
                        point: _farmerLocation!,
                        width: 60,
                        height: 60,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orange.shade600, width: 2),
                          ),
                          child: Icon(
                            Icons.store,
                            color: Colors.orange.shade600,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inSeconds < 30) {
      return 'Just now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}

/// Compact map tracking card for timeline integration
class OrderMapTrackingCard extends StatelessWidget {
  final OrderModel order;

  const OrderMapTrackingCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          OrderMapTracking(
            order: order,
            showRoute: true,
            height: 250,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location updates every 30 seconds',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Open full screen map
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Delivery Tracking'),
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          body: OrderMapTracking(
                            order: order,
                            showRoute: true,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fullscreen, size: 16),
                  label: const Text('Full Map'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
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
