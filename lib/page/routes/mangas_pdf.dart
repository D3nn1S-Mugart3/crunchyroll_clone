import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'dart:io';

class MangasPDF extends StatelessWidget {
  final List<Anime> animeList = [
    Anime(
      title: "One Piece", 
      imageAsset: "assets/images/one-piece.jpg", 
      pdfAsset: "assets/pdf/OP1099-1109.pdf"
    ),
    Anime(
      title: "One Piece", 
      imageAsset: "assets/images/one-piece.jpg", 
      pdfAsset: "assets/pdf/OP1110-1116.pdf"
    ),
    Anime(
      title: "One Piece", 
      imageAsset: "assets/images/one-piece.jpg", 
      pdfAsset: "assets/pdf/OP1117.pdf"
    ),
    Anime(
      title: "One Piece", 
      imageAsset: "assets/images/one-piece.jpg", 
      pdfAsset: "assets/pdf/OP1099-1109.pdf"
    ),
    Anime(
      title: "One Piece", 
      imageAsset: "assets/images/one-piece.jpg", 
      pdfAsset: "assets/pdf/OP1110-1116.pdf"
    ),
    Anime(
      title: "One Piece", 
      imageAsset: "assets/images/one-piece.jpg", 
      pdfAsset: "assets/pdf/OP1117.pdf"
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mangas"),
      ),
      body: ListView.builder(
        itemCount: (animeList.length / 2).ceil(),
        itemBuilder: (context, index) {
          final leftAnime = animeList[index * 2];
          final rightAnime = index * 2 < animeList.length
              ? animeList[index *2 + 1]
              : null;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimeTile(anime: leftAnime),
              if (rightAnime != null) AnimeTile(anime: rightAnime)
            ],
          );
        },
      ),
    );
  }
}

class Anime {
  final String title;
  final String imageAsset;
  final String pdfAsset;

  Anime({
    required this.title,
    required this.imageAsset,
    required this.pdfAsset,
  });
}

class AnimeTile extends StatelessWidget {
  final Anime anime;

  AnimeTile({required this.anime});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => _openPdf(context, anime.pdfAsset),
            child: Image.asset(anime.imageAsset, width: 150),
          ),
        ),
        Text(anime.title),
      ],
    );
  }

  void _openPdf(BuildContext context, String pdfAsset) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/${pdfAsset.split('/').last}");
      final data = await rootBundle.load(pdfAsset);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(pdfPath: file.path),
        ),
      );
    } catch (e) {
      print('Error cargando el PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir el PDF.')),
      );
    }
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;

  PdfViewerScreen({required this.pdfPath});

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late Future<void> _loadingFuture;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  late PDFViewController _pdfViewController;

  @override
  void initState() {
    super.initState();
    _loadingFuture = _loadPdf();
  }

  Future<void> _loadPdf() async {
    await Future.delayed(Duration(seconds: 2)); // Espera de 2 segundos
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                _isReady ? '$_currentPage/$_totalPages' : 'Cargando...',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  color: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  height: constraints.maxHeight, // Limita la altura
                  child: PDFView(
                    filePath: widget.pdfPath,
                    autoSpacing: false,
                    pageFling: false,
                    onRender: (_pages) {
                      setState(() {
                        _totalPages = _pages!;
                        _isReady = true;
                      });
                    },
                    onViewCreated: (PDFViewController pdfViewController) {
                      _pdfViewController = pdfViewController;
                    },
                    onPageChanged: (int? page, int? total) {
                      setState(() {
                        _currentPage = page! + 1;
                      });
                    },
                    defaultPage: _currentPage - 1,
                    pageSnap: false,
                    swipeHorizontal: false,
                  ),
                  
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: _isReady
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: _currentPage.toDouble(),
                  min: 1,
                  max: _totalPages.toDouble(),
                  divisions: _totalPages,
                  label: 'Página $_currentPage',
                  onChanged: (value) {
                    setState(() {
                      _currentPage = value.toInt();
                    });
                    _pdfViewController.setPage(_currentPage - 1);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        if (_currentPage > 1) {
                          _currentPage--;
                          _pdfViewController.setPage(_currentPage - 1);
                          setState(() {});
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: () {
                        if (_currentPage < _totalPages) {
                          _currentPage++;
                          _pdfViewController.setPage(_currentPage - 1);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ],
            )
          : null,
      floatingActionButton: _isReady
          ? FloatingActionButton(
              child: Icon(Icons.share),
              onPressed: () async {
                await Share.shareFiles([widget.pdfPath], text: '¡Mira este PDF!');
              },
            )
          : null,
    );
  }
}
