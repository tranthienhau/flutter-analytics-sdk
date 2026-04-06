enum AnalyticsSource { meta, firebase, custom }

class AnalyticsEvent {
  final String name;
  final Map<String, Object> parameters;
  final DateTime timestamp;
  final AnalyticsSource source;

  const AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
    required this.source,
  });

  AnalyticsEvent copyWith({
    String? name,
    Map<String, Object>? parameters,
    DateTime? timestamp,
    AnalyticsSource? source,
  }) {
    return AnalyticsEvent(
      name: name ?? this.name,
      parameters: parameters ?? this.parameters,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
      'source': source.name,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name'] as String,
      parameters: Map<String, Object>.from(json['parameters'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: AnalyticsSource.values.firstWhere(
        (s) => s.name == json['source'],
      ),
    );
  }

  @override
  String toString() =>
      'AnalyticsEvent(name: $name, source: ${source.name}, params: $parameters)';
}
