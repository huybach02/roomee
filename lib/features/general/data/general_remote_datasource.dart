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

  Future<ApiResponse<Map<String, SyncResultDto>>> sync(
    Map<String, List<SyncItemDto>> entities,
  ) {
    final requestBody = {
      'entities': entities.map(
        (key, value) => MapEntry(
          key,
          value.map((e) => e.toJson()).toList(),
        ),
      ),
    };

    return post<Map<String, SyncResultDto>>(
      '/general/sync',
      data: requestBody,
      fromJsonT: (json) {
        if (json is! Map) return {};
        return json.map(
          (key, value) => MapEntry(
            key.toString(),
            SyncResultDto.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          ),
        );
      },
    );
  }
}

