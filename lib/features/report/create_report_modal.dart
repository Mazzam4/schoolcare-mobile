import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
// Import google_maps_flutter hanya untuk non-web
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/widgets/toast_widget.dart';
import '../../core/api_config.dart'; // Sesuaikan titik-titiknya dengan posisi foldermu

class CreateReportModal extends StatefulWidget {
  const CreateReportModal({super.key});

  @override
  State<CreateReportModal> createState() => _CreateReportModalState();
}

class _CreateReportModalState extends State<CreateReportModal> {
  final DraggableScrollableController _scrollController =
      DraggableScrollableController();

  String _selectedType = "Fasilitas Rusak";
  String? _selectedCategory;
  String? _selectedLocation;
  final TextEditingController _customCategoryCtrl = TextEditingController();
  final TextEditingController _customLocationCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  Uint8List? _imageBytes;
  String? _base64Image;

  double? _latitude;
  double? _longitude;
  bool _isLoadingGps = false;
  bool _isSubmitting = false;

  int _wordCount = 0;
  final int _maxWords = 16;

  static const String _mapsApiKeyAndroid =
      'AIzaSyAbtOhrxJfQkHac3zKMWHCN9vbzKeJ03zo';
  static const String _mapsApiKeyWeb =
      'AIzaSyCDbYBrKCRr0eU--0Di12fpIqpz2ujoQ_g';
  static String get _mapsApiKey => kIsWeb ? _mapsApiKeyWeb : _mapsApiKeyAndroid;

  final Map<String, List<String>> _categoryOptions = {
    "Fasilitas Rusak": [
      "Lampu",
      "Kursi/Meja",
      "Pintu/Jendela",
      "AC/Kipas",
      "Proyektor",
      "Toilet",
      "Lainnya (Custom)",
    ],
    "Kebersihan": [
      "Sampah Berserakan",
      "Lantai Kotor",
      "Kamar Mandi Kotor",
      "Saluran Air Tersumbat",
      "Taman Tidak Terawat",
      "Ada Sampah di Laci",
      "Lainnya (Custom)",
    ],
  };

  final List<String> _locationOptions = [
    "Ruang 1",
    "Ruang 2",
    "Lab Komputer 1",
    "Perpustakaan",
    "Kantin",
    "Toilet 1",
    "Toilet 2",
    "Lapangan",
    "Parkiran",
    "Lainnya (Custom)",
  ];

  @override
  void initState() {
    super.initState();
    _descCtrl.addListener(_updateWordCount);
  }

  @override
  void dispose() {
    _customCategoryCtrl.dispose();
    _customLocationCtrl.dispose();
    _descCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    final text = _descCtrl.text.trim();
    setState(
      () => _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showAppToast(
          context,
          message: 'GPS tidak aktif',
          isSuccess: false,
          icon: Icons.location_off_outlined,
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showAppToast(
            context,
            message: 'Izin lokasi ditolak',
            isSuccess: false,
            icon: Icons.location_off_outlined,
          );
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  // ✅ Picker: web pakai iframe/url, mobile pakai GoogleMap
  Future<void> _openMapPicker() async {
    if (_latitude == null || _longitude == null) await _getLocation();
    if (_latitude == null || _longitude == null) return;

    if (kIsWeb) {
      // Web: tidak support google_maps_flutter, buka Google Maps di tab baru
      final url = 'https://www.google.com/maps?q=$_latitude,$_longitude';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } else {
      // Mobile: pakai native GoogleMap picker
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MapPickerScreen(initialLat: _latitude!, initialLng: _longitude!),
        ),
      );
      if (result != null) {
        setState(() {
          _latitude = result['lat'];
          _longitude = result['lng'];
        });
      }
    }
  }

  Future<void> _shareLocation() async {
    if (_latitude != null && _longitude != null) {
      final url = 'https://www.google.com/maps?q=$_latitude,$_longitude';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _submitReport() async {
    final category = _selectedCategory == "Lainnya (Custom)"
        ? _customCategoryCtrl.text
        : _selectedCategory;
    final location = _selectedLocation == "Lainnya (Custom)"
        ? _customLocationCtrl.text
        : _selectedLocation;

    if (category == null || category.isEmpty) {
      showAppToast(
        context,
        message: 'Pilih kategori terlebih dahulu',
        isSuccess: false,
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    if (location == null || location.isEmpty) {
      showAppToast(
        context,
        message: 'Pilih lokasi terlebih dahulu',
        isSuccess: false,
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    if (_descCtrl.text.isEmpty) {
      showAppToast(
        context,
        message: 'Deskripsi tidak boleh kosong',
        isSuccess: false,
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    if (_wordCount > _maxWords) {
      showAppToast(
        context,
        message: 'Deskripsi maksimal $_maxWords kata',
        isSuccess: false,
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final dio = Dio();

      final response = await dio.post(
        "${ApiConfig.baseUrl}/api/reports/create",
        data: {
          "type": _selectedType,
          "category": category,
          "location": location,
          "description": _descCtrl.text,
          "photoBase64": _base64Image,
          "latitude": _latitude,
          "longitude": _longitude,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context);
        showAppToast(
          context,
          message: 'Laporan berhasil dikirim!',
          isSuccess: true,
          icon: Icons.check_circle_outline_rounded,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Gagal mengirim laporan',
        isSuccess: false,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _scrollController,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.5, 0.9, 1.0],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      height: 4,
                      width: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 56, 16),
                    child: Row(
                      children: const [
                        Text(
                          'Buat Laporan',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTabBtn("Fasilitas Rusak"),
                        _buildTabBtn("Kebersihan"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kategori
                          _sectionLabel('Kategori'),
                          _buildDropdown(
                            value: _selectedCategory,
                            items: _categoryOptions[_selectedType]!,
                            hint: 'Pilih kategori',
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v),
                          ),
                          if (_selectedCategory == "Lainnya (Custom)") ...[
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _customCategoryCtrl,
                              hint: 'Masukkan kategori custom',
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Lokasi
                          _sectionLabel('Lokasi'),
                          _buildDropdown(
                            value: _selectedLocation,
                            items: _locationOptions,
                            hint: 'Pilih lokasi',
                            onChanged: (v) =>
                                setState(() => _selectedLocation = v),
                          ),
                          if (_selectedLocation == "Lainnya (Custom)") ...[
                            const SizedBox(height: 10),
                            _buildTextField(
                              controller: _customLocationCtrl,
                              hint: 'Masukkan lokasi custom',
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Deskripsi
                          _sectionLabel('Deskripsi'),
                          _buildTextField(
                            controller: _descCtrl,
                            hint: 'Jelaskan masalah secara singkat',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$_wordCount/$_maxWords kata',
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                fontSize: 12,
                                color: _wordCount > _maxWords
                                    ? const Color(0xFFFF3B30)
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Foto Bukti
                          _sectionLabel('Foto Bukti'),
                          GestureDetector(
                            onTap: _pickImage,
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  image: _imageBytes != null
                                      ? DecorationImage(
                                          image: MemoryImage(_imageBytes!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _imageBytes == null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_outlined,
                                            size: 36,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Tap untuk ambil foto',
                                            style: TextStyle(
                                              fontFamily: 'SF Pro Text',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ✅ GPS Section — layout baru, fixed overflow
                          _sectionLabel('Lokasi GPS'),
                          _buildGpsSection(),
                          const SizedBox(height: 32),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1C1C1E),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Kirim Laporan',
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Close Button
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F2F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ GPS Section — maps preview + koordinat berdampingan, fixed overflow
  Widget _buildGpsSection() {
    if (_isLoadingGps) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1C1C1E),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_latitude == null || _longitude == null) {
      // Belum ada lokasi
      return GestureDetector(
        onTap: _getLocation,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 36,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap untuk ambil lokasi GPS',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sudah ada lokasi — layout atas: maps preview | bawah: info + tombol
    final staticMapUrl =
        'https://maps.geoapify.com/v1/staticmap?style=osm-carto&width=600&height=300&center=lonlat:$_longitude,$_latitude&zoom=16&marker=lonlat:$_longitude,$_latitude;color:%23ff0000;size:medium&apiKey=caa5e20481224996ab88f0837cdba468';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Peta preview (atas) ──
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Static map image
                Image.network(
                  staticMapUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF2F2F7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Peta tidak tersedia',
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Overlay gradient bawah agar tombol terbaca
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Tombol Presisikan di atas peta
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: _openMapPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.my_location_rounded,
                            size: 14,
                            color: Color(0xFF1C1C1E),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Presisikan',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Info koordinat + tombol (bawah) ──
        Row(
          children: [
            // Koordinat
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koordinat GPS',
                      style: TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontFamily: 'SF Pro Text',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Tombol Share
            GestureDetector(
              onTap: _shareLocation,
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.share_location_rounded,
                  size: 20,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Tombol Ambil Ulang
            GestureDetector(
              onTap: _getLocation,
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBtn(String label) {
    bool isSelected = _selectedType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedType = label;
          _selectedCategory = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF1C1C1E)
                  : Colors.grey.shade500,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1C1E),
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true, // ✅ Fix overflow teks dropdown
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade500,
          ),
        ),
        icon: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        dropdownColor: Colors.white,
        style: const TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1C1C1E),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color(0xFF1C1C1E),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Colors.grey.shade500,
        ),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1C1C1E), width: 1),
        ),
      ),
    );
  }
}

// ==========================================
// MAP PICKER SCREEN — Mobile only
// ==========================================
class MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  const MapPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late GoogleMapController _mapController;
  late LatLng _selectedPosition;

  @override
  void initState() {
    super.initState();
    _selectedPosition = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1C1C1E),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Presisikan Lokasi',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 17,
            ),
            onMapCreated: (c) => _mapController = c,
            onTap: (pos) => setState(() => _selectedPosition = pos),
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedPosition,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Hint atas
          Positioned(
            top: 16,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap peta untuk memilih titik lokasi',
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tombol konfirmasi bawah
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Info koordinat terpilih
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, {
                      'lat': _selectedPosition.latitude,
                      'lng': _selectedPosition.longitude,
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1C1E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Konfirmasi Lokasi Ini',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
