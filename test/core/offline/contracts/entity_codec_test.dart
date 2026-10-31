import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/offline/contracts/entity_codec.dart';

class _Record {
  final String id;
  final String name;

  const _Record(this.id, this.name);
}

class _RecordCodec implements EntityCodec<_Record, String> {
  @override
  String getId(_Record entity) => entity.id;

  @override
  Map<String, dynamic> toJson(_Record entity) => {
    'id': entity.id,
    'name': entity.name,
  };

  @override
  _Record fromJson(Map<String, dynamic> json) =>
      _Record(json['id'] as String, json['name'] as String);
}

void main() {
  test('codec exposes ID and JSON conversions through its contract', () {
    const entity = _Record('record-id', 'Example');
    final codec = _RecordCodec();

    expect(codec.getId(entity), 'record-id');
    expect(codec.toJson(entity), {'id': 'record-id', 'name': 'Example'});
    final decoded = codec.fromJson({'id': 'record-id', 'name': 'Example'});
    expect(decoded.id, 'record-id');
    expect(decoded.name, 'Example');
  });
}
