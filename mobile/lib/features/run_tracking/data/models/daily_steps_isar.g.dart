// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_steps_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyStepsIsarCollection on Isar {
  IsarCollection<DailyStepsIsar> get dailyStepsIsars => this.collection();
}

const DailyStepsIsarSchema = CollectionSchema(
  name: r'DailyStepsIsar',
  id: -4335895110418233884,
  properties: {
    r'dateKey': PropertySchema(
      id: 0,
      name: r'dateKey',
      type: IsarType.string,
    ),
    r'lastPedometerValue': PropertySchema(
      id: 1,
      name: r'lastPedometerValue',
      type: IsarType.long,
    ),
    r'lastUpdated': PropertySchema(
      id: 2,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'steps': PropertySchema(
      id: 3,
      name: r'steps',
      type: IsarType.long,
    )
  },
  estimateSize: _dailyStepsIsarEstimateSize,
  serialize: _dailyStepsIsarSerialize,
  deserialize: _dailyStepsIsarDeserialize,
  deserializeProp: _dailyStepsIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dailyStepsIsarGetId,
  getLinks: _dailyStepsIsarGetLinks,
  attach: _dailyStepsIsarAttach,
  version: '3.1.0+1',
);

int _dailyStepsIsarEstimateSize(
  DailyStepsIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.dateKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _dailyStepsIsarSerialize(
  DailyStepsIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.dateKey);
  writer.writeLong(offsets[1], object.lastPedometerValue);
  writer.writeDateTime(offsets[2], object.lastUpdated);
  writer.writeLong(offsets[3], object.steps);
}

DailyStepsIsar _dailyStepsIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyStepsIsar();
  object.dateKey = reader.readStringOrNull(offsets[0]);
  object.id = id;
  object.lastPedometerValue = reader.readLong(offsets[1]);
  object.lastUpdated = reader.readDateTimeOrNull(offsets[2]);
  object.steps = reader.readLong(offsets[3]);
  return object;
}

P _dailyStepsIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyStepsIsarGetId(DailyStepsIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyStepsIsarGetLinks(DailyStepsIsar object) {
  return [];
}

void _dailyStepsIsarAttach(
    IsarCollection<dynamic> col, Id id, DailyStepsIsar object) {
  object.id = id;
}

extension DailyStepsIsarByIndex on IsarCollection<DailyStepsIsar> {
  Future<DailyStepsIsar?> getByDateKey(String? dateKey) {
    return getByIndex(r'dateKey', [dateKey]);
  }

  DailyStepsIsar? getByDateKeySync(String? dateKey) {
    return getByIndexSync(r'dateKey', [dateKey]);
  }

  Future<bool> deleteByDateKey(String? dateKey) {
    return deleteByIndex(r'dateKey', [dateKey]);
  }

  bool deleteByDateKeySync(String? dateKey) {
    return deleteByIndexSync(r'dateKey', [dateKey]);
  }

  Future<List<DailyStepsIsar?>> getAllByDateKey(List<String?> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateKey', values);
  }

  List<DailyStepsIsar?> getAllByDateKeySync(List<String?> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dateKey', values);
  }

  Future<int> deleteAllByDateKey(List<String?> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dateKey', values);
  }

  int deleteAllByDateKeySync(List<String?> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dateKey', values);
  }

  Future<Id> putByDateKey(DailyStepsIsar object) {
    return putByIndex(r'dateKey', object);
  }

  Id putByDateKeySync(DailyStepsIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateKey(List<DailyStepsIsar> objects) {
    return putAllByIndex(r'dateKey', objects);
  }

  List<Id> putAllByDateKeySync(List<DailyStepsIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'dateKey', objects, saveLinks: saveLinks);
  }
}

extension DailyStepsIsarQueryWhereSort
    on QueryBuilder<DailyStepsIsar, DailyStepsIsar, QWhere> {
  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DailyStepsIsarQueryWhere
    on QueryBuilder<DailyStepsIsar, DailyStepsIsar, QWhereClause> {
  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterWhereClause> idBetween(
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

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterWhereClause>
      dateKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [null],
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterWhereClause>
      dateKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dateKey',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterWhereClause>
      dateKeyEqualTo(String? dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [dateKey],
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterWhereClause>
      dateKeyNotEqualTo(String? dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DailyStepsIsarQueryFilter
    on QueryBuilder<DailyStepsIsar, DailyStepsIsar, QFilterCondition> {
  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dateKey',
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dateKey',
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
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

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
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

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      lastPedometerValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastPedometerValue',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      lastPedometerValueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastPedometerValue',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      lastPedometerValueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastPedometerValue',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      lastPedometerValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastPedometerValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      lastUpdatedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastUpdated',
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      lastUpdatedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastUpdated',
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      lastUpdatedEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      lastUpdatedGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      lastUpdatedLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      lastUpdatedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUpdated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      stepsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      stepsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      stepsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterFilterCondition>
      stepsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'steps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyStepsIsarQueryObject
    on QueryBuilder<DailyStepsIsar, DailyStepsIsar, QFilterCondition> {}

extension DailyStepsIsarQueryLinks
    on QueryBuilder<DailyStepsIsar, DailyStepsIsar, QFilterCondition> {}

extension DailyStepsIsarQuerySortBy
    on QueryBuilder<DailyStepsIsar, DailyStepsIsar, QSortBy> {
  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy> sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy>
      sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy>
      sortByLastPedometerValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPedometerValue', Sort.asc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy>
      sortByLastPedometerValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPedometerValue', Sort.desc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy>
      sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy>
      sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy> sortBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.asc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy> sortByStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.desc);
    });
  }
}

extension DailyStepsIsarQuerySortThenBy
    on QueryBuilder<DailyStepsIsar, DailyStepsIsar, QSortThenBy> {
  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy> thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy>
      thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy>
      thenByLastPedometerValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPedometerValue', Sort.asc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy>
      thenByLastPedometerValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPedometerValue', Sort.desc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy>
      thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy>
      thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy> thenBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.asc);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QAfterSortBy> thenByStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.desc);
    });
  }
}

extension DailyStepsIsarQueryWhereDistinct
    on QueryBuilder<DailyStepsIsar, DailyStepsIsar, QDistinct> {
  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QDistinct> distinctByDateKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QDistinct>
      distinctByLastPedometerValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastPedometerValue');
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QDistinct>
      distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<DailyStepsIsar, DailyStepsIsar, QDistinct> distinctBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'steps');
    });
  }
}

extension DailyStepsIsarQueryProperty
    on QueryBuilder<DailyStepsIsar, DailyStepsIsar, QQueryProperty> {
  QueryBuilder<DailyStepsIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyStepsIsar, String?, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<DailyStepsIsar, int, QQueryOperations>
      lastPedometerValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastPedometerValue');
    });
  }

  QueryBuilder<DailyStepsIsar, DateTime?, QQueryOperations>
      lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<DailyStepsIsar, int, QQueryOperations> stepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'steps');
    });
  }
}
