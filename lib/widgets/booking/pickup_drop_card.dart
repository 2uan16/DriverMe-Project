import 'package:flutter/material.dart';

class PickupDropCard extends StatelessWidget {
  final String pickupTitle;
  final String pickup;
  final String? dropoff;
  final String? distanceText;
  final String? durationText;
  final VoidCallback? onUseMyLocation;
  final VoidCallback onPickTap;
  final VoidCallback onDropTap;
  final VoidCallback onSwap;

  const PickupDropCard({
    super.key,
    required this.pickupTitle,
    required this.pickup,
    required this.dropoff,
    this.distanceText,
    this.durationText,
    this.onUseMyLocation,
    required this.onPickTap,
    required this.onDropTap,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pickup
            _buildLocationRow(
              icon: Icons.trip_origin,
              iconColor: Colors.green,
              title: pickupTitle,
              address: pickup,
              onTap: onPickTap,
              trailing: onUseMyLocation != null
                  ? IconButton(
                icon: const Icon(Icons.my_location, size: 20),
                onPressed: onUseMyLocation,
                tooltip: 'Vị trí hiện tại',
              )
                  : null,
            ),

            const Divider(height: 24),

            // Dropoff
            _buildLocationRow(
              icon: Icons.location_on,
              iconColor: Colors.red,
              title: 'Điểm đến',
              address: dropoff ?? 'Chọn điểm đến',
              isPlaceholder: dropoff == null,
              onTap: onDropTap,
              trailing: IconButton(
                icon: const Icon(Icons.swap_vert, size: 20),
                onPressed: onSwap,
                tooltip: 'Đổi điểm',
              ),
            ),

            // Distance & Duration
            if (distanceText != null && durationText != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.route, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        '$distanceText • $durationText',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
    bool isPlaceholder = false,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w600,
                    color: isPlaceholder ? Colors.grey : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}