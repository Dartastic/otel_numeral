// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_numeral/otel_numeral.dart';

/// Traces Numeral calls with OpenTelemetry.
///
/// `otel_numeral` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Numeral call in
/// [tracedNumeral]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'numeral-example');

  // Wraps a Numeral API call in a CLIENT span.
  final numeralId = await tracedNumeral<String>(
    operation: 'transactions.create',
    invoke: () async {
      // Make the Numeral call here, then report what it returned.
      const id = 'numeral_8f3a2c';
      return const NumeralCallResult(
          value: id,
          result: NumeralResult(
              transactionId: 'transaction_8f3a2c',
              registrationId: 'registration_8f3a2c',
              returnId: 'return_8f3a2c',
              kind: 'sale',
              status: 'pending',
              taxableAmountMinor: 1999,
              totalTaxMinor: 1,
              currency: 'usd',
              jurisdiction: 'example',
              filingPeriod: 'monthly',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedNumeral transactions.create returned $numeralId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutNumeralInstrumentationAsync.
  await runWithoutNumeralInstrumentationAsync(
    () => tracedNumeral<String>(
      operation: 'transactions.create',
      invoke: () async {
        const id = 'numeral_8f3a2c';
        return const NumeralCallResult(
            value: id,
            result: NumeralResult(
                transactionId: 'transaction_8f3a2c',
                registrationId: 'registration_8f3a2c',
                returnId: 'return_8f3a2c',
                kind: 'sale',
                status: 'pending',
                taxableAmountMinor: 1999,
                totalTaxMinor: 1,
                currency: 'usd',
                jurisdiction: 'example',
                filingPeriod: 'monthly',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
