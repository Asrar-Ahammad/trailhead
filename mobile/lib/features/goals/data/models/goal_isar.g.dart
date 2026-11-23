// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetGoalIsarCollection on Isar {
  IsarCollection<GoalIsar> get goalIsars => this.collection();
}

const GoalIsarSchema = CollectionSchema(
  name: r'GoalIsar',
  id: 6915484170167033734,
  properties: {
    r'dailyGoalMetric': PropertySchema(
      id: 0,
      name: r'dailyGoalMetric',
      type: IsarType.string,
    ),
    r'dailyGoalTarget': PropertySchema(
      id: 1,
      name: r'dailyGoalTarget',
      type: IsarType.double,
    ),
    r'key': PropertySchema(
      id: 2,
      name: r'key',
      type: IsarType.string,
    ),
    r'monthlyGoalMetric': PropertySchema(
      id: 3,
      name: r'monthlyGoalMetric',
      type: IsarType.string,
    ),
    r'monthlyGoalTarget': PropertySchema(
      id: 4,
      name: r'monthlyGoalTarget',
      type: IsarType.double,
    )
  },
  estimateSize: _goalIsarEstimateSize,
  serialize: _goalIsarSerialize,
  deserialize: _goalIsarDeserialize,
  deserializeProp: _goalIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _goalIsarGetId,
  getLinks: _goalIsarGetLinks,
  attach: _goalIsarAttach,
  version: '3.1.0+1',
);

int _goalIsarEstimateSize(
  GoalIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dailyGoalMetric.length * 3;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.monthlyGoalMetric.length * 3;
  return bytesCount;
}

void _goalIsarSerialize(
  GoalIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.dailyGoalMetric);
  writer.writeDouble(offsets[1], object.dailyGoalTarget);
  writer.writeString(offsets[2], object.key);
  writer.writeString(offsets[3], object.monthlyGoalMetric);
  writer.writeDouble(offsets[4], object.monthlyGoalTarget);
}

GoalIsar _goalIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GoalIsar();
  object.dailyGoalMetric = reader.readString(offsets[0]);
  object.dailyGoalTarget = reader.readDouble(offsets[1]);
  object.id = id;
  object.key = reader.readString(offsets[2]);
  object.monthlyGoalMetric = reader.readString(offsets[3]);
  object.monthlyGoalTarget = reader.readDouble(offsets[4]);
  return object;
}

P _goalIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _goalIsarGetId(GoalIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _goalIsarGetLinks(GoalIsar object) {
  return [];
}

void _goalIsarAttach(IsarCollection<dynamic> col, Id id, GoalIsar object) {
  object.id = id;
}

extension GoalIsarByIndex on IsarCollection<GoalIsar> {
  Future<GoalIsar?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  GoalIsar? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<GoalIsar?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<GoalIsar?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(GoalIsar object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(GoalIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<GoalIsar> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<GoalIsar> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension GoalIsarQueryWhereSort on QueryBuilder<GoalIsar, GoalIsar, QWhere> {
  QueryBuilder<GoalIsar, GoalIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GoalIsarQueryWhere on QueryBuilder<GoalIsar, GoalIsar, QWhereClause> {
  QueryBuilder<GoalIsar, GoalIsar, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<GoalIsar, GoalIsar, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterWhereClause> idBetween(
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

  QueryBuilder<GoalIsar, GoalIsar, QAfterWhereClause> keyEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'key',
        value: [key],
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterWhereClause> keyNotEqualTo(
      String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [key],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'key',
              lower: [],
              upper: [key],
              includeUpper: false,
            ));
      }
    });
  }
}

extension GoalIsarQueryFilter
    on QueryBuilder<GoalIsar, GoalIsar, QFilterCondition> {
  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalMetricEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalMetricGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalMetricLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalMetricBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailyGoalMetric',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalMetricStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dailyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalMetricEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dailyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalMetricContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dailyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalMetricMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dailyGoalMetric',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalMetricIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyGoalMetric',
        value: '',
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalMetricIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dailyGoalMetric',
        value: '',
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalTargetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyGoalTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalTargetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailyGoalTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalTargetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailyGoalTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      dailyGoalTargetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailyGoalTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> idBetween(
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

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'key',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> keyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'key',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> keyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'key',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition> keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'key',
        value: '',
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalMetricEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalMetricGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'monthlyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalMetricLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'monthlyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalMetricBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'monthlyGoalMetric',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalMetricStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'monthlyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalMetricEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'monthlyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalMetricContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'monthlyGoalMetric',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalMetricMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'monthlyGoalMetric',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalMetricIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlyGoalMetric',
        value: '',
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalMetricIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'monthlyGoalMetric',
        value: '',
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalTargetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlyGoalTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalTargetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'monthlyGoalTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalTargetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'monthlyGoalTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterFilterCondition>
      monthlyGoalTargetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'monthlyGoalTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension GoalIsarQueryObject
    on QueryBuilder<GoalIsar, GoalIsar, QFilterCondition> {}

extension GoalIsarQueryLinks
    on QueryBuilder<GoalIsar, GoalIsar, QFilterCondition> {}

extension GoalIsarQuerySortBy on QueryBuilder<GoalIsar, GoalIsar, QSortBy> {
  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> sortByDailyGoalMetric() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoalMetric', Sort.asc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> sortByDailyGoalMetricDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoalMetric', Sort.desc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> sortByDailyGoalTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoalTarget', Sort.asc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> sortByDailyGoalTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoalTarget', Sort.desc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> sortByMonthlyGoalMetric() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyGoalMetric', Sort.asc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> sortByMonthlyGoalMetricDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyGoalMetric', Sort.desc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> sortByMonthlyGoalTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyGoalTarget', Sort.asc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> sortByMonthlyGoalTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyGoalTarget', Sort.desc);
    });
  }
}

extension GoalIsarQuerySortThenBy
    on QueryBuilder<GoalIsar, GoalIsar, QSortThenBy> {
  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenByDailyGoalMetric() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoalMetric', Sort.asc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenByDailyGoalMetricDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoalMetric', Sort.desc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenByDailyGoalTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoalTarget', Sort.asc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenByDailyGoalTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoalTarget', Sort.desc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenByMonthlyGoalMetric() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyGoalMetric', Sort.asc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenByMonthlyGoalMetricDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyGoalMetric', Sort.desc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenByMonthlyGoalTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyGoalTarget', Sort.asc);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QAfterSortBy> thenByMonthlyGoalTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyGoalTarget', Sort.desc);
    });
  }
}

extension GoalIsarQueryWhereDistinct
    on QueryBuilder<GoalIsar, GoalIsar, QDistinct> {
  QueryBuilder<GoalIsar, GoalIsar, QDistinct> distinctByDailyGoalMetric(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailyGoalMetric',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QDistinct> distinctByDailyGoalTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailyGoalTarget');
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QDistinct> distinctByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QDistinct> distinctByMonthlyGoalMetric(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'monthlyGoalMetric',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GoalIsar, GoalIsar, QDistinct> distinctByMonthlyGoalTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'monthlyGoalTarget');
    });
  }
}

extension GoalIsarQueryProperty
    on QueryBuilder<GoalIsar, GoalIsar, QQueryProperty> {
  QueryBuilder<GoalIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<GoalIsar, String, QQueryOperations> dailyGoalMetricProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailyGoalMetric');
    });
  }

  QueryBuilder<GoalIsar, double, QQueryOperations> dailyGoalTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailyGoalTarget');
    });
  }

  QueryBuilder<GoalIsar, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<GoalIsar, String, QQueryOperations> monthlyGoalMetricProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'monthlyGoalMetric');
    });
  }

  QueryBuilder<GoalIsar, double, QQueryOperations> monthlyGoalTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'monthlyGoalTarget');
    });
  }
}
