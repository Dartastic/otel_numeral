// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_numeral/otel_numeral.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_numeral-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('returns.file records jurisdiction + period + status', () async {
    await tracedNumeral<String>(
      operation: 'returns.file',
      invoke: () async => const NumeralCallResult(
        value: 'ok',
        result: NumeralResult(
          returnId: 'r-1',
          status: 'filed',
          jurisdiction: 'TX',
          filingPeriod: 'quarterly',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('numeral returns.file')!);
    expect(a['numeral.return.id'], 'r-1');
    expect(a['numeral.status'], 'filed');
    expect(a['numeral.jurisdiction'], 'TX');
    expect(a['numeral.filing_period'], 'quarterly');
  });

  test('rejected sets span error', () async {
    await tracedNumeral<String>(
      operation: 'returns.file',
      invoke: () async => const NumeralCallResult(
        value: 'ok',
        result: NumeralResult(status: 'rejected'),
      ),
    );
    expect(
      spans.findSpanByName('numeral returns.file')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutNumeralInstrumentationAsync(() async {
      await tracedNumeral<String>(
        operation: 'transactions.list',
        invoke: () async => const NumeralCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('numeral '), isEmpty);
  });
}
