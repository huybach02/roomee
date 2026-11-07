import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';

class GeneralRemoteDataSource extends BaseService {
  GeneralRemoteDataSource({super.client});

  Future<ApiResponse<List<ProvinceModel>>> getProvinces() {
    return getDataAll<List<ProvinceModel>>(
      '/general/provinces',
      fromJsonT: (json) => (json as List)
          .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<List<WardModel>>> getWardsByProvince(int provinceId) {
    return getDataAll<List<WardModel>>(
      '/general/provinces/$provinceId/wards',
      fromJsonT: (json) => (json as List)
          .map((e) => WardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<SyncResponseDto>> sync({
    List<SyncMutation>? mutations,
    required Map<String, List<SyncItemDto>> entities,
  }) {
    final requestBody = {
      if (mutations != null && mutations.isNotEmpty)
        'mutations': mutations.map((m) => m.toJson()).toList(),
      'entities': entities.map(
        (key, value) => MapEntry(
          key,
          value.map((e) => e.toJson()).toList(),
        ),
      ),
    };

    return post<SyncResponseDto>(
      '/general/sync',
      data: requestBody,
      fromJsonT: (json) {
        if (json is! Map) return const SyncResponseDto();
        return SyncResponseDto.fromJson(Map<String, dynamic>.from(json));
      },
    );
  }
}
