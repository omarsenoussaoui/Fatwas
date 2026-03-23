enum TranscriptionStatus { pending, transcribing, done, error }

class Fatwa {
  final int? id;
  final String fileName;
  final String? filePath;
  final String? title;
  final String? transcription;
  final TranscriptionStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Fatwa({
    this.id,
    required this.fileName,
    this.filePath,
    this.title,
    this.transcription,
    this.status = TranscriptionStatus.pending,
    this.errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get displayTitle => (title != null && title!.isNotEmpty) ? title! : fileName;

  int get wordCount {
    if (transcription == null || transcription!.isEmpty) return 0;
    return transcription!.trim().split(RegExp(r'\s+')).length;
  }

  Fatwa copyWith({
    int? id,
    String? fileName,
    String? filePath,
    String? title,
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
      title: title ?? this.title,
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
      'title': title,
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
      title: map['title'] as String?,
      transcription: map['transcription'] as String?,
      status: TranscriptionStatus.values[map['status'] as int],
      errorMessage: map['errorMessage'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
