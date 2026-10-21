import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:roomee/core/types/types.dart';

export 'package:roomee/core/types/types.dart';

const int _apiPort = 5000;

String _resolveApiBaseUrl() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:$_apiPort/api/v1';
  }
  return 'http://localhost:$_apiPort/api/v1';
}

final String apiBaseUrl = _resolveApiBaseUrl();

final String logoAssetPath = 'assets/images/logo.png';

enum UserRole { staff, landlord, tenant, admin }

enum Gender { male, female, other }

/// Danh sách các item trong Bottom Bar của Chủ trọ / Quản lý trọ
const List<AppNavItem> landlordNavItems = [
  AppNavItem(
    labelKey: 'navHome',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
  ),
  AppNavItem(
    labelKey: 'navWorkspace',
    icon: Icons.business_outlined,
    activeIcon: Icons.business,
  ),
  AppNavItem(
    labelKey: 'navManageRentals',
    icon: Icons.apartment_outlined,
    activeIcon: Icons.apartment,
  ),
  AppNavItem(
    labelKey: 'navMessages',
    icon: Icons.chat_bubble_outline,
    activeIcon: Icons.chat_bubble,
  ),
  AppNavItem(
    labelKey: 'navMenu',
    icon: Icons.menu,
    activeIcon: Icons.menu_open,
  ),
];

/// Danh sách các item trong Bottom Bar của Người thuê trọ
const List<AppNavItem> tenantNavItems = [
  AppNavItem(
    labelKey: 'navHome',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
  ),
  AppNavItem(
    labelKey: 'navMyRental',
    icon: Icons.meeting_room_outlined,
    activeIcon: Icons.meeting_room,
  ),
  AppNavItem(
    labelKey: 'navMessages',
    icon: Icons.chat_bubble_outline,
    activeIcon: Icons.chat_bubble,
  ),
  AppNavItem(
    labelKey: 'navMenu',
    icon: Icons.menu,
    activeIcon: Icons.menu_open,
  ),
];
