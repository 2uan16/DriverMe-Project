import 'package:driverme_app/screens/driver/driver_earning_screen.dart';
import 'package:driverme_app/screens/driver/driver_profile_screen.dart';
import 'package:driverme_app/screens/user/trip_tracking_screen.dart';
import 'package:driverme_app/screens/user/user_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// Import config
import 'config/app_theme.dart';

// Import services
import 'services/location_service.dart';
import 'services/socket_service.dart';
import 'services/auth_service.dart';

// Import screens
import 'screens/splash_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user/user_home_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/driver/available_bookings_screen.dart';
import 'screens/driver/driver_bookings_screen.dart';
import 'screens/user/point_to_point_booking.dart';
import 'screens/user/user_profile_screen.dart';
import 'screens/driver/driver_trip_flow_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AuthService
  final authService = AuthService();
  await authService.init();

  runApp(const DriverMeApp());
}

class AppConfig {
  static const String appName = 'DriverMe';
}

class DriverMeApp extends StatelessWidget {
  const DriverMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => SocketService()),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}

// Router configuration
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/login-user',
      builder: (context, state) => const LoginScreen(role: 'user'),
    ),
    GoRoute(
      path: '/login-driver',
      builder: (context, state) => const LoginScreen(role: 'driver'),
    ),
    GoRoute(
      path: '/register-user',
      builder: (context, state) => const RegisterScreen(role: 'user'),
    ),
    GoRoute(
      path: '/register-driver',
      builder: (context, state) => const RegisterScreen(role: 'driver'),
    ),
    GoRoute(
      path: '/user-home',
      builder: (context, state) => const UserHomeScreen(),
    ),
    GoRoute(
      path: '/driver-home',
      builder: (context, state) => const DriverHomeScreen(),
    ),
    GoRoute(
      path: '/driver/available-bookings',
      builder: (context, state) => const AvailableBookingsScreen(),
    ),
    GoRoute(
      path: '/driver/my-bookings',
      builder: (context, state) => const DriverBookingsScreen(),
    ),
    GoRoute(
      path: '/user/point-to-point-booking',
      builder: (context, state) => const PointToPointBookingScreen(),
    ),
    GoRoute(
      path: '/user-profile',
      builder: (context, state) => const UserProfileScreen(),
    ),
    GoRoute(
      path: '/trip-tracking/:bookingId',
      builder: (context, state) => TripTrackingScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(
      path: '/driver-home',
      builder: (context, state) => const DriverHomeScreen(),
    ),
    GoRoute(
      path: '/driver/trip-flow',
      builder: (context, state) {
        final bookingId = state.extra as String?; 
        return DriverTripFlowScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: '/user-history',
      builder: (context, state) => const UserHistoryScreen(),
    ),
    GoRoute(
      path: '/driver/earnings',
      builder: (context, state) => const DriverEarningsScreen(),
    ),
    GoRoute(
      path: '/driver/profile',
      builder: (context, state) => const DriverProfileScreen(),
    ),
  ],
);