class ConversionEvent {
  final String eventName;
  final double? value;
  final String? currency;
  final String? contentType;
  final String? contentId;
  final DateTime timestamp;

  ConversionEvent({
    required this.eventName,
    this.value,
    this.currency,
    this.contentType,
    this.contentId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, Object> toParameters() {
    final params = <String, Object>{};
    if (value != null) params['value'] = value!;
    if (currency != null) params['currency'] = currency!;
    if (contentType != null) params['content_type'] = contentType!;
    if (contentId != null) params['content_id'] = contentId!;
    return params;
  }

  @override
  String toString() =>
      'ConversionEvent(name: $eventName, value: $value $currency)';
}
