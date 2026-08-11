import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';
import '../../data/local/database.dart';

class BarcodeLabelGenerator {
  static Future<Uint8List> generate(Part part) async {
    final regularData = await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
    final regularFont = pw.Font.ttf(regularData);

    final doc = pw.Document(theme: pw.ThemeData.withFont(base: regularFont));
    final code = part.barcode ?? 'TMR-P${part.id.toString().padLeft(5, '0')}';

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(280, 150, marginAll: 10),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(part.name, style: pw.TextStyle(font: regularFont, fontSize: 12), textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 8),
              pw.BarcodeWidget(
                barcode: Barcode.code128(),
                data: code,
                width: 220,
                height: 60,
                drawText: false,
              ),
              pw.SizedBox(height: 4),
              pw.Text(code, style: pw.TextStyle(font: regularFont, fontSize: 10)),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
