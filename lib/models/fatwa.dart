enum TranscriptionStatus { pending, transcribing, done, error }

class Fatwa {
  final int? id;
  final String fileName;
  final String? filePath;
  final String? transcription;
  final TranscriptionStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Fatwa({
    this.id,
    required this.fileName,
    this.filePath,
    this.transcription,
    this.status = TranscriptionStatus.pending,
    this.errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Fatwa copyWith({
    int? id,
    String? fileName,
    String? filePath,
    String? transcription,
    TranscriptionStatus? status,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fatwa(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      transcription: transcription ?? this.transcription,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'transcription': transcription,
      'status': status.index,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Fatwa.fromMap(Map<String, dynamic> map) {
    return Fatwa(
      id: map['id'] as int?,
      fileName: map['fileName'] as String,
      filePath: map['filePath'] as String?,
      transcription: map['transcription'] as String?,
      status: TranscriptionStatus.values[map['status'] as int],
      errorMessage: map['errorMessage'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
