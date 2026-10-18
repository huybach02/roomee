part of 'general_bloc.dart';

@immutable
sealed class GeneralEvent {
  const GeneralEvent();
}

final class GeneralProvincesLoadEvent extends GeneralEvent {
  const GeneralProvincesLoadEvent();
}

final class GeneralWardsLoadEvent extends GeneralEvent {
  final int provinceId;

  const GeneralWardsLoadEvent(this.provinceId);
}
