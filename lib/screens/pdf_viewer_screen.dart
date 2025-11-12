import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.pdfTitle,
  });

  final String pdfUrl;
  final String pdfTitle;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    if (kIsWeb) {
      // On web, open PDF in browser as pdfx doesn't fully support web yet
      setState(() {
        _isLoading = false;
      });
      try {
        await launchUrl(Uri.parse(widget.pdfUrl), mode: LaunchMode.platformDefault);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to open PDF: $e';
          });
        }
      }
      return;
    }

    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final documentFuture = PdfDocument.openData(response.bodyBytes);
        if (mounted) {
          _pdfController = PdfController(
            document: documentFuture,
            initialPage: 1,
          );
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Failed to load PDF: HTTP ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load PDF: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For web, show a message that PDF will open in browser
      return Scaffold(
        appBar: AppBar(
          leading: CupertinoNavigationBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.black,
          ),
          title: Text(
            widget.pdfTitle,
            style: const TextStyle(
              color: Color(0xFF582DB0),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : _error != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => launchUrl(Uri.parse(widget.pdfUrl)),
                          child: const Text('Open in Browser'),
                        ),
                      ],
                    )
                  : const Text('Opening PDF in browser...'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.white,
        ),
        title: Text(
          widget.pdfTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF582DB0),
        actions: [
          if (_pdfController != null)
            IconButton(
              icon: const Icon(Icons.download_outlined, color: Colors.white),
              onPressed: () async {
                try {
                  await launchUrl(Uri.parse(widget.pdfUrl), mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to download: $e')),
                    );
                  }
                }
              },
              tooltip: 'Download PDF',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await launchUrl(Uri.parse(widget.pdfUrl), mode: LaunchMode.externalApplication);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to open: $e')),
                            );
                          }
                        },
                        child: const Text('Open in External App'),
                      ),
                    ],
                  ),
                )
              : PdfView(
                  controller: _pdfController!,
                  scrollDirection: Axis.vertical,
                ),
    );
  }
}

