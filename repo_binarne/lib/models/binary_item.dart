class BinaryItem {
  final String id;
  final String fileName;
  final String platform;
  final String format;
  final String source;
  final String status;
  final String storagePath; // np. "binaries/sample.exe"

  BinaryItem({
    required this.id,
    required this.fileName,
    required this.platform,
    required this.format,
    required this.source,
    required this.status,
    required this.storagePath,
  });

  factory BinaryItem.fromMap(String id, Map<String, dynamic> data) {
    return BinaryItem(
      id: id,
      fileName: (data['fileName'] ?? '') as String,
      platform: (data['platform'] ?? '') as String,
      format: (data['format'] ?? '') as String,
      source: (data['source'] ?? '') as String,
      status: (data['status'] ?? '') as String,
      storagePath: (data['storagePath'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'fileName': fileName,
        'platform': platform,
        'format': format,
        'source': source,
        'status': status,
        'storagePath': storagePath,
      };
}
