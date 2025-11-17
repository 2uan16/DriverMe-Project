import 'package:flutter/material.dart';
import '../../models/car_service.dart';
import 'service_card.dart';
import 'action_buttons_row.dart';

class BookingBottomPanel extends StatelessWidget {
  final List<CarService> services;
  final int selectedServiceIndex;
  final Function(int) onServiceSelected;
  final List<ActionButton> actionButtons;
  final bool canBook;
  final bool isBooking;
  final VoidCallback? onBookTap;

  const BookingBottomPanel({
    super.key,
    required this.services,
    required this.selectedServiceIndex,
    required this.onServiceSelected,
    required this.actionButtons,
    required this.canBook,
    required this.isBooking,
    this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.25,
      maxChildSize: 0.65,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Service list
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: services.length,
                  itemBuilder: (ctx, i) => ServiceCard(
                    service: services[i],
                    isSelected: i == selectedServiceIndex,
                    onTap: () => onServiceSelected(i),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ActionButtonsRow(buttons: actionButtons),
              ),

              const SizedBox(height: 12),

              // Book button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (canBook && !isBooking) ? onBookTap : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7F50),
                      disabledBackgroundColor: const Color(0x33FF7F50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isBooking
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Đặt chuyến',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}