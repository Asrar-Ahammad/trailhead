import '../entities/parsed_run_log.dart';

abstract interface class RunLogParserRepository {
  Future<ParsedRunLog?> parse(String text);
}
