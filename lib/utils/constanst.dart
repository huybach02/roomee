import 'package:flutter/foundation.dart';

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
