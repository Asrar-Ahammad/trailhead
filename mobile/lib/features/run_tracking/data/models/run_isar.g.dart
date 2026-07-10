// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRunIsarCollection on Isar {
  IsarCollection<RunIsar> get runIsars => this.collection();
}

const RunIsarSchema = CollectionSchema(
  name: r'RunIsar',
  id: -2463788054546546243,
  properties: {
    r'activityType': PropertySchema(
      id: 0,
      name: r'activityType',
      type: IsarType.string,
    ),
    r'aiSummary': PropertySchema(
      id: 1,
      name: r'aiSummary',
      type: IsarType.string,
    ),
    r'avgCadenceSpm': PropertySchema(
      id: 2,
      name: r'avgCadenceSpm',
      type: IsarType.double,
    ),
    r'avgPaceSPerKm': PropertySchema(
      id: 3,
      name: r'avgPaceSPerKm',
      type: IsarType.double,
    ),
    r'avgStrideLengthM': PropertySchema(
      id: 4,
      name: r'avgStrideLengthM',
      type: IsarType.double,
    ),
    r'caloriesKcal': PropertySchema(
      id: 5,
      name: r'caloriesKcal',
      type: IsarType.double,
    ),
    r'clientRunId': PropertySchema(
      id: 6,
      name: r'clientRunId',
      type: IsarType.string,
    ),
    r'distanceM': PropertySchema(
      id: 7,
      name: r'distanceM',
      type: IsarType.double,
    ),
    r'durationS': PropertySchema(
      id: 8,
      name: r'durationS',
      type: IsarType.long,
    ),
    r'elevationGainM': PropertySchema(
      id: 9,
      name: r'elevationGainM',
      type: IsarType.double,
    ),
    r'endTime': PropertySchema(
      id: 10,
      name: r'endTime',
      type: IsarType.dateTime,
    ),
    r'lastModifiedAt': PropertySchema(
      id: 11,
      name: r'lastModifiedAt',
      type: IsarType.dateTime,
    ),
    r'startTime': PropertySchema(
      id: 12,
      name: r'startTime',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 13,
      name: r'status',
      type: IsarType.string,
    ),
    r'stepCount': PropertySchema(
      id: 14,
      name: r'stepCount',
      type: IsarType.long,
    ),
    r'synced': PropertySchema(
      id: 15,
      name: r'synced',
      type: IsarType.bool,
    ),
    r'syncedAt': PropertySchema(
      id: 16,
      name: r'syncedAt',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(
      id: 17,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _runIsarEstimateSize,
  serialize: _runIsarSerialize,
  deserialize: _runIsarDeserialize,
  deserializeProp: _runIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'clientRunId': IndexSchema(
      id: 2942396646733133561,
      name: r'clientRunId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'clientRunId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'startTime': IndexSchema(
      id: -3870335341264752872,
      name: r'startTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'startTime',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _runIsarGetId,
  getLinks: _runIsarGetLinks,
  attach: _runIsarAttach,
  version: '3.1.0+1',
);

int _runIsarEstimateSize(
  RunIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.activityType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.aiSummary;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.clientRunId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.status;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.title;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _runIsarSerialize(
  RunIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.activityType);
  writer.writeString(offsets[1], object.aiSummary);
  writer.writeDouble(offsets[2], object.avgCadenceSpm);
  writer.writeDouble(offsets[3], object.avgPaceSPerKm);
  writer.writeDouble(offsets[4], object.avgStrideLengthM);
  writer.writeDouble(offsets[5], object.caloriesKcal);
  writer.writeString(offsets[6], object.clientRunId);
  writer.writeDouble(offsets[7], object.distanceM);
  writer.writeLong(offsets[8], object.durationS);
  writer.writeDouble(offsets[9], object.elevationGainM);
  writer.writeDateTime(offsets[10], object.endTime);
  writer.writeDateTime(offsets[11], object.lastModifiedAt);
  writer.writeDateTime(offsets[12], object.startTime);
  writer.writeString(offsets[13], object.status);
  writer.writeLong(offsets[14], object.stepCount);
  writer.writeBool(offsets[15], object.synced);
  writer.writeDateTime(offsets[16], object.syncedAt);
  writer.writeString(offsets[17], object.title);
}

RunIsar _runIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RunIsar();
  object.activityType = reader.readStringOrNull(offsets[0]);
  object.aiSummary = reader.readStringOrNull(offsets[1]);
  object.avgCadenceSpm = reader.readDoubleOrNull(offsets[2]);
  object.avgPaceSPerKm = reader.readDoubleOrNull(offsets[3]);
  object.avgStrideLengthM = reader.readDoubleOrNull(offsets[4]);
  object.caloriesKcal = reader.readDoubleOrNull(offsets[5]);
  object.clientRunId = reader.readStringOrNull(offsets[6]);
  object.distanceM = reader.readDoubleOrNull(offsets[7]);
  object.durationS = reader.readLongOrNull(offsets[8]);
  object.elevationGainM = reader.readDoubleOrNull(offsets[9]);
  object.endTime = reader.readDateTimeOrNull(offsets[10]);
  object.id = id;
  object.lastModifiedAt = reader.readDateTimeOrNull(offsets[11]);
  object.startTime = reader.readDateTimeOrNull(offsets[12]);
  object.status = reader.readStringOrNull(offsets[13]);
  object.stepCount = reader.readLongOrNull(offsets[14]);
  object.synced = reader.readBool(offsets[15]);
  object.syncedAt = reader.readDateTimeOrNull(offsets[16]);
  object.title = reader.readStringOrNull(offsets[17]);
  return object;
}

P _runIsarDeserializeProp<P>(
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
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _runIsarGetId(RunIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _runIsarGetLinks(RunIsar object) {
  return [];
}

void _runIsarAttach(IsarCollection<dynamic> col, Id id, RunIsar object) {
  object.id = id;
}

extension RunIsarByIndex on IsarCollection<RunIsar> {
  Future<RunIsar?> getByClientRunId(String? clientRunId) {
    return getByIndex(r'clientRunId', [clientRunId]);
  }

  RunIsar? getByClientRunIdSync(String? clientRunId) {
    return getByIndexSync(r'clientRunId', [clientRunId]);
  }

  Future<bool> deleteByClientRunId(String? clientRunId) {
    return deleteByIndex(r'clientRunId', [clientRunId]);
  }

  bool deleteByClientRunIdSync(String? clientRunId) {
    return deleteByIndexSync(r'clientRunId', [clientRunId]);
  }

  Future<List<RunIsar?>> getAllByClientRunId(List<String?> clientRunIdValues) {
    final values = clientRunIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'clientRunId', values);
  }

  List<RunIsar?> getAllByClientRunIdSync(List<String?> clientRunIdValues) {
    final values = clientRunIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'clientRunId', values);
  }

  Future<int> deleteAllByClientRunId(List<String?> clientRunIdValues) {
    final values = clientRunIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'clientRunId', values);
  }

  int deleteAllByClientRunIdSync(List<String?> clientRunIdValues) {
    final values = clientRunIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'clientRunId', values);
  }

  Future<Id> putByClientRunId(RunIsar object) {
    return putByIndex(r'clientRunId', object);
  }

  Id putByClientRunIdSync(RunIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'clientRunId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByClientRunId(List<RunIsar> objects) {
    return putAllByIndex(r'clientRunId', objects);
  }

  List<Id> putAllByClientRunIdSync(List<RunIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'clientRunId', objects, saveLinks: saveLinks);
  }
}

extension RunIsarQueryWhereSort on QueryBuilder<RunIsar, RunIsar, QWhere> {
  QueryBuilder<RunIsar, RunIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhere> anyStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'startTime'),
      );
    });
  }
}

extension RunIsarQueryWhere on QueryBuilder<RunIsar, RunIsar, QWhereClause> {
  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> idBetween(
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

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> clientRunIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'clientRunId',
        value: [null],
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> clientRunIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'clientRunId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> clientRunIdEqualTo(
      String? clientRunId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'clientRunId',
        value: [clientRunId],
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> clientRunIdNotEqualTo(
      String? clientRunId) {
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

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> startTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'startTime',
        value: [null],
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> startTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> startTimeEqualTo(
      DateTime? startTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'startTime',
        value: [startTime],
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> startTimeNotEqualTo(
      DateTime? startTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [],
              upper: [startTime],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [startTime],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [startTime],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startTime',
              lower: [],
              upper: [startTime],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> startTimeGreaterThan(
    DateTime? startTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [startTime],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> startTimeLessThan(
    DateTime? startTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [],
        upper: [startTime],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterWhereClause> startTimeBetween(
    DateTime? lowerStartTime,
    DateTime? upperStartTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startTime',
        lower: [lowerStartTime],
        includeLower: includeLower,
        upper: [upperStartTime],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RunIsarQueryFilter
    on QueryBuilder<RunIsar, RunIsar, QFilterCondition> {
  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> activityTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'activityType',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      activityTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'activityType',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> activityTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> activityTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> activityTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> activityTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activityType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> activityTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'activityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> activityTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'activityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> activityTypeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'activityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> activityTypeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'activityType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> activityTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityType',
        value: '',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      activityTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'activityType',
        value: '',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aiSummary',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aiSummary',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiSummary',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aiSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aiSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aiSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aiSummary',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiSummary',
        value: '',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> aiSummaryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aiSummary',
        value: '',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> avgCadenceSpmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avgCadenceSpm',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      avgCadenceSpmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avgCadenceSpm',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> avgCadenceSpmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avgCadenceSpm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      avgCadenceSpmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avgCadenceSpm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> avgCadenceSpmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avgCadenceSpm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> avgCadenceSpmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avgCadenceSpm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> avgPaceSPerKmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avgPaceSPerKm',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      avgPaceSPerKmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avgPaceSPerKm',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> avgPaceSPerKmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avgPaceSPerKm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      avgPaceSPerKmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avgPaceSPerKm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> avgPaceSPerKmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avgPaceSPerKm',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> avgPaceSPerKmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avgPaceSPerKm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      avgStrideLengthMIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avgStrideLengthM',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      avgStrideLengthMIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avgStrideLengthM',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> avgStrideLengthMEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avgStrideLengthM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      avgStrideLengthMGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avgStrideLengthM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      avgStrideLengthMLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avgStrideLengthM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> avgStrideLengthMBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avgStrideLengthM',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> caloriesKcalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'caloriesKcal',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      caloriesKcalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'caloriesKcal',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> caloriesKcalEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caloriesKcal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> caloriesKcalGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'caloriesKcal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> caloriesKcalLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'caloriesKcal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> caloriesKcalBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'caloriesKcal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> clientRunIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'clientRunId',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> clientRunIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'clientRunId',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> clientRunIdEqualTo(
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> clientRunIdGreaterThan(
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> clientRunIdLessThan(
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> clientRunIdBetween(
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> clientRunIdStartsWith(
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> clientRunIdEndsWith(
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> clientRunIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientRunId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> clientRunIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientRunId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> clientRunIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientRunId',
        value: '',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      clientRunIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientRunId',
        value: '',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> distanceMIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'distanceM',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> distanceMIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'distanceM',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> distanceMEqualTo(
    double? value, {
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> distanceMGreaterThan(
    double? value, {
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> distanceMLessThan(
    double? value, {
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> distanceMBetween(
    double? lower,
    double? upper, {
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> durationSIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'durationS',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> durationSIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'durationS',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> durationSEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationS',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> durationSGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationS',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> durationSLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationS',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> durationSBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationS',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> elevationGainMIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'elevationGainM',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      elevationGainMIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'elevationGainM',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> elevationGainMEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'elevationGainM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      elevationGainMGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'elevationGainM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> elevationGainMLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'elevationGainM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> elevationGainMBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'elevationGainM',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> endTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endTime',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> endTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endTime',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> endTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> endTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> endTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTime',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> endTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> idBetween(
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

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> lastModifiedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      lastModifiedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModifiedAt',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> lastModifiedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModifiedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition>
      lastModifiedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastModifiedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> lastModifiedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastModifiedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> lastModifiedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastModifiedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> startTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startTime',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> startTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startTime',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> startTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> startTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> startTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTime',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> startTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> stepCountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stepCount',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> stepCountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stepCount',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> stepCountEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stepCount',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> stepCountGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stepCount',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> stepCountLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stepCount',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> stepCountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stepCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> syncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'synced',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> syncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'syncedAt',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> syncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'syncedAt',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> syncedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> syncedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> syncedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> syncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension RunIsarQueryObject
    on QueryBuilder<RunIsar, RunIsar, QFilterCondition> {}

extension RunIsarQueryLinks
    on QueryBuilder<RunIsar, RunIsar, QFilterCondition> {}

extension RunIsarQuerySortBy on QueryBuilder<RunIsar, RunIsar, QSortBy> {
  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByActivityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityType', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByActivityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityType', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByAiSummary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiSummary', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByAiSummaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiSummary', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByAvgCadenceSpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgCadenceSpm', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByAvgCadenceSpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgCadenceSpm', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByAvgPaceSPerKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgPaceSPerKm', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByAvgPaceSPerKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgPaceSPerKm', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByAvgStrideLengthM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgStrideLengthM', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByAvgStrideLengthMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgStrideLengthM', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByCaloriesKcal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesKcal', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByCaloriesKcalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesKcal', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByClientRunId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByClientRunIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByDistanceM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceM', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByDistanceMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceM', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByDurationS() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationS', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByDurationSDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationS', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByElevationGainM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevationGainM', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByElevationGainMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevationGainM', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByStepCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepCount', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByStepCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepCount', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension RunIsarQuerySortThenBy
    on QueryBuilder<RunIsar, RunIsar, QSortThenBy> {
  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByActivityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityType', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByActivityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityType', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByAiSummary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiSummary', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByAiSummaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiSummary', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByAvgCadenceSpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgCadenceSpm', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByAvgCadenceSpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgCadenceSpm', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByAvgPaceSPerKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgPaceSPerKm', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByAvgPaceSPerKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgPaceSPerKm', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByAvgStrideLengthM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgStrideLengthM', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByAvgStrideLengthMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgStrideLengthM', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByCaloriesKcal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesKcal', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByCaloriesKcalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesKcal', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByClientRunId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByClientRunIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByDistanceM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceM', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByDistanceMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceM', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByDurationS() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationS', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByDurationSDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationS', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByElevationGainM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevationGainM', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByElevationGainMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elevationGainM', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByLastModifiedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModifiedAt', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByStepCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepCount', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByStepCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stepCount', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension RunIsarQueryWhereDistinct
    on QueryBuilder<RunIsar, RunIsar, QDistinct> {
  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByActivityType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activityType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByAiSummary(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiSummary', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByAvgCadenceSpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avgCadenceSpm');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByAvgPaceSPerKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avgPaceSPerKm');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByAvgStrideLengthM() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avgStrideLengthM');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByCaloriesKcal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'caloriesKcal');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByClientRunId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientRunId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByDistanceM() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'distanceM');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByDurationS() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationS');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByElevationGainM() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'elevationGainM');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByLastModifiedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModifiedAt');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByStepCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stepCount');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'synced');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedAt');
    });
  }

  QueryBuilder<RunIsar, RunIsar, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension RunIsarQueryProperty
    on QueryBuilder<RunIsar, RunIsar, QQueryProperty> {
  QueryBuilder<RunIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RunIsar, String?, QQueryOperations> activityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activityType');
    });
  }

  QueryBuilder<RunIsar, String?, QQueryOperations> aiSummaryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiSummary');
    });
  }

  QueryBuilder<RunIsar, double?, QQueryOperations> avgCadenceSpmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avgCadenceSpm');
    });
  }

  QueryBuilder<RunIsar, double?, QQueryOperations> avgPaceSPerKmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avgPaceSPerKm');
    });
  }

  QueryBuilder<RunIsar, double?, QQueryOperations> avgStrideLengthMProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avgStrideLengthM');
    });
  }

  QueryBuilder<RunIsar, double?, QQueryOperations> caloriesKcalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'caloriesKcal');
    });
  }

  QueryBuilder<RunIsar, String?, QQueryOperations> clientRunIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientRunId');
    });
  }

  QueryBuilder<RunIsar, double?, QQueryOperations> distanceMProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'distanceM');
    });
  }

  QueryBuilder<RunIsar, int?, QQueryOperations> durationSProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationS');
    });
  }

  QueryBuilder<RunIsar, double?, QQueryOperations> elevationGainMProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'elevationGainM');
    });
  }

  QueryBuilder<RunIsar, DateTime?, QQueryOperations> endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<RunIsar, DateTime?, QQueryOperations> lastModifiedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModifiedAt');
    });
  }

  QueryBuilder<RunIsar, DateTime?, QQueryOperations> startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }

  QueryBuilder<RunIsar, String?, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<RunIsar, int?, QQueryOperations> stepCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stepCount');
    });
  }

  QueryBuilder<RunIsar, bool, QQueryOperations> syncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'synced');
    });
  }

  QueryBuilder<RunIsar, DateTime?, QQueryOperations> syncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedAt');
    });
  }

  QueryBuilder<RunIsar, String?, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
