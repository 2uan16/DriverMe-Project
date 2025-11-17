import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_keys.dart';

class SearchDestinationScreen extends StatefulWidget {
  final String title;
  final String hint;

  const SearchDestinationScreen({
    super.key,
    required this.title,
    required this.hint,
  });

  @override
  State<SearchDestinationScreen> createState() =>
      _SearchDestinationScreenState();
}

class _SearchDestinationScreenState extends State<SearchDestinationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {

      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/'
            '${Uri.encodeComponent(input)}.json'
            '?access_token=${ApiKeys.mapboxAccessToken}'
            '&country=VN' // Chỉ tìm ở Việt Nam
            '&language=vi' // Ngôn ngữ tiếng Việt
            '&proximity=105.8542,21.0285' // Ưu tiên kết quả gần Hà Nội
            '&types=address,poi,place,locality,neighborhood' // ✅ BẮT BUỘC: Tìm cả số nhà
            '&limit=15' // Tăng số kết quả
            '&autocomplete=true', // ✅ Bật autocomplete
      );

      print('🔍 Searching: $input');
      print('📡 URL: ${url.toString()}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['features'] != null) {
          final features = data['features'] as List;

          // ✅ Filter và sắp xếp kết quả
          final filteredResults = features
              .where((feature) {
            // Ưu tiên address (có số nhà)
            final types = feature['place_type'] as List?;
            return types != null &&
                (types.contains('address') ||
                    types.contains('poi') ||
                    types.contains('place'));
          })
              .map((feature) {
            final placeType = (feature['place_type'] as List).first;
            final relevance = feature['relevance'] ?? 0.0;

            return {
              'place_id': feature['id'],
              'description': feature['place_name'], // Địa chỉ đầy đủ
              'text': feature['text'], // Tên ngắn (có số nhà nếu là address)
              'address': feature['address'] ?? '', // Số nhà (nếu có)
              'latitude': feature['center'][1],
              'longitude': feature['center'][0],
              'place_type': placeType,
              'relevance': relevance,
            };
          })
              .toList();

          // Sắp xếp: address (có số nhà) lên trước
          filteredResults.sort((a, b) {
            // Ưu tiên address
            if (a['place_type'] == 'address' && b['place_type'] != 'address') {
              return -1;
            }
            if (a['place_type'] != 'address' && b['place_type'] == 'address') {
              return 1;
            }
            // Sau đó sort theo relevance
            return (b['relevance'] as double).compareTo(a['relevance'] as double);
          });

          setState(() {
            _predictions = filteredResults;
          });

          print('✅ Found ${_predictions.length} results');
          print('📍 First result: ${_predictions.isNotEmpty ? _predictions[0]['description'] : 'none'}');
        }
      } else {
        print('❌ Mapbox Geocoding Error: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Search error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8A00),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFF8A00),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _predictions = [];
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _searchPlaces(value);
              },
            ),
          ),

          // Loading
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Color(0xFFFF8A00),
              ),
            ),

          // Results
          Expanded(
            child: _predictions.isEmpty && !_isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Nhập địa chỉ để tìm kiếm'
                        : 'Không tìm thấy kết quả',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Thử tìm: "Hà Nội", "Hồ Chí Minh", "Đà Nẵng"',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                final placeType = prediction['place_type'] ?? '';
                final address = prediction['address'] ?? '';

                // Icon theo loại địa điểm
                IconData iconData = Icons.location_on;
                Color iconColor = const Color(0xFFFF8A00);

                if (placeType == 'address') {
                  iconData = Icons.home;
                  iconColor = Colors.green;
                } else if (placeType == 'poi') {
                  iconData = Icons.place;
                  iconColor = Colors.blue;
                }

                return ListTile(
                  leading: Icon(iconData, color: iconColor),
                  title: Row(
                    children: [
                      // Hiển thị số nhà nếu có
                      if (address.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          prediction['text'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    prediction['description'] ?? '',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(context, prediction['description']);
                  },
                );
              },
            )
          ),
        ],
      ),
    );
  }
}