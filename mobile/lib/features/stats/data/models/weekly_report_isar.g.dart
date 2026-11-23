// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_report_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWeeklyReportIsarCollection on Isar {
  IsarCollection<WeeklyReportIsar> get weeklyReportIsars => this.collection();
}

const WeeklyReportIsarSchema = CollectionSchema(
  name: r'WeeklyReportIsar',
  id: 1530243560192386204,
  properties: {
    r'avgCadenceSpm': PropertySchema(
      id: 0,
      name: r'avgCadenceSpm',
      type: IsarType.double,
    ),
    r'avgPaceSPerKm': PropertySchema(
      id: 1,
      name: r'avgPaceSPerKm',
      type: IsarType.double,
    ),
    r'avgStrideLengthM': PropertySchema(
      id: 2,
      name: r'avgStrideLengthM',
      type: IsarType.double,
    ),
    r'dailyStatsJson': PropertySchema(
      id: 3,
      name: r'dailyStatsJson',
      type: IsarType.string,
    ),
    r'endDate': PropertySchema(
      id: 4,
      name: r'endDate',
      type: IsarType.dateTime,
    ),
    r'runCount': PropertySchema(
      id: 5,
      name: r'runCount',
      type: IsarType.long,
    ),
    r'startDate': PropertySchema(
      id: 6,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'totalCalories': PropertySchema(
      id: 7,
      name: r'totalCalories',
      type: IsarType.double,
    ),
    r'totalDistanceM': PropertySchema(
      id: 8,
      name: r'totalDistanceM',
      type: IsarType.double,
    ),
    r'totalDurationS': PropertySchema(
      id: 9,
      name: r'totalDurationS',
      type: IsarType.long,
    ),
    r'totalSteps': PropertySchema(
      id: 10,
      name: r'totalSteps',
      type: IsarType.long,
    ),
    r'walkCount': PropertySchema(
      id: 11,
      name: r'walkCount',
      type: IsarType.long,
    ),
    r'weekNumber': PropertySchema(
      id: 12,
      name: r'weekNumber',
      type: IsarType.long,
    ),
    r'year': PropertySchema(
      id: 13,
      name: r'year',
      type: IsarType.long,
    )
  },
  estimateSize: _weeklyReportIsarEstimateSize,
  serialize: _weeklyReportIsarSerialize,
  deserialize: _weeklyReportIsarDeserialize,
  deserializeProp: _weeklyReportIsarDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _weeklyReportIsarGetId,
  getLinks: _weeklyReportIsarGetLinks,
  attach: _weeklyReportIsarAttach,
  version: '3.1.0+1',
);

int _weeklyReportIsarEstimateSize(
  WeeklyReportIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.dailyStatsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _weeklyReportIsarSerialize(
  WeeklyReportIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.avgCadenceSpm);
  writer.writeDouble(offsets[1], object.avgPaceSPerKm);
  writer.writeDouble(offsets[2], object.avgStrideLengthM);
  writer.writeString(offsets[3], object.dailyStatsJson);
  writer.writeDateTime(offsets[4], object.endDate);
  writer.writeLong(offsets[5], object.runCount);
  writer.writeDateTime(offsets[6], object.startDate);
  writer.writeDouble(offsets[7], object.totalCalories);
  writer.writeDouble(offsets[8], object.totalDistanceM);
  writer.writeLong(offsets[9], object.totalDurationS);
  writer.writeLong(offsets[10], object.totalSteps);
  writer.writeLong(offsets[11], object.walkCount);
  writer.writeLong(offsets[12], object.weekNumber);
  writer.writeLong(offsets[13], object.year);
}

WeeklyReportIsar _weeklyReportIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WeeklyReportIsar();
  object.avgCadenceSpm = reader.readDoubleOrNull(offsets[0]);
  object.avgPaceSPerKm = reader.readDoubleOrNull(offsets[1]);
  object.avgStrideLengthM = reader.readDoubleOrNull(offsets[2]);
  object.dailyStatsJson = reader.readStringOrNull(offsets[3]);
  object.endDate = reader.readDateTimeOrNull(offsets[4]);
  object.id = id;
  object.runCount = reader.readLongOrNull(offsets[5]);
  object.startDate = reader.readDateTimeOrNull(offsets[6]);
  object.totalCalories = reader.readDoubleOrNull(offsets[7]);
  object.totalDistanceM = reader.readDoubleOrNull(offsets[8]);
  object.totalDurationS = reader.readLongOrNull(offsets[9]);
  object.totalSteps = reader.readLongOrNull(offsets[10]);
  object.walkCount = reader.readLongOrNull(offsets[11]);
  object.weekNumber = reader.readLongOrNull(offsets[12]);
  object.year = reader.readLongOrNull(offsets[13]);
  return object;
}

P _weeklyReportIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _weeklyReportIsarGetId(WeeklyReportIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _weeklyReportIsarGetLinks(WeeklyReportIsar object) {
  return [];
}

void _weeklyReportIsarAttach(
    IsarCollection<dynamic> col, Id id, WeeklyReportIsar object) {
  object.id = id;
}

extension WeeklyReportIsarQueryWhereSort
    on QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QWhere> {
  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WeeklyReportIsarQueryWhere
    on QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QWhereClause> {
  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterWhereClause> idBetween(
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
}

extension WeeklyReportIsarQueryFilter
    on QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QFilterCondition> {
  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgCadenceSpmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avgCadenceSpm',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgCadenceSpmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avgCadenceSpm',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgCadenceSpmEqualTo(
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgCadenceSpmLessThan(
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgCadenceSpmBetween(
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgPaceSPerKmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avgPaceSPerKm',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgPaceSPerKmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avgPaceSPerKm',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgPaceSPerKmEqualTo(
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgPaceSPerKmLessThan(
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgPaceSPerKmBetween(
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgStrideLengthMIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avgStrideLengthM',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgStrideLengthMIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avgStrideLengthM',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgStrideLengthMEqualTo(
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      avgStrideLengthMBetween(
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dailyStatsJson',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dailyStatsJson',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyStatsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailyStatsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailyStatsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailyStatsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dailyStatsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dailyStatsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dailyStatsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dailyStatsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyStatsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      dailyStatsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dailyStatsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      endDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      endDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      endDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      endDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      endDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      endDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      runCountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'runCount',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      runCountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'runCount',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      runCountEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'runCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      runCountGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'runCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      runCountLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'runCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      runCountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'runCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      startDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      startDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      startDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      startDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      startDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      startDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalCaloriesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalCalories',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalCaloriesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalCalories',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalCaloriesEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCalories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalCaloriesGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCalories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalCaloriesLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCalories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalCaloriesBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCalories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDistanceMIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalDistanceM',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDistanceMIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalDistanceM',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDistanceMEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalDistanceM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDistanceMGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalDistanceM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDistanceMLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalDistanceM',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDistanceMBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalDistanceM',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDurationSIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalDurationS',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDurationSIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalDurationS',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDurationSEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalDurationS',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDurationSGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalDurationS',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDurationSLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalDurationS',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalDurationSBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalDurationS',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalStepsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalSteps',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalStepsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalSteps',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalStepsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalSteps',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalStepsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalSteps',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalStepsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalSteps',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      totalStepsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalSteps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      walkCountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'walkCount',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      walkCountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'walkCount',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      walkCountEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'walkCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      walkCountGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'walkCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      walkCountLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'walkCount',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      walkCountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'walkCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      weekNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weekNumber',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      weekNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weekNumber',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      weekNumberEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weekNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      weekNumberGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weekNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      weekNumberLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weekNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      weekNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weekNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      yearIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'year',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      yearIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'year',
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      yearEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'year',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      yearGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'year',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      yearLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'year',
        value: value,
      ));
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterFilterCondition>
      yearBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'year',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WeeklyReportIsarQueryObject
    on QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QFilterCondition> {}

extension WeeklyReportIsarQueryLinks
    on QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QFilterCondition> {}

extension WeeklyReportIsarQuerySortBy
    on QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QSortBy> {
  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByAvgCadenceSpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgCadenceSpm', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByAvgCadenceSpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgCadenceSpm', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByAvgPaceSPerKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgPaceSPerKm', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByAvgPaceSPerKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgPaceSPerKm', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByAvgStrideLengthM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgStrideLengthM', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByAvgStrideLengthMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgStrideLengthM', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByDailyStatsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyStatsJson', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByDailyStatsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyStatsJson', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByRunCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runCount', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByRunCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runCount', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByTotalCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByTotalDistanceM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDistanceM', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByTotalDistanceMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDistanceM', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByTotalDurationS() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationS', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByTotalDurationSDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationS', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByTotalSteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSteps', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByTotalStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSteps', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByWalkCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walkCount', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByWalkCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walkCount', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByWeekNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekNumber', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByWeekNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekNumber', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy> sortByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      sortByYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.desc);
    });
  }
}

extension WeeklyReportIsarQuerySortThenBy
    on QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QSortThenBy> {
  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByAvgCadenceSpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgCadenceSpm', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByAvgCadenceSpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgCadenceSpm', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByAvgPaceSPerKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgPaceSPerKm', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByAvgPaceSPerKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgPaceSPerKm', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByAvgStrideLengthM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgStrideLengthM', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByAvgStrideLengthMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avgStrideLengthM', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByDailyStatsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyStatsJson', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByDailyStatsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyStatsJson', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByRunCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runCount', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByRunCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runCount', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByTotalCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByTotalDistanceM() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDistanceM', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByTotalDistanceMDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDistanceM', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByTotalDurationS() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationS', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByTotalDurationSDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDurationS', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByTotalSteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSteps', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByTotalStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSteps', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByWalkCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walkCount', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByWalkCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walkCount', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByWeekNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekNumber', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByWeekNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weekNumber', Sort.desc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy> thenByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.asc);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QAfterSortBy>
      thenByYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.desc);
    });
  }
}

extension WeeklyReportIsarQueryWhereDistinct
    on QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct> {
  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByAvgCadenceSpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avgCadenceSpm');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByAvgPaceSPerKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avgPaceSPerKm');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByAvgStrideLengthM() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avgStrideLengthM');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByDailyStatsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailyStatsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endDate');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByRunCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'runCount');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCalories');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByTotalDistanceM() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalDistanceM');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByTotalDurationS() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalDurationS');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByTotalSteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalSteps');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByWalkCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'walkCount');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct>
      distinctByWeekNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weekNumber');
    });
  }

  QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QDistinct> distinctByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'year');
    });
  }
}

extension WeeklyReportIsarQueryProperty
    on QueryBuilder<WeeklyReportIsar, WeeklyReportIsar, QQueryProperty> {
  QueryBuilder<WeeklyReportIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WeeklyReportIsar, double?, QQueryOperations>
      avgCadenceSpmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avgCadenceSpm');
    });
  }

  QueryBuilder<WeeklyReportIsar, double?, QQueryOperations>
      avgPaceSPerKmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avgPaceSPerKm');
    });
  }

  QueryBuilder<WeeklyReportIsar, double?, QQueryOperations>
      avgStrideLengthMProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avgStrideLengthM');
    });
  }

  QueryBuilder<WeeklyReportIsar, String?, QQueryOperations>
      dailyStatsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailyStatsJson');
    });
  }

  QueryBuilder<WeeklyReportIsar, DateTime?, QQueryOperations>
      endDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endDate');
    });
  }

  QueryBuilder<WeeklyReportIsar, int?, QQueryOperations> runCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'runCount');
    });
  }

  QueryBuilder<WeeklyReportIsar, DateTime?, QQueryOperations>
      startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<WeeklyReportIsar, double?, QQueryOperations>
      totalCaloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCalories');
    });
  }

  QueryBuilder<WeeklyReportIsar, double?, QQueryOperations>
      totalDistanceMProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalDistanceM');
    });
  }

  QueryBuilder<WeeklyReportIsar, int?, QQueryOperations>
      totalDurationSProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalDurationS');
    });
  }

  QueryBuilder<WeeklyReportIsar, int?, QQueryOperations> totalStepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalSteps');
    });
  }

  QueryBuilder<WeeklyReportIsar, int?, QQueryOperations> walkCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walkCount');
    });
  }

  QueryBuilder<WeeklyReportIsar, int?, QQueryOperations> weekNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weekNumber');
    });
  }

  QueryBuilder<WeeklyReportIsar, int?, QQueryOperations> yearProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'year');
    });
  }
}
