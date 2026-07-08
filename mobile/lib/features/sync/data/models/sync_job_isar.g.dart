// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_job_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncJobIsarCollection on Isar {
  IsarCollection<SyncJobIsar> get syncJobIsars => this.collection();
}

const SyncJobIsarSchema = CollectionSchema(
  name: r'SyncJobIsar',
  id: 139974279442619914,
  properties: {
    r'attempts': PropertySchema(
      id: 0,
      name: r'attempts',
      type: IsarType.long,
    ),
    r'clientRunId': PropertySchema(
      id: 1,
      name: r'clientRunId',
      type: IsarType.string,
    ),
    r'nextRetryAt': PropertySchema(
      id: 2,
      name: r'nextRetryAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 3,
      name: r'status',
      type: IsarType.string,
    )
  },
  estimateSize: _syncJobIsarEstimateSize,
  serialize: _syncJobIsarSerialize,
  deserialize: _syncJobIsarDeserialize,
  deserializeProp: _syncJobIsarDeserializeProp,
  idName: r'id',
  indexes: {
    r'clientRunId': IndexSchema(
      id: 2942396646733133561,
      name: r'clientRunId',
      unique: true,
      replace: true,
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
  getId: _syncJobIsarGetId,
  getLinks: _syncJobIsarGetLinks,
  attach: _syncJobIsarAttach,
  version: '3.1.0+1',
);

int _syncJobIsarEstimateSize(
  SyncJobIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.clientRunId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _syncJobIsarSerialize(
  SyncJobIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.attempts);
  writer.writeString(offsets[1], object.clientRunId);
  writer.writeDateTime(offsets[2], object.nextRetryAt);
  writer.writeString(offsets[3], object.status);
}

SyncJobIsar _syncJobIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncJobIsar();
  object.attempts = reader.readLong(offsets[0]);
  object.clientRunId = reader.readString(offsets[1]);
  object.id = id;
  object.nextRetryAt = reader.readDateTimeOrNull(offsets[2]);
  object.status = reader.readString(offsets[3]);
  return object;
}

P _syncJobIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncJobIsarGetId(SyncJobIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncJobIsarGetLinks(SyncJobIsar object) {
  return [];
}

void _syncJobIsarAttach(
    IsarCollection<dynamic> col, Id id, SyncJobIsar object) {
  object.id = id;
}

extension SyncJobIsarByIndex on IsarCollection<SyncJobIsar> {
  Future<SyncJobIsar?> getByClientRunId(String clientRunId) {
    return getByIndex(r'clientRunId', [clientRunId]);
  }

  SyncJobIsar? getByClientRunIdSync(String clientRunId) {
    return getByIndexSync(r'clientRunId', [clientRunId]);
  }

  Future<bool> deleteByClientRunId(String clientRunId) {
    return deleteByIndex(r'clientRunId', [clientRunId]);
  }

  bool deleteByClientRunIdSync(String clientRunId) {
    return deleteByIndexSync(r'clientRunId', [clientRunId]);
  }

  Future<List<SyncJobIsar?>> getAllByClientRunId(
      List<String> clientRunIdValues) {
    final values = clientRunIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'clientRunId', values);
  }

  List<SyncJobIsar?> getAllByClientRunIdSync(List<String> clientRunIdValues) {
    final values = clientRunIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'clientRunId', values);
  }

  Future<int> deleteAllByClientRunId(List<String> clientRunIdValues) {
    final values = clientRunIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'clientRunId', values);
  }

  int deleteAllByClientRunIdSync(List<String> clientRunIdValues) {
    final values = clientRunIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'clientRunId', values);
  }

  Future<Id> putByClientRunId(SyncJobIsar object) {
    return putByIndex(r'clientRunId', object);
  }

  Id putByClientRunIdSync(SyncJobIsar object, {bool saveLinks = true}) {
    return putByIndexSync(r'clientRunId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByClientRunId(List<SyncJobIsar> objects) {
    return putAllByIndex(r'clientRunId', objects);
  }

  List<Id> putAllByClientRunIdSync(List<SyncJobIsar> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'clientRunId', objects, saveLinks: saveLinks);
  }
}

extension SyncJobIsarQueryWhereSort
    on QueryBuilder<SyncJobIsar, SyncJobIsar, QWhere> {
  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncJobIsarQueryWhere
    on QueryBuilder<SyncJobIsar, SyncJobIsar, QWhereClause> {
  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterWhereClause> idBetween(
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterWhereClause> clientRunIdEqualTo(
      String clientRunId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'clientRunId',
        value: [clientRunId],
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterWhereClause>
      clientRunIdNotEqualTo(String clientRunId) {
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

extension SyncJobIsarQueryFilter
    on QueryBuilder<SyncJobIsar, SyncJobIsar, QFilterCondition> {
  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> attemptsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      attemptsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      attemptsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attempts',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> attemptsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attempts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      clientRunIdEqualTo(
    String value, {
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      clientRunIdGreaterThan(
    String value, {
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      clientRunIdLessThan(
    String value, {
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      clientRunIdBetween(
    String lower,
    String upper, {
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      clientRunIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientRunId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      clientRunIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientRunId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      clientRunIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientRunId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      clientRunIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientRunId',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      nextRetryAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nextRetryAt',
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      nextRetryAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nextRetryAt',
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      nextRetryAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      nextRetryAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      nextRetryAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextRetryAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      nextRetryAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextRetryAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> statusEqualTo(
    String value, {
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> statusLessThan(
    String value, {
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      statusStartsWith(
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> statusEndsWith(
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> statusContains(
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition> statusMatches(
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

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }
}

extension SyncJobIsarQueryObject
    on QueryBuilder<SyncJobIsar, SyncJobIsar, QFilterCondition> {}

extension SyncJobIsarQueryLinks
    on QueryBuilder<SyncJobIsar, SyncJobIsar, QFilterCondition> {}

extension SyncJobIsarQuerySortBy
    on QueryBuilder<SyncJobIsar, SyncJobIsar, QSortBy> {
  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> sortByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> sortByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> sortByClientRunId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.asc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> sortByClientRunIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.desc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> sortByNextRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.asc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> sortByNextRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.desc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension SyncJobIsarQuerySortThenBy
    on QueryBuilder<SyncJobIsar, SyncJobIsar, QSortThenBy> {
  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> thenByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.asc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> thenByAttemptsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attempts', Sort.desc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> thenByClientRunId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.asc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> thenByClientRunIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientRunId', Sort.desc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> thenByNextRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.asc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> thenByNextRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.desc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension SyncJobIsarQueryWhereDistinct
    on QueryBuilder<SyncJobIsar, SyncJobIsar, QDistinct> {
  QueryBuilder<SyncJobIsar, SyncJobIsar, QDistinct> distinctByAttempts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attempts');
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QDistinct> distinctByClientRunId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientRunId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QDistinct> distinctByNextRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextRetryAt');
    });
  }

  QueryBuilder<SyncJobIsar, SyncJobIsar, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }
}

extension SyncJobIsarQueryProperty
    on QueryBuilder<SyncJobIsar, SyncJobIsar, QQueryProperty> {
  QueryBuilder<SyncJobIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncJobIsar, int, QQueryOperations> attemptsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attempts');
    });
  }

  QueryBuilder<SyncJobIsar, String, QQueryOperations> clientRunIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientRunId');
    });
  }

  QueryBuilder<SyncJobIsar, DateTime?, QQueryOperations> nextRetryAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextRetryAt');
    });
  }

  QueryBuilder<SyncJobIsar, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}
