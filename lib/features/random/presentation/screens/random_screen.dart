// lib/features/random/presentation/screens/random_screen.dart
import 'dart:async'; // Ditambahkan untuk fitur Timer[cite: 17]
import 'dart:io'; // Ditambahkan untuk mengecek platform
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Dibutuhkan untuk mengakses Clipboard[cite: 17]
import 'package:flutter/foundation.dart'; // Ditambahkan untuk mendeteksi kDebugMode
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Ditambahkan untuk SDK AdMob
import '../../../../core/presentation/widgets/drawer_menu.dart';

enum RandomType { angka, huruf, list } //[cite: 17]

class RandomScreen extends StatefulWidget {
  const RandomScreen({super.key});

  @override
  State<RandomScreen> createState() => _RandomScreenState();
}

class _RandomScreenState extends State<RandomScreen> {
  RandomType _selectedType = RandomType.angka; //[cite: 17]

  // Controller untuk Angka[cite: 17]
  final TextEditingController _minController = TextEditingController(
    text: '0',
  ); //[cite: 17]
  final TextEditingController _maxController = TextEditingController(
    //[cite: 17]
    text: '10', //[cite: 17]
  ); //[cite: 17]

  // Controller untuk Huruf[cite: 17]
  final TextEditingController _minLetterController = TextEditingController(
    //[cite: 17]
    text: 'A', //[cite: 17]
  ); //[cite: 17]
  final TextEditingController _maxLetterController = TextEditingController(
    //[cite: 17]
    text: 'E', //[cite: 17]
  ); //[cite: 17]

  // Controller untuk List/Daftar Teks[cite: 17]
  final TextEditingController _listController = TextEditingController(
    //[cite: 17]
    text: 'Pilihan 1\nPilihan 2\nPilihan 3', //[cite: 17]
  ); //[cite: 17]

  // State untuk Fitur Timer[cite: 17]
  final TextEditingController _durationController = TextEditingController(
    //[cite: 17]
    text: '10', //[cite: 17]
  ); //[cite: 17]
  Timer? _timer; //[cite: 17]
  int _remainingSeconds = 0; //[cite: 17]
  bool _isTimerRunning = false; //[cite: 17]
  bool _isTimerInitialized = false; //[cite: 17]

  String? _result; //[cite: 17]
  final Random _random = Random(); //[cite: 17]

  // Variabel kontrol untuk Banner AdMob
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Getter adaptif untuk menentukan Ad Unit ID Iklan Banner
  String get adUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        // ID Test Resmi dari Google untuk pengujian iklan Banner Android
        return 'ca-app-pub-3940256099942544/6300978111';
      } else {
        // GANTI dengan Ad Unit ID asli Anda dari dasbor AdMob saat rilis nanti
        return 'ca-app-pub-5320800343545863/9491875036';
      }
    }
    return ''; // Kosongkan jika berjalan di Desktop (Windows/Linux/macOS) agar tidak crash
  }

  @override
  void initState() {
    super.initState();
    // Panggil fungsi pemuatan iklan banner
    _loadBannerAd();
  }

  // Fungsi untuk mengunduh iklan banner AdMob
  void _loadBannerAd() {
    if (adUnitId.isEmpty) return; // Batalkan jika bukan platform Android

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Iklan Banner Random Screen gagal dimuat: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  void _generateRandomValue() {
    //[cite: 17]
    setState(() {
      //[cite: 17]
      if (_selectedType == RandomType.angka) {
        //[cite: 17]
        int min = int.tryParse(_minController.text) ?? 0; //[cite: 17]
        int max = int.tryParse(_maxController.text) ?? 10; //[cite: 17]

        if (min > max) {
          //[cite: 17]
          final temp = min; //[cite: 17]
          min = max; //[cite: 17]
          max = temp; //[cite: 17]
          _minController.text = min.toString(); //[cite: 17]
          _maxController.text = max.toString(); //[cite: 17]
        } //[cite: 17]

        _result = (min + _random.nextInt((max - min) + 1))
            .toString(); //[cite: 17]
      } else if (_selectedType == RandomType.huruf) {
        //[cite: 17]
        String minStr = _minLetterController.text
            .trim()
            .toUpperCase(); //[cite: 17]
        String maxStr = _maxLetterController.text
            .trim()
            .toUpperCase(); //[cite: 17]

        if (minStr.isEmpty) minStr = 'A'; //[cite: 17]
        if (maxStr.isEmpty) maxStr = 'E'; //[cite: 17]

        int minCode = minStr.codeUnitAt(0); //[cite: 17]
        int maxCode = maxStr.codeUnitAt(0); //[cite: 17]

        if (minCode < 65 || minCode > 90) minCode = 65; //[cite: 17]
        if (maxCode < 65 || maxCode > 90) maxCode = 69; //[cite: 17]

        if (minCode > maxCode) {
          //[cite: 17]
          final temp = minCode; //[cite: 17]
          minCode = maxCode; //[cite: 17]
          maxCode = temp; //[cite: 17]
          _minLetterController.text = String.fromCharCode(minCode); //[cite: 17]
          _maxLetterController.text = String.fromCharCode(maxCode); //[cite: 17]
        } //[cite: 17]

        int randomCode =
            minCode + _random.nextInt((maxCode - minCode) + 1); //[cite: 17]
        _result = String.fromCharCode(randomCode); //[cite: 17]
      } else {
        //[cite: 17]
        List<String> items = _listController
            .text //[cite: 17]
            .split('\n') //[cite: 17]
            .map((e) => e.trim()) //[cite: 17]
            .where((e) => e.isNotEmpty) //[cite: 17]
            .toList(); //[cite: 17]

        if (items.isEmpty) {
          //[cite: 17]
          _result = 'Daftar Kosong'; //[cite: 17]
          return; //[cite: 17]
        } //[cite: 17]

        int randomIndex = _random.nextInt(items.length); //[cite: 17]
        _result = items[randomIndex]; //[cite: 17]
      } //[cite: 17]
    }); //[cite: 17]
  } //[cite: 17]

  // Fungsi Logika Timer[cite: 17]
  void _startTimer() {
    //[cite: 17]
    if (!_isTimerInitialized) {
      //[cite: 17]
      int duration = int.tryParse(_durationController.text) ?? 10; //[cite: 17]
      if (duration <= 0) return; //[cite: 17]
      _remainingSeconds = duration; //[cite: 17]
      _isTimerInitialized = true; //[cite: 17]
    } //[cite: 17]

    setState(() {
      //[cite: 17]
      _isTimerRunning = true; //[cite: 17]
    }); //[cite: 17]

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      //[cite: 17]
      setState(() {
        //[cite: 17]
        if (_remainingSeconds > 0) {
          //[cite: 17]
          _remainingSeconds--; //[cite: 17]
        } else {
          //[cite: 17]
          _timer?.cancel(); //[cite: 17]
          _isTimerRunning = false; //[cite: 17]
          // Panggil dialog di sini saat waktu habis[cite: 17]
          _showTimeoutDialog(); //[cite: 17]
        } //[cite: 17]
      }); //[cite: 17]
    }); //[cite: 17]
  } //[cite: 17]

  // Fungsi baru untuk menampilkan dialog saat waktu habis[cite: 17]
  void _showTimeoutDialog() {
    //[cite: 17]
    showDialog(
      //[cite: 17]
      context: context, //[cite: 17]
      barrierDismissible:
          false, // User harus menekan tombol untuk menutup[cite: 17]
      builder: (BuildContext context) {
        //[cite: 17]
        return AlertDialog(
          //[cite: 17]
          shape: RoundedRectangleBorder(
            //[cite: 17]
            borderRadius: BorderRadius.circular(16), //[cite: 17]
          ), //[cite: 17]
          title: Row(
            //[cite: 17]
            children: [
              //[cite: 17]
              Icon(Icons.alarm_on, color: Colors.red[700]), //[cite: 17]
              const SizedBox(width: 10), //[cite: 17]
              const Text('Waktu Habis!'), //[cite: 17]
            ], //[cite: 17]
          ), //[cite: 17]
          content: const Text(
            //[cite: 17]
            'Durasi hitung mundur telah selesai.', //[cite: 17]
            style: TextStyle(fontSize: 16), //[cite: 17]
          ), //[cite: 17]
          actions: [
            //[cite: 17]
            TextButton(
              //[cite: 17]
              onPressed: () {
                //[cite: 17]
                Navigator.of(context).pop(); // Menutup dialog[cite: 17]
              }, //[cite: 17]
              child: const Text(
                //[cite: 17]
                'OK', //[cite: 17]
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ), //[cite: 17]
              ), //[cite: 17]
            ), //[cite: 17]
          ], //[cite: 17]
        ); //[cite: 17]
      }, //[cite: 17]
    ); //[cite: 17]
  } //[cite: 17]

  void _pauseTimer() {
    //[cite: 17]
    _timer?.cancel(); //[cite: 17]
    setState(() {
      //[cite: 17]
      _isTimerRunning = false; //[cite: 17]
    }); //[cite: 17]
  } //[cite: 17]

  void _resetTimer() {
    //[cite: 17]
    _timer?.cancel(); //[cite: 17]
    setState(() {
      //[cite: 17]
      _isTimerRunning = false; //[cite: 17]
      _isTimerInitialized = false; //[cite: 17]
      _remainingSeconds = 0; //[cite: 17]
    }); //[cite: 17]
  } //[cite: 17]

  // Fungsi untuk menempelkan teks dari clipboard[cite: 17]
  Future<void> _pasteFromClipboard() async {
    //[cite: 17]
    ClipboardData? data = await Clipboard.getData(
      Clipboard.kTextPlain,
    ); //[cite: 17]
    if (data != null && data.text != null) {
      //[cite: 17]
      setState(() {
        //[cite: 17]
        _listController.text = data.text!; //[cite: 17]
      }); //[cite: 17]
    } //[cite: 17]
  } //[cite: 17]

  @override
  void dispose() {
    _minController.dispose(); //[cite: 17]
    _maxController.dispose(); //[cite: 17]
    _minLetterController.dispose(); //[cite: 17]
    _maxLetterController.dispose(); //[cite: 17]
    _listController.dispose(); //[cite: 17]
    _durationController.dispose(); //[cite: 17]
    _timer?.cancel(); //[cite: 17]
    _bannerAd
        ?.dispose(); // Hancurkan objek iklan dari memori saat halaman ditutup
    super.dispose(); //[cite: 17]
  }

  @override
  Widget build(BuildContext context) {
    String cardTitle = 'ANGKA ACAK'; //[cite: 17]
    if (_selectedType == RandomType.huruf) {
      //[cite: 17]
      cardTitle = 'HURUF ACAK'; //[cite: 17]
    } else if (_selectedType == RandomType.list) {
      //[cite: 17]
      cardTitle = 'HASIL ACAK LIST'; //[cite: 17]
    } //[cite: 17]

    return Scaffold(
      //[cite: 17]
      appBar: AppBar(
        //[cite: 17]
        title: const Text('Random Generator'), //[cite: 17]
        backgroundColor: Colors.indigo[800], //[cite: 17]
        elevation: 0, //[cite: 17]
      ), //[cite: 17]
      drawer: const DrawerMenu(isRandomActive: true), //[cite: 17]
      body: Container(
        //[cite: 17]
        decoration: BoxDecoration(
          //[cite: 17]
          gradient: LinearGradient(
            //[cite: 17]
            colors: [Colors.indigo[50]!, Colors.white], //[cite: 17]
            begin: Alignment.topCenter, //[cite: 17]
            end: Alignment.bottomCenter, //[cite: 17]
          ), //[cite: 17]
        ), //[cite: 17]
        child: Center(
          //[cite: 17]
          child: SingleChildScrollView(
            //[cite: 17]
            padding: const EdgeInsets.all(24.0), //[cite: 17]
            child: Column(
              //[cite: 17]
              mainAxisAlignment: MainAxisAlignment.center, //[cite: 17]
              children: [
                //[cite: 17]
                // Pilihan Mode: Angka, Huruf, atau List[cite: 17]
                SegmentedButton<RandomType>(
                  //[cite: 17]
                  segments: const <ButtonSegment<RandomType>>[
                    //[cite: 17]
                    ButtonSegment<RandomType>(
                      //[cite: 17]
                      value: RandomType.angka, //[cite: 17]
                      label: Text('Angka'), //[cite: 17]
                      icon: Icon(Icons.numbers), //[cite: 17]
                    ), //[cite: 17]
                    ButtonSegment<RandomType>(
                      //[cite: 17]
                      value: RandomType.huruf, //[cite: 17]
                      label: Text('Huruf'), //[cite: 17]
                      icon: Icon(Icons.text_fields), //[cite: 17]
                    ), //[cite: 17]
                    ButtonSegment<RandomType>(
                      //[cite: 17]
                      value: RandomType.list, //[cite: 17]
                      label: Text('List'), //[cite: 17]
                      icon: Icon(Icons.list), //[cite: 17]
                    ), //[cite: 17]
                  ], //[cite: 17]
                  selected: <RandomType>{_selectedType}, //[cite: 17]
                  onSelectionChanged: (Set<RandomType> newSelection) {
                    //[cite: 17]
                    setState(() {
                      //[cite: 17]
                      _selectedType = newSelection.first; //[cite: 17]
                      _result = null; //[cite: 17]
                    }); //[cite: 17]
                  }, //[cite: 17]
                ), //[cite: 17]
                const SizedBox(height: 24), //[cite: 17]
                // Card Display Utama untuk Hasil[cite: 17]
                Card(
                  //[cite: 17]
                  elevation: 8, //[cite: 17]
                  shadowColor: Colors.indigo.withOpacity(0.3), //[cite: 17]
                  shape: RoundedRectangleBorder(
                    //[cite: 17]
                    borderRadius: BorderRadius.circular(24), //[cite: 17]
                  ), //[cite: 17]
                  child: Container(
                    //[cite: 17]
                    width: double.infinity, //[cite: 17]
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                    ), //[cite: 17]
                    padding: const EdgeInsets.symmetric(
                      //[cite: 17]
                      vertical: 40, //[cite: 17]
                      horizontal: 20, //[cite: 17]
                    ), //[cite: 17]
                    child: Column(
                      //[cite: 17]
                      children: [
                        //[cite: 17]
                        Text(
                          //[cite: 17]
                          cardTitle, //[cite: 17]
                          style: TextStyle(
                            //[cite: 17]
                            fontSize: 14, //[cite: 17]
                            fontWeight: FontWeight.bold, //[cite: 17]
                            color: Colors.indigo[300], //[cite: 17]
                            letterSpacing: 2, //[cite: 17]
                          ), //[cite: 17]
                        ), //[cite: 17]
                        const SizedBox(height: 20), //[cite: 17]
                        AnimatedSwitcher(
                          //[cite: 17]
                          duration: const Duration(
                            milliseconds: 300,
                          ), //[cite: 17]
                          transitionBuilder: //[cite: 17]
                          (Widget child, Animation<double> animation) {
                            //[cite: 17]
                            return ScaleTransition(
                              //[cite: 17]
                              scale: animation, //[cite: 17]
                              child: child, //[cite: 17]
                            ); //[cite: 17]
                          }, //[cite: 17]
                          child: Text(
                            //[cite: 17]
                            _result ?? '?', //[cite: 17]
                            key: ValueKey<String>(_result ?? '-'), //[cite: 17]
                            textAlign: TextAlign.center, //[cite: 17]
                            style: TextStyle(
                              //[cite: 17]
                              fontSize: //[cite: 17]
                                  _selectedType ==
                                          RandomType.list && //[cite: 17]
                                      _result !=
                                          null //[cite: 17]
                                  ? (_result!.length >
                                            50 //[cite: 17]
                                        ? 18 //[cite: 17]
                                        : _result!.length >
                                              20 //[cite: 17]
                                        ? 24 //[cite: 17]
                                        : 36) //[cite: 17]
                                  : (_selectedType ==
                                            RandomType
                                                .list //[cite: 17]
                                        ? 36 //[cite: 17]
                                        : 84), //[cite: 17]
                              fontWeight: //[cite: 17]
                                  _result != null &&
                                      _result!.length >
                                          20 //[cite: 17]
                                  ? FontWeight
                                        .w600 //[cite: 17]
                                  : FontWeight.w900, //[cite: 17]
                              color: Colors.indigo[900], //[cite: 17]
                            ), //[cite: 17]
                          ), //[cite: 17]
                        ), //[cite: 17]
                      ], //[cite: 17]
                    ), //[cite: 17]
                  ), //[cite: 17]
                ), //[cite: 17]
                const SizedBox(height: 32), //[cite: 17]
                // Card Input Pengaturan (Kondisional berdasarkan mode)[cite: 17]
                Card(
                  //[cite: 17]
                  elevation: 4, //[cite: 17]
                  shape: RoundedRectangleBorder(
                    //[cite: 17]
                    borderRadius: BorderRadius.circular(16), //[cite: 17]
                  ), //[cite: 17]
                  child: Container(
                    //[cite: 17]
                    width: double.infinity, //[cite: 17]
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                    ), //[cite: 17]
                    padding: const EdgeInsets.all(24.0), //[cite: 17]
                    child: Column(
                      //[cite: 17]
                      crossAxisAlignment: CrossAxisAlignment.start, //[cite: 17]
                      children: [
                        //[cite: 17]
                        if (_selectedType == RandomType.list) ...[
                          //[cite: 17]
                          Row(
                            //[cite: 17]
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween, //[cite: 17]
                            children: [
                              //[cite: 17]
                              Text(
                                //[cite: 17]
                                'Masukkan Daftar Teks', //[cite: 17]
                                style: TextStyle(
                                  //[cite: 17]
                                  fontSize: 16, //[cite: 17]
                                  fontWeight: FontWeight.bold, //[cite: 17]
                                  color: Colors.grey[800], //[cite: 17]
                                ), //[cite: 17]
                              ), //[cite: 17]
                              IconButton(
                                //[cite: 17]
                                icon: const Icon(
                                  //[cite: 17]
                                  Icons
                                      .assignment_returned_rounded, //[cite: 17]
                                ), //[cite: 17]
                                tooltip: 'Paste dari Clipboard', //[cite: 17]
                                color: Colors.indigo[700], //[cite: 17]
                                onPressed: _pasteFromClipboard, //[cite: 17]
                              ), //[cite: 17]
                            ], //[cite: 17]
                          ), //[cite: 17]
                          const SizedBox(height: 8), //[cite: 17]
                          TextField(
                            //[cite: 17]
                            controller: _listController, //[cite: 17]
                            maxLines: 5, //[cite: 17]
                            keyboardType: TextInputType.multiline, //[cite: 17]
                            decoration: InputDecoration(
                              //[cite: 17]
                              hintText: //[cite: 17]
                                  'Pisahkan setiap pilihan dengan baris baru...', //[cite: 17]
                              border: OutlineInputBorder(
                                //[cite: 17]
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), //[cite: 17]
                              ), //[cite: 17]
                            ), //[cite: 17]
                          ), //[cite: 17]
                        ] else ...[
                          //[cite: 17]
                          Text(
                            //[cite: 17]
                            _selectedType ==
                                    RandomType
                                        .angka //[cite: 17]
                                ? 'Tentukan Rentang Angka' //[cite: 17]
                                : 'Tentukan Rentang Huruf (A-Z)', //[cite: 17]
                            style: TextStyle(
                              //[cite: 17]
                              fontSize: 16, //[cite: 17]
                              fontWeight: FontWeight.bold, //[cite: 17]
                              color: Colors.grey[800], //[cite: 17]
                            ), //[cite: 17]
                          ), //[cite: 17]
                          const SizedBox(height: 16), //[cite: 17]
                          Row(
                            //[cite: 17]
                            children: [
                              //[cite: 17]
                              Expanded(
                                //[cite: 17]
                                child: TextField(
                                  //[cite: 17]
                                  controller:
                                      _selectedType ==
                                          RandomType
                                              .angka //[cite: 17]
                                      ? _minController //[cite: 17]
                                      : _minLetterController, //[cite: 17]
                                  keyboardType: //[cite: 17]
                                      _selectedType ==
                                          RandomType
                                              .angka //[cite: 17]
                                      ? TextInputType
                                            .number //[cite: 17]
                                      : TextInputType.text, //[cite: 17]
                                  maxLength:
                                      _selectedType ==
                                          RandomType
                                              .huruf //[cite: 17]
                                      ? 1 //[cite: 17]
                                      : null, //[cite: 17]
                                  decoration: InputDecoration(
                                    //[cite: 17]
                                    counterText: "", //[cite: 17]
                                    labelText: 'Min', //[cite: 17]
                                    border: OutlineInputBorder(
                                      //[cite: 17]
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ), //[cite: 17]
                                    ), //[cite: 17]
                                    prefixIcon: const Icon(
                                      //[cite: 17]
                                      Icons.arrow_downward, //[cite: 17]
                                    ), //[cite: 17]
                                  ), //[cite: 17]
                                ), //[cite: 17]
                              ), //[cite: 17]
                              const SizedBox(width: 16), //[cite: 17]
                              Expanded(
                                //[cite: 17]
                                child: TextField(
                                  //[cite: 17]
                                  controller:
                                      _selectedType ==
                                          RandomType
                                              .angka //[cite: 17]
                                      ? _maxController //[cite: 17]
                                      : _maxLetterController, //[cite: 17]
                                  keyboardType: //[cite: 17]
                                      _selectedType ==
                                          RandomType
                                              .angka //[cite: 17]
                                      ? TextInputType
                                            .number //[cite: 17]
                                      : TextInputType.text, //[cite: 17]
                                  maxLength:
                                      _selectedType ==
                                          RandomType
                                              .huruf //[cite: 17]
                                      ? 1 //[cite: 17]
                                      : null, //[cite: 17]
                                  decoration: InputDecoration(
                                    //[cite: 17]
                                    counterText: "", //[cite: 17]
                                    labelText: 'Max', //[cite: 17]
                                    border: OutlineInputBorder(
                                      //[cite: 17]
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ), //[cite: 17]
                                    ), //[cite: 17]
                                    prefixIcon: const Icon(
                                      Icons.arrow_upward,
                                    ), //[cite: 17]
                                  ), //[cite: 17]
                                ), //[cite: 17]
                              ), //[cite: 17]
                            ], //[cite: 17]
                          ), //[cite: 17]
                        ], //[cite: 17]
                      ], //[cite: 17]
                    ), //[cite: 17]
                  ), //[cite: 17]
                ), //[cite: 17]
                const SizedBox(height: 32), //[cite: 17]
                // Tombol Generator[cite: 17]
                Container(
                  //[cite: 17]
                  width: double.infinity, //[cite: 17]
                  constraints: const BoxConstraints(maxWidth: 400), //[cite: 17]
                  height: 56, //[cite: 17]
                  child: ElevatedButton(
                    //[cite: 17]
                    onPressed: _generateRandomValue, //[cite: 17]
                    style: ElevatedButton.styleFrom(
                      //[cite: 17]
                      backgroundColor: Colors.indigo[700], //[cite: 17]
                      shape: RoundedRectangleBorder(
                        //[cite: 17]
                        borderRadius: BorderRadius.circular(16), //[cite: 17]
                      ), //[cite: 17]
                      elevation: 4, //[cite: 17]
                    ), //[cite: 17]
                    child: const Row(
                      //[cite: 17]
                      mainAxisAlignment: MainAxisAlignment.center, //[cite: 17]
                      children: [
                        //[cite: 17]
                        Icon(Icons.casino, color: Colors.white), //[cite: 17]
                        SizedBox(width: 12), //[cite: 17]
                        Text(
                          //[cite: 17]
                          'ACAK SEKARANG', //[cite: 17]
                          style: TextStyle(
                            //[cite: 17]
                            fontSize: 16, //[cite: 17]
                            fontWeight: FontWeight.bold, //[cite: 17]
                            color: Colors.white, //[cite: 17]
                            letterSpacing: 1, //[cite: 17]
                          ), //[cite: 17]
                        ), //[cite: 17]
                      ], //[cite: 17]
                    ), //[cite: 17]
                  ), //[cite: 17]
                ), //[cite: 17]
                const SizedBox(height: 24), //[cite: 17]
                // CARD BARU: Fitur Timer Hitung Mundur Adaptif[cite: 17]
                Card(
                  //[cite: 17]
                  elevation: 4, //[cite: 17]
                  shape: RoundedRectangleBorder(
                    //[cite: 17]
                    borderRadius: BorderRadius.circular(16), //[cite: 17]
                  ), //[cite: 17]
                  child: Container(
                    //[cite: 17]
                    width: double.infinity, //[cite: 17]
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                    ), //[cite: 17]
                    padding: const EdgeInsets.all(24.0), //[cite: 17]
                    child: Column(
                      //[cite: 17]
                      children: [
                        //[cite: 17]
                        Text(
                          //[cite: 17]
                          'TIMER HITUNG MUNDUR', //[cite: 17]
                          style: TextStyle(
                            //[cite: 17]
                            fontSize: 12, //[cite: 17]
                            fontWeight: FontWeight.bold, //[cite: 17]
                            color: Colors.grey[600], //[cite: 17]
                            letterSpacing: 1.5, //[cite: 17]
                          ), //[cite: 17]
                        ), //[cite: 17]
                        const SizedBox(height: 16), //[cite: 17]
                        if (!_isTimerInitialized) //[cite: 17]
                          TextField(
                            //[cite: 17]
                            controller: _durationController, //[cite: 17]
                            keyboardType: TextInputType.number, //[cite: 17]
                            decoration: InputDecoration(
                              //[cite: 17]
                              labelText:
                                  'Durasi Hitung Mundur (Detik)', //[cite: 17]
                              border: OutlineInputBorder(
                                //[cite: 17]
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), //[cite: 17]
                              ), //[cite: 17]
                              prefixIcon: const Icon(Icons.timer), //[cite: 17]
                            ), //[cite: 17]
                          ) //[cite: 17]
                        else //[cite: 17]
                          Text(
                            //[cite: 17]
                            _isTimerInitialized &&
                                    _remainingSeconds ==
                                        0 //[cite: 17]
                                ? 'TIMER HABIS' //[cite: 17]
                                : '$_remainingSeconds Detik', //[cite: 17]
                            style: TextStyle(
                              //[cite: 17]
                              fontSize: //[cite: 17]
                                  _isTimerInitialized &&
                                      _remainingSeconds ==
                                          0 //[cite: 17]
                                  ? 28 //[cite: 17]
                                  : 40, //[cite: 17]
                              fontWeight: FontWeight.bold, //[cite: 17]
                              color: //[cite: 17]
                                  _isTimerInitialized &&
                                      _remainingSeconds ==
                                          0 //[cite: 17]
                                  ? Colors.red[700] //[cite: 17]
                                  : Colors.indigo[900], //[cite: 17]
                            ), //[cite: 17]
                          ), //[cite: 17]
                        const SizedBox(height: 16), //[cite: 17]
                        Row(
                          //[cite: 17]
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly, //[cite: 17]
                          children: [
                            //[cite: 17]
                            if (_isTimerRunning) //[cite: 17]
                              ElevatedButton.icon(
                                //[cite: 17]
                                onPressed: _pauseTimer, //[cite: 17]
                                icon: const Icon(Icons.pause), //[cite: 17]
                                label: const Text('Pause'), //[cite: 17]
                                style: ElevatedButton.styleFrom(
                                  //[cite: 17]
                                  backgroundColor:
                                      Colors.amber[800], //[cite: 17]
                                ), //[cite: 17]
                              ) //[cite: 17]
                            else //[cite: 17]
                              ElevatedButton.icon(
                                //[cite: 17]
                                onPressed: //[cite: 17]
                                    _isTimerInitialized && //[cite: 17]
                                        _remainingSeconds ==
                                            0 //[cite: 17]
                                    ? null //[cite: 17]
                                    : _startTimer, //[cite: 17]
                                icon: const Icon(Icons.play_arrow), //[cite: 17]
                                label: const Text('Mulai'), //[cite: 17]
                                style: ElevatedButton.styleFrom(
                                  //[cite: 17]
                                  backgroundColor:
                                      Colors.green[700], //[cite: 17]
                                ), //[cite: 17]
                              ), //[cite: 17]
                            ElevatedButton.icon(
                              //[cite: 17]
                              onPressed: _resetTimer, //[cite: 17]
                              icon: const Icon(Icons.refresh), //[cite: 17]
                              label: const Text('Reset'), //[cite: 17]
                              style: ElevatedButton.styleFrom(
                                //[cite: 17]
                                backgroundColor: Colors.grey[700], //[cite: 17]
                              ), //[cite: 17]
                            ), //[cite: 17]
                          ], //[cite: 17]
                        ), //[cite: 17]
                      ], //[cite: 17]
                    ), //[cite: 17]
                  ), //[cite: 17]
                ), //[cite: 17]
              ], //[cite: 17]
            ), //[cite: 17]
          ), //[cite: 17]
        ), //[cite: 17]
      ), //[cite: 17]
      // IMPLEMENTASI LAYOUT FOOTER BANNER ADMOB KHUSUS ANDROID
      bottomNavigationBar:
          _isAdLoaded && _bannerAd != null && Platform.isAndroid
          ? SafeArea(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
