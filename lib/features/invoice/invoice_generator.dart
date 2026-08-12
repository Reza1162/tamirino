import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/utils/jalali_utils.dart';
import '../../data/local/database.dart';

class InvoiceGenerator {
  static Future<Uint8List> generate({
    required RepairOrder order,
    required Customer customer,
    required BusinessSetting? business,
    required int totalPaid,
  }) async {
    final regularData = await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
    final regularFont = pw.Font.ttf(regularData);
    final boldFont = pw.Font.ttf(boldData);

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    final cost = order.finalCost ?? order.estimatedCost ?? 0;
    final remaining = cost - totalPaid - order.discount;
    final dateStr = JalaliUtils.formatDate(order.receivedAt);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      if (business?.logoPath != null && File(business!.logoPath!).existsSync())
                        pw.Container(
                          width: 40,
                          height: 40,
                          margin: const pw.EdgeInsets.only(left: 10),
                          child: pw.Image(pw.MemoryImage(File(business.logoPath!).readAsBytesSync())),
                        ),
                      pw.Text(
                        business?.businessName ?? 'تعمیرگاه',
                        style: pw.TextStyle(font: boldFont, fontSize: 22),
                      ),
                    ],
                  ),
                  pw.Text('فاکتور تعمیر #${order.id}', style: pw.TextStyle(font: regularFont, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('تاریخ: $dateStr', style: pw.TextStyle(font: regularFont, fontSize: 12)),
              pw.Divider(height: 24),
              pw.Text('مشخصات مشتری', style: pw.TextStyle(font: boldFont)),
              pw.SizedBox(height: 6),
              pw.Text('نام: ${customer.name}', style: pw.TextStyle(font: regularFont)),
              pw.Text('تلفن: ${customer.phone}', style: pw.TextStyle(font: regularFont)),
              pw.SizedBox(height: 20),
              pw.Text('شرح خدمات', style: pw.TextStyle(font: boldFont)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Text(order.issueDescription, style: pw.TextStyle(font: regularFont)),
              ),
              pw.SizedBox(height: 24),
              pw.Divider(),
              _row('مبلغ کل', '$cost تومان', regularFont, boldFont),
              if (order.discount > 0) _row('تخفیف', '${order.discount} تومان', regularFont, boldFont),
              _row('پرداخت‌شده', '$totalPaid تومان', regularFont, boldFont),
              pw.Divider(),
              _row(
                'باقی‌مانده',
                '$remaining تومان',
                regularFont,
                boldFont,
                bold: true,
                color: remaining > 0 ? PdfColors.red : PdfColors.green800,
              ),
              if (order.signaturePath != null && File(order.signaturePath!).existsSync()) ...[
                pw.SizedBox(height: 20),
                pw.Text('امضای تحویل مشتری', style: pw.TextStyle(font: regularFont, fontSize: 12)),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 120,
                  height: 60,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                  child: pw.Image(pw.MemoryImage(File(order.signaturePath!).readAsBytesSync())),
                ),
              ],
              if (order.warrantyDays != null) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  'این تعمیر دارای ${order.warrantyDays} روز گارانتی است',
                  style: pw.TextStyle(font: regularFont, fontSize: 12, color: PdfColors.green800),
                ),
              ],
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text(
                  'با تشکر از اعتماد شما',
                  style: pw.TextStyle(font: regularFont, fontSize: 12, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _row(
    String label,
    String value,
    pw.Font regularFont,
    pw.Font boldFont, {
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: regularFont, fontSize: 13)),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: bold ? boldFont : regularFont,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
