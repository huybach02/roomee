import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/features/general/data/general_remote_datasource.dart';

abstract class IGeneralRepository {
  Future<List<ProvinceModel>> getProvinces();
  Future<List<WardModel>> getWardsByProvince(int provinceId);
}

class GeneralRepository implements IGeneralRepository {
  final GeneralRemoteDataSource _remoteDataSource;

  GeneralRepository({GeneralRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GeneralRemoteDataSource();

  @override
  Future<List<ProvinceModel>> getProvinces() async {
    final response = await _remoteDataSource.getProvinces();

    final data = response.data;
    if (data == null) {
      throw ServerException(message: t('errors.invalidServerResponse'));
    }

    return data;
  }

  @override
  Future<List<WardModel>> getWardsByProvince(int provinceId) async {
    final response = await _remoteDataSource.getWardsByProvince(provinceId);

    final data = response.data;
    if (data == null) {
      throw ServerException(message: t('errors.invalidServerResponse'));
    }

    return data;
  }
}
