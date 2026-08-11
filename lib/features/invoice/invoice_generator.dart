import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/local/database.dart';

class InvoiceGenerator {
  static Future<Uint8List> generate({
    required RepairOrder order,
    required Customer customer,
    required BusinessSetting? business,
    required int totalPaid,
  }) async {
    final doc = pw.Document();
    final cost = order.finalCost ?? order.estimatedCost ?? 0;
    final remaining = cost - totalPaid - order.discount;
    final dateStr = DateFormat('yyyy/MM/dd').format(order.receivedAt);

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
                  pw.Text(
                    business?.businessName ?? 'تعمیرگاه',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('فاکتور تعمیر #${order.id}', style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('تاریخ: $dateStr', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(height: 24),
              pw.Text('مشخصات مشتری', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('نام: ${customer.name}'),
              pw.Text('تلفن: ${customer.phone}'),
              pw.SizedBox(height: 20),
              pw.Text('شرح خدمات', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Text(order.issueDescription),
              ),
              pw.SizedBox(height: 24),
              pw.Divider(),
              _row('مبلغ کل', '$cost تومان'),
              if (order.discount > 0) _row('تخفیف', '${order.discount} تومان'),
              _row('پرداخت‌شده', '$totalPaid تومان'),
              pw.Divider(),
              _row(
                'باقی‌مانده',
                '$remaining تومان',
                bold: true,
                color: remaining > 0 ? PdfColors.red : PdfColors.green800,
              ),
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text('با تشکر از اعتماد شما', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _row(String label, String value, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 13)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
