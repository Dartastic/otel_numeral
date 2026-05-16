// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_numeral_suppression.dart';

const _tracerName = 'dartastic_otel_libs_numeral';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class NumeralResult {
  const NumeralResult({
    this.transactionId,
    this.registrationId,
    this.returnId,
    this.kind,
    this.status,
    this.taxableAmountMinor,
    this.totalTaxMinor,
    this.currency,
    this.jurisdiction,
    this.filingPeriod,
    this.requestId,
    this.statusCode,
  });

  /// Transaction id.
  final String? transactionId;

  /// Registration id when calling per-jurisdiction endpoints.
  final String? registrationId;

  /// Return id when calling filings.
  final String? returnId;

  /// `sale` / `refund` / `adjustment` / `credit` / `tax_only`.
  final String? kind;

  /// `pending` / `posted` / `filed` / `remitted` / `rejected` /
  /// `cancelled`.
  final String? status;

  /// Taxable base in minor units.
  final int? taxableAmountMinor;

  /// Total tax in minor units.
  final int? totalTaxMinor;

  /// ISO 4217.
  final String? currency;

  /// US state / VAT jurisdiction (registration is per-jurisdiction).
  final String? jurisdiction;

  /// `monthly` / `quarterly` / `annual` / `semi_annual` — drives
  /// filing cadence cost.
  final String? filingPeriod;

  /// `X-Numeral-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class NumeralCallResult<T> {
  const NumeralCallResult({required this.value, this.result});
  final T value;
  final NumeralResult? result;
}

/// Wraps a Numeral API call in a CLIENT span. [operation] is one of
/// `transactions.create`, `transactions.list`, `transactions.update`,
/// `transactions.delete`, `customers.create`, `registrations.list`,
/// `registrations.activate`, `returns.list`, `returns.get`,
/// `returns.file`, `remittances.list`, `webhooks.list`.
Future<T> tracedNumeral<T>({
  required String operation,
  required Future<NumeralCallResult<T>> Function() invoke,
}) async {
  if (numeralInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'numeral',
    'rpc.method': operation,
    'numeral.operation': operation,
  };

  final span = _tracer().startSpan(
    'numeral $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.transactionId != null) {
        extras.add(OTel.attributeString(
          'numeral.transaction.id',
          r.result!.transactionId!,
        ));
      }
      if (r.result!.registrationId != null) {
        extras.add(OTel.attributeString(
          'numeral.registration.id',
          r.result!.registrationId!,
        ));
      }
      if (r.result!.returnId != null) {
        extras.add(OTel.attributeString(
          'numeral.return.id',
          r.result!.returnId!,
        ));
      }
      if (r.result!.kind != null) {
        extras.add(OTel.attributeString(
          'numeral.transaction.kind',
          r.result!.kind!,
        ));
      }
      if (r.result!.status != null) {
        extras.add(OTel.attributeString(
          'numeral.status',
          r.result!.status!,
        ));
        if (r.result!.status == 'rejected' || r.result!.status == 'cancelled') {
          span.setStatus(
            SpanStatusCode.Error,
            'Numeral ${r.result!.status}',
          );
        }
      }
      if (r.result!.taxableAmountMinor != null) {
        extras.add(OTel.attributeInt(
          'numeral.taxable.minor',
          r.result!.taxableAmountMinor!,
        ));
      }
      if (r.result!.totalTaxMinor != null) {
        extras.add(OTel.attributeInt(
          'numeral.tax.total.minor',
          r.result!.totalTaxMinor!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTel.attributeString(
          'numeral.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.jurisdiction != null) {
        extras.add(OTel.attributeString(
          'numeral.jurisdiction',
          r.result!.jurisdiction!,
        ));
      }
      if (r.result!.filingPeriod != null) {
        extras.add(OTel.attributeString(
          'numeral.filing_period',
          r.result!.filingPeriod!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'numeral.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Numeral HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
