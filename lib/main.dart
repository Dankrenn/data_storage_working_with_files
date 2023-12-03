import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _idController = TextEditingController();
  File? _downloadedFile;
  List<Widget> _actionButtons = [];
  bool hidePopup = true;

  @override
  void initState() {
    super.initState();
    _actionButtons.add(SizedBox.shrink());
    showPopup(context);
  }

  showPopup(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool showPopup = prefs.getBool('hidePopup') ?? true;

    if (showPopup) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Инструкция по использованию приложения'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ваша инструкция здесь...'),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Больше не показывать'),
                onPressed: () async {
                 const hp = false;
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  prefs.setBool('hidePopup', hp);
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }


  Future<bool> _downloadFiles(String url, String fileName) async {
    try {
      var response = await http.head(Uri.parse(url));
      if (response.statusCode == 200 && response.headers['content-type'] == 'application/pdf') {
        var request = await http.get(Uri.parse(url));
        var bytes = request.bodyBytes;
        String dir = (await getApplicationDocumentsDirectory()).path;
        File file = File('$dir/$fileName');
        await file.writeAsBytes(bytes);
        _downloadedFile = file;
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _deleteFile() async {
    try {
      if (_downloadedFile != null) {
        await _downloadedFile!.delete();
        setState(() {
          _downloadedFile = null;
          _actionButtons = [SizedBox.shrink()];
        });
      }
    } catch (e) {
      // print("Error deleting file: $e");
    }
  }


  void _updateActionButtons() {
    setState(() {
      _actionButtons = [
        ElevatedButton(
          onPressed: _openFile,
          child: Text('Посмотреть'),
        ),
        ElevatedButton(
          onPressed: _deleteFile,
          child: Text('Удалить'),
        ),
      ];
    });
  }

  Future<void> _openFile() async {
    try {
      if (_downloadedFile != null) {
        await OpenFile.open(_downloadedFile!.path);
      } else {
        throw Exception('Файл не найден. Сначала скачайте файл.');
      }
    } catch (e) {
      print("Error opening file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при открытии файла: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Распаковщик PDF'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Введите ID',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                if (_idController.text.isNotEmpty) {
                  int id = int.parse(_idController.text);
                  String url = 'http://ntv.ifmo.ru/file/journal/$id.pdf';
                  String fileName = 'journal_$id.pdf';

                  bool downloaded = await _downloadFiles(url, fileName);

                  if (downloaded) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Файл успешно скачан.'),
                      ),
                    );
                    _updateActionButtons();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка при скачивании файла или файл не найден.'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Введите ID.'),
                    ),
                  );
                }
              },
              child: Text('Сохранить'),
            ),
            ..._actionButtons,
          ],
        ),
      ),
    );
  }
}
