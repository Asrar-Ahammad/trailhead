import '../../../run_tracking/application/nl_logging_service.dart';
import '../../domain/entities/parsed_run_log.dart';
import '../../domain/repositories/run_log_parser_repository.dart';

class AiRunLogParserRepository implements RunLogParserRepository {
  const AiRunLogParserRepository(this._loggingService);

  final NlLoggingService _loggingService;

  @override
  Future<ParsedRunLog?> parse(String text) {
    return _loggingService.parseLog(text);
  }
}
