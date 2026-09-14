import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/booking_service.dart';
import '../../services/service_locator.dart';

class LabResultDetailScreen extends StatefulWidget {
  final String labTestId;

  const LabResultDetailScreen({super.key, required this.labTestId});

  @override
  State<LabResultDetailScreen> createState() => _LabResultDetailScreenState();
}

class _LabResultDetailScreenState extends State<LabResultDetailScreen> {
  LabTestDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _busyPdf = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await ServiceLocator.instance.bookings.getMyLabTestDetail(widget.labTestId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final data):
          _detail = data;
        case Failure(message: final msg):
          _error = msg;
      }
    });
  }

  String _longDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('EEEE, MMMM d, yyyy', 'en').format(d);
  }

  Future<void> _viewAsPdf() async {
    final detail = _detail;
    if (detail == null || _busyPdf) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busyPdf = true);
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text('Hiraal · Lab Result',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(detail.template,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (detail.resultDate != null || detail.created != null)
              pw.Text(_longDate(detail.resultDate ?? detail.created)),
            pw.Text(detail.clinicName),
            if (detail.reviewedBy.isNotEmpty)
              pw.Text('${l10n.reviewedByPrefix} ${detail.reviewedBy}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Test', 'Result', 'Normal', 'Status'],
              data: detail.items
                  .map((i) => [
                        i.name,
                        i.value,
                        i.normalRange.isEmpty ? '–' : i.normalRange,
                        i.status,
                      ])
                  .toList(),
            ),
            if (detail.doctorNote.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(l10n.whatYourDoctorSays,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(detail.doctorNote),
            ],
          ],
        ),
      );
      final dir = await getTemporaryDirectory();
      final safeName = detail.template.replaceAll(RegExp(r'[^\w\-]+'), '_');
      final file = File('${dir.path}/hiraal_${safeName}_${detail.id}.pdf');
      await file.writeAsBytes(await doc.save());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: detail.template,
        text: l10n.labResultPdfShareText(detail.template),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotCreatePdf)),
        );
      }
    } finally {
      if (mounted) setState(() => _busyPdf = false);
    }
  }

  Future<void> _forwardShare() async {
    final detail = _detail;
    if (detail == null) return;
    final l10n = AppLocalizations.of(context);
    final buffer = StringBuffer()
      ..writeln(detail.template)
      ..writeln(_longDate(detail.resultDate ?? detail.created))
      ..writeln(detail.clinicName);
    for (final item in detail.items) {
      buffer.writeln('${item.name}: ${item.value} (${item.status})');
    }
    if (detail.doctorNote.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${l10n.whatYourDoctorSays}: ${detail.doctorNote}');
    }
    await Share.share(buffer.toString(), subject: detail.template);
  }

  Future<void> _sendWhatsApp() async {
    final detail = _detail;
    if (detail == null) return;
    final l10n = AppLocalizations.of(context);
    final text = Uri.encodeComponent(
      '${detail.template}\n'
      '${_longDate(detail.resultDate ?? detail.created)}\n'
      '${detail.items.map((i) => '${i.name}: ${i.value} (${i.status})').join('\n')}'
      '${detail.doctorNote.isNotEmpty ? '\n\n${l10n.whatYourDoctorSays}: ${detail.doctorNote}' : ''}',
    );
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenWhatsApp)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppColors.of(context);
    final unread = context.watch<AppProvider>().unreadNotificationCount;

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        title: Text(l10n.labResultTitle),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.notifications,
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            icon: unread > 0
                ? Badge.count(
                    count: unread,
                    backgroundColor: AppColors.error,
                    textColor: AppColors.white,
                    child: Icon(Icons.notifications_outlined, color: palette.text),
                  )
                : Icon(Icons.notifications_outlined, color: palette.text),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: AppColors.error)),
                      TextButton(onPressed: _load, child: Text(l10n.retry)),
                    ],
                  ),
                )
              : _detail == null
                  ? Center(child: Text(l10n.noLabResultsYet))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        _ResultCard(detail: _detail!, longDate: _longDate),
                        if (_detail!.doctorNote.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4FC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.whatYourDoctorSays,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: palette.text,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _detail!.doctorNote,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: palette.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _busyPdf ? null : _viewAsPdf,
                            icon: _busyPdf
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(l10n.viewAsPdf),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _forwardShare,
                            icon: const Icon(Icons.share_outlined),
                            label: Text(l10n.forwardToDoctorOrFamily),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: BorderSide(color: palette.border),
                            ),
                            onPressed: _sendWhatsApp,
                            icon: const Icon(Icons.chat_outlined),
                            label: Text(l10n.sendSummaryOnWhatsApp),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final LabTestDetail detail;
  final String Function(DateTime?) longDate;

  const _ResultCard({required this.detail, required this.longDate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppColors.of(context);
    final date = detail.resultDate ?? detail.created;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.science_outlined, color: Color(0xFF7E57C2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.template,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        longDate(date),
                        style: TextStyle(fontSize: 13, color: palette.textMuted),
                      ),
                    ],
                    Text(
                      detail.clinicName,
                      style: TextStyle(fontSize: 13, color: palette.textMuted),
                    ),
                    if (detail.reviewedBy.isNotEmpty)
                      Text(
                        '${l10n.reviewedByPrefix} ${detail.reviewedBy}',
                        style: TextStyle(fontSize: 13, color: palette.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (detail.items.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.labResultsPendingDetail,
              style: TextStyle(color: palette.textMuted),
            ),
          ] else
            ...detail.items.asMap().entries.map((entry) {
              final i = entry.value;
              final last = entry.key == detail.items.length - 1;
              final watch = i.isWatch;
              final color = watch ? AppColors.warning : AppColors.success;
              final statusLabel = watch ? l10n.statusWatch : l10n.statusNormal;
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Divider(height: 1, color: palette.border),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: palette.text,
                              ),
                            ),
                            if (i.normalRange.isNotEmpty)
                              Text(
                                '${l10n.normalRangeLabel}: ${i.normalRange}',
                                style: TextStyle(fontSize: 12, color: palette.textMuted),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            i.value,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (last) const SizedBox(height: 4),
                ],
              );
            }),
        ],
      ),
    );
  }
}
