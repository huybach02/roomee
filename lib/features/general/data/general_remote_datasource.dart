import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/network.dart';

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
}
