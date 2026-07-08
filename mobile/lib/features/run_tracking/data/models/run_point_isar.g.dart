// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_point_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRunPointIsarCollection on Isar {
  IsarCollection<RunPointIsar> get runPointIsars => this.collection();
}

const RunPointIsarSchema = CollectionSchema(
  name: r'RunPointIsar',
  id: 1767578006173424777,
  properties: {
    r'accuracy': PropertySchema(
      id: 0,
      name: r'accuracy',
      type: IsarType.double,
    ),
    r'clientRunId': PropertySchema(
      id: 1,
      name: r'clientRunId',
      type: IsarType.string,
    ),
    r'elevation': PropertySchema(
      id: 2,
      name: r'elevation',
      type: IsarType.double,
    ),
    r'isPaused': PropertySchema(
      id: 3,
      name: r'isPaused',
      type: IsarType.bool,
    ),
    r'lat': PropertySchema(
      id: 4,
      name: r'lat',
      type: IsarType.double,
    ),
    r'lng': PropertySchema(
      id: 5,
      name: r'lng',
      type: IsarType.double,
    ),
    r'sequence': PropertySchema(
      id: 6,
      name: r'sequence',
      type: IsarType.long,
    ),
    r'speed': PropertySchema(
      id: 7,
      name: r'speed',
      type: IsarType.double,
    ),
    r'timestamp': PropertySchema(
      id: 8,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _runPointIsarEstimateSize,
  serialize: _runPointIsarSerialize,
  deserialize: _runPointIsarDeserialize,
  deserializeProp: _runPointIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'clientRunId': IndexSchema(
      id: 2942396646733133561,
      name: r'clientRunId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'clientRunId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _runPointIsarGetId,
  getLinks: _runPointIsarGetLinks,
  attach: _runPointIsarAttach,
  version: '3.1.0+1',
);

int _runPointIsarEstimateSize(
  RunPointIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.clientRunId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _runPointIsarSerialize(
  RunPointIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.accuracy);
  writer.writeString(offsets[1], object.clientRunId);
  writer.writeDouble(offsets[2], object.elevation);
  writer.writeBool(offsets[3], object.isPaused);
  writer.writeDouble(offsets[4], object.lat);
  writer.writeDouble(offsets[5], object.lng);
  writer.writeLong(offsets[6], object.sequence);
  writer.writeDouble(offsets[7], object.speed);
  writer.writeDateTime(offsets[8], object.timestamp);
}

RunPointIsar _runPointIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RunPointIsar();
  object.accuracy = reader.readDoubleOrNull(offsets[0]);
  object.clientRunId = reader.readStringOrNull(offsets[1]);
  object.elevation = reader.readDoubleOrNull(offsets[2]);
  object.id = id;
  object.isPaused = reader.readBool(offsets[3]);
  object.lat = reader.readDoubleOrNull(offsets[4]);
  object.lng = reader.readDoubleOrNull(offsets[5]);
  object.sequence = reader.readLong(offsets[6]);
  object.speed = reader.readDoubleOrNull(offsets[7]);
  object.timestamp = reader.readDateTimeOrNull(offsets[8]);
  return object;
}

P _runPointIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _runPointIsarGetId(RunPointIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _runPointIsarGetLinks(RunPointIsar object) {
  return [];
}

void _runPointIsarAttach(
    IsarCollection<dynamic> col, Id id, RunPointIsar object) {
  object.id = id;
}

extension RunPointIsarQueryWhereSort
    on QueryBuilder<RunPointIsar, RunPointIsar, QWhere> {
  QueryBuilder<RunPointIsar, RunPointIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RunPointIsarQueryWhere
    on QueryBuilder<RunPointIsar, RunPointIsar, QWhereClause> {
  QueryBuilder<RunPointIsar, RunPointIsar, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterWhereClause> idBetween(
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

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterWhereClause>
      clientRunIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'clientRunId',
        value: [null],
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterWhereClause>
      clientRunIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'clientRunId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterWhereClause>
      clientRunIdEqualTo(String? clientRunId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'clientRunId',
        value: [clientRunId],
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterWhereClause>
      clientRunIdNotEqualTo(String? clientRunId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientRunId',
              lower: [],
              upper: [clientRunId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientRunId',
              lower: [clientRunId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientRunId',
              lower: [clientRunId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'clientRunId',
              lower: [],
              upper: [clientRunId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RunPointIsarQueryFilter
    on QueryBuilder<RunPointIsar, RunPointIsar, QFilterCondition> {
  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      accuracyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accuracy',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      accuracyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accuracy',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      accuracyEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accuracy',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      accuracyGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accuracy',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      accuracyLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accuracy',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      accuracyBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accuracy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'clientRunId',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'clientRunId',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientRunId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clientRunId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clientRunId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clientRunId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clientRunId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clientRunId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientRunId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientRunId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientRunId',
        value: '',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      clientRunIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientRunId',
        value: '',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      elevationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'elevation',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      elevationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'elevation',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      elevationEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'elevation',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      elevationGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'elevation',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      elevationLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'elevation',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      elevationBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'elevation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> idBetween(
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

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      isPausedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPaused',
        value: value,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> latIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lat',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      latIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lat',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> latEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      latGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> latLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> latBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> lngIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lng',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      lngIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lng',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> lngEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      lngGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> lngLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lng',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> lngBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lng',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      sequenceEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sequence',
        value: value,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      sequenceGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sequence',
        value: value,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      sequenceLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sequence',
        value: value,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      sequenceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sequence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      speedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'speed',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      speedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'speed',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> speedEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'speed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      speedGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'speed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> speedLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'speed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition> speedBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'speed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      timestampIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timestamp',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      timestampIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timestamp',
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      timestampEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      timestampLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterFilterCondition>
      timestampBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RunPointIsarQueryObject
    on QueryBuilder<RunPointIsar, RunPointIsar, QFilterCondition> {}

extension RunPointIsarQueryLinks
    on QueryBuilder<RunPointIsar, RunPointIsar, QFilterCondition> {}

extension RunPointIsarQuerySortBy
    on QueryBuilder<RunPointIsar, RunPointIsar, QSortBy> {
  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByAccuracy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracy', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByAccuracyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracy', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByClientRunId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy>
      sortByClientRunIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByElevation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevation', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByElevationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevation', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByIsPaused() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPaused', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByIsPausedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPaused', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lng', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByLngDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lng', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortBySequenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortBySpeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speed', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortBySpeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speed', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension RunPointIsarQuerySortThenBy
    on QueryBuilder<RunPointIsar, RunPointIsar, QSortThenBy> {
  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByAccuracy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracy', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByAccuracyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuracy', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByClientRunId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy>
      thenByClientRunIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByElevation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevation', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByElevationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevation', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByIsPaused() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPaused', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByIsPausedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPaused', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lng', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByLngDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lng', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenBySequenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenBySpeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speed', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenBySpeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speed', Sort.desc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension RunPointIsarQueryWhereDistinct
    on QueryBuilder<RunPointIsar, RunPointIsar, QDistinct> {
  QueryBuilder<RunPointIsar, RunPointIsar, QDistinct> distinctByAccuracy() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accuracy');
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QDistinct> distinctByClientRunId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientRunId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QDistinct> distinctByElevation() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'elevation');
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QDistinct> distinctByIsPaused() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPaused');
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QDistinct> distinctByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lat');
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QDistinct> distinctByLng() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lng');
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QDistinct> distinctBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sequence');
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QDistinct> distinctBySpeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'speed');
    });
  }

  QueryBuilder<RunPointIsar, RunPointIsar, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension RunPointIsarQueryProperty
    on QueryBuilder<RunPointIsar, RunPointIsar, QQueryProperty> {
  QueryBuilder<RunPointIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RunPointIsar, double?, QQueryOperations> accuracyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accuracy');
    });
  }

  QueryBuilder<RunPointIsar, String?, QQueryOperations> clientRunIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientRunId');
    });
  }

  QueryBuilder<RunPointIsar, double?, QQueryOperations> elevationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'elevation');
    });
  }

  QueryBuilder<RunPointIsar, bool, QQueryOperations> isPausedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPaused');
    });
  }

  QueryBuilder<RunPointIsar, double?, QQueryOperations> latProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lat');
    });
  }

  QueryBuilder<RunPointIsar, double?, QQueryOperations> lngProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lng');
    });
  }

  QueryBuilder<RunPointIsar, int, QQueryOperations> sequenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sequence');
    });
  }

  QueryBuilder<RunPointIsar, double?, QQueryOperations> speedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'speed');
    });
  }

  QueryBuilder<RunPointIsar, DateTime?, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
