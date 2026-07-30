import 'dart:convert';

import '../config/era_hatch_config.dart';
import '../core/hatch_models.dart';
import 'flight_attribution.dart';
import 'nest_vault.dart';
import 'roost_agent.dart';

/// POSTs the composed attribution + device payload to the config endpoint
/// and unpacks the response into a `RelayReply`. On success caches the
/// returned URL to `CoopSafe` so a subsequent cold launch skips the whole
/// pipeline (see the "Config Request Contract" in the docs).
class SignalExchange {
  SignalExchange(this._agent, this._safe);

  final HerderAgent _agent;
  final CoopSafe _safe;

  Future<RelayReply> request(Map<String, dynamic> payload) async {
    if (!LanternRallyEnv.grayCredentialsReady) {
      return RelayReply.rejected('credentials_unavailable');
    }
    try {
      lbrTrace(() => '[LBR.EXCHANGE] request ${jsonEncode(payload)}');
      final response = await _agent
          .post(
            Uri.parse(LanternRallyEnv.endpoint),
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      lbrTrace(
        () => '[LBR.EXCHANGE] response ${response.statusCode} '
            '${response.body}',
      );
      if (response.statusCode != 200) {
        return RelayReply.rejected('http_${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return RelayReply.rejected('invalid_response');
      final reply = RelayReply.fromJson(Map<String, dynamic>.from(decoded));
      if (reply.hasDestination) {
        await _safe.cacheUrl(reply.url!, reply.expiresAt);
      }
      return reply;
    } catch (error) {
      lbrTrace(() => '[LBR.EXCHANGE] failed: $error');
      return RelayReply.rejected('network_failure');
    }
  }
}
