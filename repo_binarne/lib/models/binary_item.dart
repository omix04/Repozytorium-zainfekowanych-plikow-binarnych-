class BinaryItem {
  final String id;
  final String fileName;
  final String fileNameDescription;
  final String platform;
  final String platformDescription;
  final String format;
  final String formatDescription;
  final String source;
  final String sourceDescription;
  final String status;
  final String statusDescription;
  final String storagePath;
  final String storagePathDescription;
  final String? md5; // Nowe pole
  final String? lastVerified; // Nowe pole

  BinaryItem({
    required this.id,
    required this.fileName,
    required this.fileNameDescription,
    required this.platform,
    required this.platformDescription,
    required this.format,
    required this.formatDescription,
    required this.source,
    required this.sourceDescription,
    required this.status,
    required this.statusDescription,
    required this.storagePath,
    required this.storagePathDescription,
    this.md5,
    this.lastVerified,
  });

  factory BinaryItem.fromMap(String id, Map<String, dynamic> data) {
    return BinaryItem(
      id: id,
      fileName: (data['fileName'] ?? '') as String,
      fileNameDescription: (data['fileNameDescription'] ?? '') as String,
      platform: (data['platform'] ?? '') as String,
      platformDescription: (data['platformDescription'] ?? '') as String,
      format: (data['format'] ?? '') as String,
      formatDescription: (data['formatDescription'] ?? '') as String,
      source: (data['source'] ?? '') as String,
      sourceDescription: (data['sourceDescription'] ?? '') as String,
      status: (data['status'] ?? '') as String,
      statusDescription: (data['statusDescription'] ?? '') as String,
      storagePath: (data['storagePath'] ?? '') as String,
      storagePathDescription: (data['storagePathDescription'] ?? '') as String,
      md5: data['md5'] as String?,
      lastVerified: data['lastVerified'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'fileName': fileName,
        'fileNameDescription': fileNameDescription,
        'platform': platform,
        'platformDescription': platformDescription,
        'format': format,
        'formatDescription': formatDescription,
        'source': source,
        'sourceDescription': sourceDescription,
        'status': status,
        'statusDescription': statusDescription,
        'storagePath': storagePath,
        'storagePathDescription': storagePathDescription,
        if (md5 != null) 'md5': md5,
        if (lastVerified != null) 'lastVerified': lastVerified,
      };
}