import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/utils/jalali_utils.dart';
import '../../data/local/database.dart';

class EstimateGenerator {
  static Future<Uint8List> generate({
    required RepairOrder order,
    required Customer customer,
    required BusinessSetting? business,
  }) async {
    final regularData = await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
    final regularFont = pw.Font.ttf(regularData);
    final boldFont = pw.Font.ttf(boldData);

    final doc = pw.Document(theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont));
    final cost = order.estimatedCost ?? 0;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: PdfColors.amber100,
                child: pw.Text('پیش‌فاکتور — تخمین هزینه (غیرقطعی)', style: pw.TextStyle(font: boldFont, fontSize: 12)),
              ),
              pw.SizedBox(height: 14),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(business?.businessName ?? 'تعمیرگاه', style: pw.TextStyle(font: boldFont, fontSize: 20)),
                  pw.Text('سفارش #${order.id}', style: pw.TextStyle(font: regularFont, fontSize: 13)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('تاریخ: ${JalaliUtils.formatDate(order.receivedAt)}', style: pw.TextStyle(font: regularFont, fontSize: 12)),
              pw.Divider(height: 24),
              pw.Text('مشتری: ${customer.name}', style: pw.TextStyle(font: regularFont)),
              pw.Text('تلفن: ${customer.phone}', style: pw.TextStyle(font: regularFont)),
              pw.SizedBox(height: 20),
              pw.Text('شرح خرابی', style: pw.TextStyle(font: boldFont)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Text(order.issueDescription, style: pw.TextStyle(font: regularFont)),
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('برآورد هزینه تعمیر', style: pw.TextStyle(font: regularFont, fontSize: 14)),
                  pw.Text('$cost تومان', style: pw.TextStyle(font: boldFont, fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'این مبلغ تخمینی است و ممکن است پس از بررسی دقیق‌تر تغییر کند. فاکتور نهایی هنگام تحویل صادر می‌شود.',
                style: pw.TextStyle(font: regularFont, fontSize: 11, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
