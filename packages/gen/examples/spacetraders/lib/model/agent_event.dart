class AgentEvent {
  AgentEvent({
    required this.id,
    required this.type,
    required this.message,
    required this.data,
    required this.createdAt,
  });

  factory AgentEvent.fromJson(Map<String, dynamic> json) {
    return AgentEvent(
      id: json['id'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String type;
  final String message;
  final dynamic data;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
