import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';
import 'package:public_file_saver/public_file_saver.dart';

import '../services/medical_record_service.dart';
import '../services/patient_service.dart';
import '../services/session_manager.dart';
import '../utils/appcolors.dart';
import '../utils/auth_storage.dart';

class DocumentViewerScreen extends StatefulWidget {
  final Map<String, dynamic> document;

  const DocumentViewerScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState
    extends State<DocumentViewerScreen> {
  final PatientService _patientService = PatientService();

  final MedicalRecordService _medicalRecordService =
      MedicalRecordService();

  final AuthStorage _authStorage = AuthStorage();

  final PublicFileSaver _fileSaver =
      PublicFileSaver();

  String? _error;

  Uint8List? _documentBytes;

  Map<String, dynamic>? _metadata;

  bool _isLoading = true;

  bool _isDownloading = false;

  bool _isPdf = false;

  String? _documentId;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  // ===========================================================================
  // LOAD DOCUMENT
  // ===========================================================================

  Future<void> _loadDocument() async {
    try {
      print(
        '========== DOCUMENT VIEW START ==========',
      );

      // -----------------------------------------------------------------------
      // DOCUMENT ID
      // -----------------------------------------------------------------------

      final documentId =
          widget.document['documentId'] ??
          widget.document['_id'] ??
          widget.document['id'];

      print('DOCUMENT ID: $documentId');

      if (documentId == null ||
          documentId.toString().trim().isEmpty) {
        throw Exception(
          'Document ID was not returned by the server.',
        );
      }

      // -----------------------------------------------------------------------
      // PATIENT
      // -----------------------------------------------------------------------

      final patientResponse =
          await _patientService.getMyPatientProfile();

      Map<String, dynamic> patientData;

      final rawPatientData =
          patientResponse['data'];

      if (rawPatientData is Map) {
        patientData =
            Map<String, dynamic>.from(
          rawPatientData,
        );
      } else {
        patientData =
            Map<String, dynamic>.from(
          patientResponse,
        );
      }

      final patientId =
          patientData['_id'];

      print('PATIENT ID: $patientId');

      if (patientId == null ||
          patientId.toString().trim().isEmpty) {
        throw Exception(
          'Patient UUID was not returned by the server.',
        );
      }

      final patientIdString =
          patientId.toString();

      final documentIdString =
          documentId.toString();

      // -----------------------------------------------------------------------
      // GET DOCUMENT METADATA
      // -----------------------------------------------------------------------

      print(
        'GETTING DOCUMENT METADATA...',
      );

      final metadataResponse =
          await _medicalRecordService
              .getDocumentMetadata(
        patientId: patientIdString,
        documentId: documentIdString,
      );

      Map<String, dynamic> metadata;

      final metadataData =
          metadataResponse['data'];

      if (metadataData is Map) {
        metadata =
            Map<String, dynamic>.from(
          metadataData,
        );
      } else {
        metadata =
            Map<String, dynamic>.from(
          metadataResponse,
        );
      }

      print(
        'DOCUMENT METADATA: $metadata',
      );

      // -----------------------------------------------------------------------
      // GET TEMPORARY DOCUMENT URL
      // -----------------------------------------------------------------------

      print(
        'GETTING DOCUMENT DOWNLOAD URL...',
      );

      final url =
          await _medicalRecordService
              .getDocumentUrl(
        patientId: patientIdString,
        documentId: documentIdString,
      );

      print(
        'DOCUMENT VIEW URL: $url',
      );

      if (url.trim().isEmpty) {
        throw Exception(
          'The server returned an empty document URL.',
        );
      }

      // -----------------------------------------------------------------------
      // ACCESS TOKEN
      // -----------------------------------------------------------------------

      final token =
          await _authStorage.getAccessToken();

      if (token == null ||
          token.trim().isEmpty) {
        throw Exception(
          'No access token found.',
        );
      }

      print(
        'ACCESS TOKEN FOUND: true',
      );

      // -----------------------------------------------------------------------
      // DOWNLOAD DOCUMENT
      // -----------------------------------------------------------------------

      print(
        'DOWNLOADING DOCUMENT...',
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        'DOCUMENT DOWNLOAD STATUS: '
        '${response.statusCode}',
      );

      print(
        'DOCUMENT CONTENT TYPE: '
        '${response.headers['content-type']}',
      );

      print(
        'DOCUMENT SIZE: '
        '${response.bodyBytes.length} bytes',
      );

      // -----------------------------------------------------------------------
      // SESSION EXPIRED
      // -----------------------------------------------------------------------

      if (response.statusCode == 401) {
        SessionManager.instance.handleSessionExpired(
          usedToken: token,
        );

        throw Exception(
          'Your session has expired. Please sign in again.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Document download failed '
          '(HTTP ${response.statusCode}).',
        );
      }

      final bytes =
          response.bodyBytes;

      if (bytes.isEmpty) {
        throw Exception(
          'The server returned an empty document.',
        );
      }

      // -----------------------------------------------------------------------
      // DETECT DOCUMENT TYPE
      // -----------------------------------------------------------------------

      final contentType =
          response.headers['content-type']
                  ?.toLowerCase() ??
              '';

      final isPdf =
          contentType.contains(
                'application/pdf',
              ) ||
          (
            bytes.length >= 4 &&
            bytes[0] == 0x25 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x44 &&
            bytes[3] == 0x46
          );

      final isImage =
          contentType.startsWith('image/') ||
          _looksLikeImage(bytes);

      if (!isPdf && !isImage) {
        throw Exception(
          'The downloaded document format is not supported.',
        );
      }

      if (!mounted) return;

      setState(() {
        _metadata = metadata;
        _documentBytes = bytes;
        _isPdf = isPdf;
        _documentId = documentIdString;
        _isLoading = false;
        _error = null;
      });

      print(
        'DOCUMENT DOWNLOADED SUCCESSFULLY',
      );

      print(
        '========================================',
      );
    } catch (e, stackTrace) {
      print(
        '========== DOCUMENT VIEW ERROR ==========',
      );

      print('ERROR: $e');

      print(
        'STACK TRACE: $stackTrace',
      );

      print(
        '========================================',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ===========================================================================
  // DOWNLOAD DOCUMENT
  // ===========================================================================

  Future<void> _downloadDocument() async {
    if (_documentBytes == null ||
        _documentBytes!.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Document is not available for download.',
          ),
        ),
      );

      return;
    }

    if (_isDownloading) {
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      // -----------------------------------------------------------------------
      // GET FILE NAME
      // -----------------------------------------------------------------------

      String fileName =
          _stringValue(
        _metadata?['originalName'],
      );

      if (fileName.isEmpty) {
        fileName =
            _stringValue(
          widget.document['originalName'],
        );
      }

      if (fileName.isEmpty) {
        fileName =
            _stringValue(
          _metadata?['fileName'],
        );
      }

      if (fileName.isEmpty) {
        fileName =
            _isPdf
                ? 'medical_document.pdf'
                : 'medical_document';
      }

      fileName =
          _sanitizeFileName(fileName);

      // -----------------------------------------------------------------------
      // MIME TYPE
      // -----------------------------------------------------------------------

      final mimeType =
          _getMimeType();

      // -----------------------------------------------------------------------
      // ADD FILE EXTENSION IF NEEDED
      // -----------------------------------------------------------------------

      if (_isPdf) {
        if (!fileName
            .toLowerCase()
            .endsWith('.pdf')) {
          fileName =
              '$fileName.pdf';
        }
      } else {
        final lowerName =
            fileName.toLowerCase();

        final hasKnownImageExtension =
            lowerName.endsWith('.jpg') ||
            lowerName.endsWith('.jpeg') ||
            lowerName.endsWith('.png') ||
            lowerName.endsWith('.gif') ||
            lowerName.endsWith('.webp');

        if (!hasKnownImageExtension) {
          fileName =
              '$fileName'
              '${_getImageExtension()}';
        }
      }

      print(
        '========== DOCUMENT SAVE START ==========',
      );

      print(
        'SAVE FILE NAME: $fileName',
      );

      print(
        'SAVE MIME TYPE: $mimeType',
      );

      print(
        'SAVE FILE SIZE: '
        '${_documentBytes!.length} bytes',
      );

      // -----------------------------------------------------------------------
      // SAVE FILE
      // -----------------------------------------------------------------------

      final result =
          await _fileSaver.saveBytes(
        bytes: _documentBytes!,
        fileName: fileName,
        mimeType: mimeType,
        subDir: 'MediVault',
      );

      print(
        'SAVE RESULT: $result',
      );

      print(
        'SAVE URI: ${result?.uri}',
      );

      print(
        'SAVE PATH: ${result?.path}',
      );

      print(
        '==========================================',
      );

      if (!mounted) return;

      if (result != null &&
          result.isSuccess) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Document downloaded: '
              '${result.fileName}',
            ),
            duration:
                const Duration(
              seconds: 4,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Document download was cancelled or failed.',
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print(
        '========== DOCUMENT SAVE ERROR ==========',
      );

      print(
        'SAVE ERROR: $e',
      );

      print(
        'STACK TRACE: $stackTrace',
      );

      print(
        '==========================================',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to download document: $e',
          ),
          duration:
              const Duration(
            seconds: 4,
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isDownloading = false;
      });
    }
  }

  // ===========================================================================
  // MIME TYPE
  // ===========================================================================

  String _getMimeType() {
    final metadataMimeType =
        _stringValue(
      _metadata?['mimeType'],
    );

    if (metadataMimeType.isNotEmpty) {
      return metadataMimeType;
    }

    final metadataContentType =
        _stringValue(
      _metadata?['contentType'],
    );

    if (metadataContentType.isNotEmpty) {
      return metadataContentType;
    }

    if (_isPdf) {
      return 'application/pdf';
    }

    final originalName =
        _stringValue(
      _metadata?['originalName'],
    ).toLowerCase();

    if (originalName.endsWith('.png')) {
      return 'image/png';
    }

    if (originalName.endsWith('.gif')) {
      return 'image/gif';
    }

    if (originalName.endsWith('.webp')) {
      return 'image/webp';
    }

    if (originalName.endsWith('.jpg') ||
        originalName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    final widgetFileName =
        _stringValue(
      widget.document['originalName'],
    ).toLowerCase();

    if (widgetFileName.endsWith('.png')) {
      return 'image/png';
    }

    if (widgetFileName.endsWith('.gif')) {
      return 'image/gif';
    }

    if (widgetFileName.endsWith('.webp')) {
      return 'image/webp';
    }

    if (widgetFileName.endsWith('.jpg') ||
        widgetFileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    return 'image/jpeg';
  }

  // ===========================================================================
  // IMAGE EXTENSION
  // ===========================================================================

  String _getImageExtension() {
    final mimeType =
        _getMimeType().toLowerCase();

    if (mimeType.contains('png')) {
      return '.png';
    }

    if (mimeType.contains('gif')) {
      return '.gif';
    }

    if (mimeType.contains('webp')) {
      return '.webp';
    }

    return '.jpg';
  }

  // ===========================================================================
  // SANITIZE FILE NAME
  // ===========================================================================

  String _sanitizeFileName(
    String fileName,
  ) {
    var sanitized =
        fileName.trim();

    if (sanitized.isEmpty) {
      return 'medical_document';
    }

    sanitized =
        sanitized.replaceAll(
      RegExp(
        r'[\\/:*?"<>|]',
      ),
      '_',
    );

    sanitized =
        sanitized.replaceFirst(
      RegExp(
        r'^[.\s]+',
      ),
      '',
    );

    sanitized =
        sanitized.replaceFirst(
      RegExp(
        r'[.\s]+$',
      ),
      '',
    );

    if (sanitized.isEmpty) {
      return 'medical_document';
    }

    return sanitized;
  }

  // ===========================================================================
  // IMAGE FORMAT DETECTION
  // ===========================================================================

  bool _looksLikeImage(
    Uint8List bytes,
  ) {
    // JPEG
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return true;
    }

    // PNG
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return true;
    }

    // GIF
    if (bytes.length >= 6) {
      final header =
          String.fromCharCodes(
        bytes.sublist(0, 6),
      );

      if (header == 'GIF87a' ||
          header == 'GIF89a') {
        return true;
      }
    }

    // WEBP
    if (bytes.length >= 12) {
      final riff =
          String.fromCharCodes(
        bytes.sublist(0, 4),
      );

      final webp =
          String.fromCharCodes(
        bytes.sublist(8, 12),
      );

      if (riff == 'RIFF' &&
          webp == 'WEBP') {
        return true;
      }
    }

    return false;
  }

  // ===========================================================================
  // STRING HELPER
  // ===========================================================================

  String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final valueString =
        value.toString().trim();

    if (valueString.isEmpty ||
        valueString == 'null') {
      return '';
    }

    return valueString;
  }

  // ===========================================================================
  // DATE FORMATTER
  // ===========================================================================

  String _formatDate(
    dynamic value,
  ) {
    final valueString =
        _stringValue(value);

    if (valueString.isEmpty) {
      return '';
    }

    try {
      final date =
          DateTime.parse(
        valueString,
      );

      final localDate =
          date.toLocal();

      final day =
          localDate.day
              .toString()
              .padLeft(2, '0');

      final month =
          localDate.month
              .toString()
              .padLeft(2, '0');

      final year =
          localDate.year.toString();

      return '$day/$month/$year';
    } catch (_) {
      return valueString;
    }
  }

  // ===========================================================================
  // FILE SIZE FORMATTER
  // ===========================================================================

  String _formatFileSize(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final bytes =
        int.tryParse(
      value.toString(),
    );

    if (bytes == null) {
      return '';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final fileName =
        _stringValue(
          _metadata?['originalName'],
        ).isNotEmpty
            ? _stringValue(
                _metadata?['originalName'],
              )
            : _stringValue(
                widget.document['originalName'],
              ).isNotEmpty
                ? _stringValue(
                    widget.document[
                      'originalName'
                    ],
                  )
                : 'Medical Document';

    return Scaffold(
      backgroundColor:
          Appcolors.background,

      appBar: AppBar(
        backgroundColor:
            Appcolors.background,

        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color:
                Appcolors.primaryText,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Medical Document',
          style: TextStyle(
            color:
                Appcolors.primaryText,
            fontSize: 19,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        // ---------------------------------------------------------------------
        // DOWNLOAD BUTTON
        // ---------------------------------------------------------------------

        actions: [
          if (!_isLoading &&
              _documentBytes != null &&
              _error == null)
            _isDownloading
                ? const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 16,
                    ),

                    child: Center(
                      child: SizedBox(
                        width: 21,
                        height: 21,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color:
                              Appcolors.primary,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    tooltip:
                        'Download document',

                    icon: const Icon(
                      Icons.download_outlined,
                      color:
                          Appcolors.primaryText,
                    ),

                    onPressed:
                        _downloadDocument,
                  ),

          const SizedBox(
            width: 6,
          ),
        ],
      ),

      body:
          _buildBody(fileName),
    );
  }

  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _buildBody(
    String fileName,
  ) {
    // -------------------------------------------------------------------------
    // LOADING
    // -------------------------------------------------------------------------

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            CircularProgressIndicator(
              color:
                  Appcolors.primary,
            ),

            SizedBox(
              height: 14,
            ),

            Text(
              'Loading document...',
              style: TextStyle(
                color:
                    Appcolors.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    // -------------------------------------------------------------------------
    // ERROR
    // -------------------------------------------------------------------------

    if (_error != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color:
                    Appcolors.error,
              ),

              const SizedBox(
                height: 14,
              ),

              const Text(
                'Unable to open document',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Appcolors.primaryText,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                _error!,
                textAlign:
                    TextAlign.center,

                style: const TextStyle(
                  fontSize: 13,
                  color:
                      Appcolors.secondaryText,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                    _documentBytes = null;
                    _metadata = null;
                    _isPdf = false;
                    _documentId = null;
                  });

                  _loadDocument();
                },

                icon: const Icon(
                  Icons.refresh,
                ),

                label: const Text(
                  'Try Again',
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Appcolors.primary,
                  foregroundColor:
                      Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // NO DOCUMENT
    // -------------------------------------------------------------------------

    if (_documentBytes == null) {
      return const Center(
        child: Text(
          'Document is unavailable.',
          style: TextStyle(
            color:
                Appcolors.secondaryText,
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // METADATA
    // -------------------------------------------------------------------------

    final uploadedBy =
        _stringValue(
      _metadata?['uploadedByName'],
    );

    final uploadedByRole =
        _stringValue(
      _metadata?['uploadedByRole'],
    );

    final documentType =
        _stringValue(
      _metadata?['category'],
    );

    final documentTitle =
        _stringValue(
      _metadata?['documentTitle'],
    );

    final documentDate =
        _formatDate(
      _metadata?['documentDate'],
    );

    final uploadedDate =
        _formatDate(
      _metadata?['createdAt'],
    );

    final fileSize =
        _formatFileSize(
      _metadata?['sizeBytes'],
    );

    return Column(
      children: [
        // ---------------------------------------------------------------------
        // DOCUMENT INFO
        // ---------------------------------------------------------------------

        Container(
          width: double.infinity,

          padding:
              const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            14,
          ),

          color:
              Appcolors.surface,

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                fileName,

                maxLines: 2,

                overflow:
                    TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Appcolors.primaryText,
                ),
              ),

              if (documentTitle
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 4,
                ),

                Text(
                  documentTitle,

                  maxLines: 2,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 13,
                    color:
                        Appcolors.secondaryText,
                  ),
                ),
              ],

              const SizedBox(
                height: 12,
              ),

              if (uploadedBy
                  .isNotEmpty)
                _infoRow(
                  icon:
                      Icons.person_outline,
                  label:
                      'Uploaded by',
                  value:
                      uploadedByRole
                              .isNotEmpty
                          ? '$uploadedBy • '
                              '$uploadedByRole'
                          : uploadedBy,
                ),

              if (uploadedDate
                  .isNotEmpty)
                _infoRow(
                  icon:
                      Icons.upload_outlined,
                  label:
                      'Uploaded on',
                  value:
                      uploadedDate,
                ),

              if (documentDate
                  .isNotEmpty)
                _infoRow(
                  icon:
                      Icons.calendar_today_outlined,
                  label:
                      'Document date',
                  value:
                      documentDate,
                ),

              if (documentType
                  .isNotEmpty)
                _infoRow(
                  icon:
                      Icons.category_outlined,
                  label:
                      'Type',
                  value:
                      documentType,
                ),

              if (fileSize
                  .isNotEmpty)
                _infoRow(
                  icon:
                      Icons.data_usage_outlined,
                  label:
                      'File size',
                  value:
                      fileSize,
                ),
            ],
          ),
        ),

        const Divider(
          height: 1,
          color:
              Appcolors.border,
        ),

        // ---------------------------------------------------------------------
        // DOCUMENT VIEWER
        // ---------------------------------------------------------------------

        Expanded(
          child: Container(
            width: double.infinity,

            color:
                Appcolors.background,

            padding:
                const EdgeInsets.all(12),

            child: _isPdf
                ? PdfViewer.data(
                    _documentBytes!,

                    sourceName:
                        'medical-document-'
                        '${_documentId ?? 'document'}'
                        '.pdf',
                  )
                : InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,

                    child: Center(
                      child: Image.memory(
                        _documentBytes!,

                        fit:
                            BoxFit.contain,

                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          print(
                            'DOCUMENT MEMORY IMAGE ERROR: '
                            '$error',
                          );

                          return const Column(
                            mainAxisSize:
                                MainAxisSize.min,

                            children: [
                              Icon(
                                Icons
                                    .broken_image_outlined,
                                size: 56,
                                color:
                                    Appcolors
                                        .secondaryText,
                              ),

                              SizedBox(
                                height: 12,
                              ),

                              Text(
                                'The document could not '
                                'be displayed.',

                                style:
                                    TextStyle(
                                  color:
                                      Appcolors
                                          .secondaryText,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // INFO ROW
  // ===========================================================================

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            size: 17,
            color:
                Appcolors.secondaryText,
          ),

          const SizedBox(
            width: 9,
          ),

          Text(
            '$label: ',

            style: const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color:
                  Appcolors.secondaryText,
            ),
          ),

          Expanded(
            child: Text(
              value,

              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
                color:
                    Appcolors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}