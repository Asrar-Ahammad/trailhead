import '../entities/parsed_run_log.dart';
import '../repositories/run_log_parser_repository.dart';

class ParseManualRunLog {
  const ParseManualRunLog(this._repository);

  final RunLogParserRepository _repository;

  Future<ParsedRunLog?> call(String text) {
    return _repository.parse(text);
  }
}
