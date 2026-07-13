// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shoe_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetShoeIsarCollection on Isar {
  IsarCollection<ShoeIsar> get shoeIsars => this.collection();
}

const ShoeIsarSchema = CollectionSchema(
  name: r'ShoeIsar',
  id: -7994866456838286048,
  properties: {
    r'brand': PropertySchema(
      id: 0,
      name: r'brand',
      type: IsarType.string,
    ),
    r'clientShoeId': PropertySchema(
      id: 1,
      name: r'clientShoeId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'distanceM': PropertySchema(
      id: 3,
      name: r'distanceM',
      type: IsarType.double,
    ),
    r'isActive': PropertySchema(
      id: 4,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _shoeIsarEstimateSize,
  serialize: _shoeIsarSerialize,
  deserialize: _shoeIsarDeserialize,
  deserializeProp: _shoeIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'clientShoeId': IndexSchema(
      id: -2444811440984164204,
      name: r'clientShoeId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'clientShoeId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _shoeIsarGetId,
  getLinks: _shoeIsarGetLinks,
  attach: _shoeIsarAttach,
  version: '3.1.0+1',
);

int _shoeIsarEstimateSize(
  ShoeIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.brand;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.clientShoeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _shoeIsarSerialize(
  ShoeIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.brand);
  writer.writeString(offsets[1], object.clientShoeId);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeDouble(offsets[3], object.distanceM);
  writer.writeBool(offsets[4], object.isActive);
  writer.writeString(offsets[5], object.name);
}

ShoeIsar _shoeIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ShoeIsar();
  object.brand = reader.readStringOrNull(offsets[0]);
  object.clientShoeId = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readDateTimeOrNull(offsets[2]);
  object.distanceM = reader.readDouble(offsets[3]);
  object.id = id;
  object.isActive = reader.readBool(offsets[4]);
  object.name = reader.readStringOrNull(offsets[5]);
  return object;
}

P _shoeIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _shoeIsarGetId(ShoeIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _shoeIsarGetLinks(ShoeIsar object) {
  return [];
}

void _shoeIsarAttach(IsarCollection<dynamic> col, Id id, ShoeIsar object) {
  object.id = id;
}

extension ShoeIsarByIndex on IsarCollection<ShoeIsar> {
  Future<ShoeIsar?> getByClientShoeId(String? clientShoeId) {
    return getByIndex(r'clientShoeId', [clientShoeId]);
  }

  ShoeIsar? getByClientShoeIdSync(String? clientShoeId) {
    return getByIndexSync(r'clientShoeId', [clientShoeId]);
  }

  Future<bool> deleteByClientShoeId(String? clientShoeId) {
    return deleteByIndex(r'clientShoeId', [clientShoeId]);
  }

  bool deleteByClientShoeIdSync(String? clientShoeId) {
    return deleteByIndexSync(r'clientShoeId', [clientShoeId]);
  }

  Future<List<ShoeIsar?>> getAllByClientShoeId(
      List<String?> clientShoeIdValues) {
    final values = clientShoeIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'clientShoeId', values);
  }

  List<ShoeIsar?> getAllByClientShoeIdSync(List<String?> clientShoeIdValues) {
    final values = clientShoeIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'clientShoeId', values);
  }

  Future<int> deleteAllByClientShoeId(List<String?> clientShoeIdValues) {
    final values = clientShoeIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'clientShoeId', values);
  }

  int deleteAllByClientShoeIdSync(List<String?> clientShoeIdValues) {
    final values = clientShoeIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'clientShoeId', values);
  }

  Future<Id> putByClientShoeId(ShoeIsar object) {
    return putByIndex(r'clientShoeId', object);
  }

  Id putByClientShoeIdSync(ShoeIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'clientShoeId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByClientShoeId(List<ShoeIsar> objects) {
    return putAllByIndex(r'clientShoeId', objects);
  }

  List<Id> putAllByClientShoeIdSync(List<ShoeIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'clientShoeId', objects, saveLinks: saveLinks);
  }
}

extension ShoeIsarQueryWhereSort on QueryBuilder<ShoeIsar, ShoeIsar, QWhere> {
  QueryBuilder<ShoeIsar, ShoeIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ShoeIsarQueryWhere on QueryBuilder<ShoeIsar, ShoeIsar, QWhereClause> {
  QueryBuilder<ShoeIsar, ShoeIsar, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterWhereClause> clientShoeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'clientShoeId',
        value: [null],
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterWhereClause> clientShoeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'clientShoeId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterWhereClause> clientShoeIdEqualTo(
      String? clientShoeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'clientShoeId',
        value: [clientShoeId],
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterWhereClause> clientShoeIdNotEqualTo(
      String? clientShoeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientShoeId',
              lower: [],
              upper: [clientShoeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientShoeId',
              lower: [clientShoeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientShoeId',
              lower: [clientShoeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientShoeId',
              lower: [],
              upper: [clientShoeId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ShoeIsarQueryFilter
    on QueryBuilder<ShoeIsar, ShoeIsar, QFilterCondition> {
  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'brand',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'brand',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'brand',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'brand',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brand',
        value: '',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> brandIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'brand',
        value: '',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> clientShoeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'clientShoeId',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition>
      clientShoeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'clientShoeId',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> clientShoeIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientShoeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition>
      clientShoeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clientShoeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> clientShoeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clientShoeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> clientShoeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clientShoeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition>
      clientShoeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clientShoeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> clientShoeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clientShoeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> clientShoeIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientShoeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> clientShoeIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientShoeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition>
      clientShoeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientShoeId',
        value: '',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition>
      clientShoeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientShoeId',
        value: '',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> createdAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> distanceMEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'distanceM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> distanceMGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'distanceM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> distanceMLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'distanceM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> distanceMBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'distanceM',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> isActiveEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension ShoeIsarQueryObject
    on QueryBuilder<ShoeIsar, ShoeIsar, QFilterCondition> {}

extension ShoeIsarQueryLinks
    on QueryBuilder<ShoeIsar, ShoeIsar, QFilterCondition> {}

extension ShoeIsarQuerySortBy on QueryBuilder<ShoeIsar, ShoeIsar, QSortBy> {
  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByBrand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByBrandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.desc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByClientShoeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientShoeId', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByClientShoeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientShoeId', Sort.desc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByDistanceM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceM', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByDistanceMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceM', Sort.desc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension ShoeIsarQuerySortThenBy
    on QueryBuilder<ShoeIsar, ShoeIsar, QSortThenBy> {
  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByBrand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByBrandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.desc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByClientShoeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientShoeId', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByClientShoeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientShoeId', Sort.desc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByDistanceM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceM', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByDistanceMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceM', Sort.desc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension ShoeIsarQueryWhereDistinct
    on QueryBuilder<ShoeIsar, ShoeIsar, QDistinct> {
  QueryBuilder<ShoeIsar, ShoeIsar, QDistinct> distinctByBrand(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'brand', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QDistinct> distinctByClientShoeId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientShoeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QDistinct> distinctByDistanceM() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'distanceM');
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<ShoeIsar, ShoeIsar, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }
}

extension ShoeIsarQueryProperty
    on QueryBuilder<ShoeIsar, ShoeIsar, QQueryProperty> {
  QueryBuilder<ShoeIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ShoeIsar, String?, QQueryOperations> brandProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'brand');
    });
  }

  QueryBuilder<ShoeIsar, String?, QQueryOperations> clientShoeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientShoeId');
    });
  }

  QueryBuilder<ShoeIsar, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ShoeIsar, double, QQueryOperations> distanceMProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'distanceM');
    });
  }

  QueryBuilder<ShoeIsar, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<ShoeIsar, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }
}
