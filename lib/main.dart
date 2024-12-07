import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '주소 검색',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AddressSearchPage(),
    );
  }
}

class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({super.key});

  @override
  _AddressSearchPageState createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  List<dynamic> data = [];
  List<dynamic> searchResults = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://apis.data.go.kr/B551011/KorWithService1/areaBasedList1?MobileOS=and&MobileApp=app&serviceKey=iXoQf3UDOt7v9vzF1%2BB5KUZf4uU7H5pSsRb7WWQr3bzJsDDOo0G%2B8Z99BZhVhIOvJbjznVY2hAyESeqcw%2FL28A%3D%3D&_type=json&numOfRows=9000&contentTypeId=39'),
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedResponse);
        setState(() {
          data = jsonResponse['response']['body']['items']['item'] ?? [];
        });
      } else {
        print("API 호출 실패: 상태 코드 ${response.statusCode}");
      }
    } catch (error) {
      print("데이터 로드 중 오류 발생: $error");
    }
  }

  void searchAddress() {
    final input = searchController.text.trim();

    if (input.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("데이터가 아직 로드되지 않았습니다.")),
      );
      return;
    }

    setState(() {
      searchResults = data
          .where((item) =>
              item['addr1'] != null && item['addr1'].toString().contains(input))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: '검색어를 입력하세요',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => searchAddress(),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: searchAddress,
              child: const Text('검색'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: searchResults.isNotEmpty
                  ? ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final item = searchResults[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailPage(contentid: item['contentid']),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] ?? '제목 없음',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text("콘텐츠 ID: ${item['contentid'] ?? 'N/A'}"),
                                  Text("주소: ${item['addr1'] ?? 'N/A'}"),
                                  Text("지역 코드: ${item['areacode'] ?? 'N/A'}"),
                                  Text(
                                      "시군구 코드: ${item['sigungucode'] ?? 'N/A'}"),
                                  Text("X좌표: ${item['mapx'] ?? 'N/A'}"),
                                  Text("Y좌표: ${item['mapy'] ?? 'N/A'}"),
                                  const SizedBox(height: 6),
                                  Image.network(
                                    item['firstimage'] ?? '',
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(child: Text("결과가 없습니다.")),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatefulWidget {
  final String contentid;

  const DetailPage({super.key, required this.contentid});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map<String, dynamic>? detailData;
  List<Map<String, dynamic>> reviews = [];
  TextEditingController reviewController = TextEditingController();
  double rating = 3.0;

  @override
  void initState() {
    super.initState();
    fetchDetailData();
  }

  Future<void> fetchDetailData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://apis.data.go.kr/B551011/KorWithService1/detailIntro1?MobileOS=AND&MobileApp=app&contentId=${widget.contentid}&contentTypeId=39&_type=json&serviceKey=iXoQf3UDOt7v9vzF1%2BB5KUZf4uU7H5pSsRb7WWQr3bzJsDDOo0G%2B8Z99BZhVhIOvJbjznVY2hAyESeqcw%2FL28A%3D%3D'),
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedResponse);
        final items = jsonResponse['response']?['body']?['items']?['item'];
        if (items is List && items.isNotEmpty) {
          setState(() {
            detailData = items[0];
          });
        } else if (items is Map<String, dynamic>) {
          setState(() {
            detailData = items;
          });
        } else {
          print("데이터가 없습니다. items가 null이거나 형식이 올바르지 않습니다.");
        }
      } else {
        print("상세 정보 API 호출 실패: 상태 코드 ${response.statusCode}");
      }
    } catch (error) {
      print("상세 정보 로드 중 오류 발생: $error");
    }
  }

  void addReview() {
    if (reviewController.text.isNotEmpty) {
      setState(() {
        reviews.add({
          'review': reviewController.text,
          'rating': rating,
        });
        reviewController.clear();
        rating = 3.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(detailData?['title'] ?? '상세 페이지'),
      ),
      body: detailData != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("신용카드 가능: ${detailData?['chkcreditcardfood'] ?? 'N/A'}"),
                  Text("할인정보: ${detailData?['discountinfofood'] ?? 'N/A'}"),
                  Text("대표 메뉴: ${detailData?['firstmenu'] ?? 'N/A'}"),
                  Text("문의 및 안내: ${detailData?['infocenterfood'] ?? 'N/A'}"),
                  Text("어린이 놀이방 여부: ${detailData?['kidsfacility'] ?? 'N/A'}"),
                  // Text("개업일: ${detailData?['opendatefood'] ?? 'N/A'}"),
                  // Text("영업시간: ${detailData?['opentimefood'] ?? 'N/A'}"),
                  // Text("포장 가능: ${detailData?['packing'] ?? 'N/A'}"),
                  // Text("주차시설: ${detailData?['parkingfood'] ?? 'N/A'}"),
                  // Text("예약 안내: ${detailData?['reservationfood'] ?? 'N/A'}"),
                  // Text("쉬는 날: ${detailData?['restdatefood'] ?? 'N/A'}"),
                  // Text("규모: ${detailData?['scalefood'] ?? 'N/A'}"),
                  // Text("좌석수: ${detailData?['seat'] ?? 'N/A'}"),
                  Text("금연/흡연 여부: ${detailData?['smoking'] ?? 'N/A'}"),
                  Text("취급 메뉴: ${detailData?['treatmenu'] ?? 'N/A'}"),
                  const SizedBox(height: 20),
                  const Text(
                    '리뷰',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return ListTile(
                          title: Text(review['review']),
                          subtitle: Text('별점: ${review['rating']}'),
                        );
                      },
                    ),
                  ),
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(
                      labelText: '리뷰 작성',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Slider(
                    value: rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: rating.toString(),
                    onChanged: (value) {
                      setState(() {
                        rating = value;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: addReview,
                    child: const Text('리뷰 등록'),
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
