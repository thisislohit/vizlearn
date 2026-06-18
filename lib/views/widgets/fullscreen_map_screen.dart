// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:vizlearn/utils/app_export.dart';
//
// class FullScreenMap extends StatefulWidget {
//   final LatLng initialLocation;
//
//   FullScreenMap({required this.initialLocation});
//
//   @override
//   _FullScreenMapState createState() => _FullScreenMapState();
// }
//
// class _FullScreenMapState extends State<FullScreenMap> {
//   late GoogleMapController mapController;
//   TextEditingController _controller = TextEditingController();
//   List<Map<String, dynamic>> _suggestions = [];
//   LatLng? selectedLocation;
//
//   Future<List<Map<String, dynamic>>> fetchGooglePlaceSuggestions(String input) async {
//     final String? apiKey = dotenv.env['MAPS_API_KEY']; // Replace with your Google API Key
//     const url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
//
//     final response = await http.get(
//       Uri.parse('$url?input=$input&key=$apiKey&components=country:IN'),
//     );
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return List<Map<String, dynamic>>.from(data['predictions']);
//     } else {
//       throw Exception('Failed to fetch suggestions');
//     }
//   }
//
//   Future<Map<String, dynamic>?> fetchGooglePlaceDetails(String placeId) async {
//     final String? apiKey = dotenv.env['MAPS_API_KEY']; // Replace with your Google API Key
//     const url = 'https://maps.googleapis.com/maps/api/place/details/json';
//
//     final response = await http.get(
//       Uri.parse('$url?place_id=$placeId&key=$apiKey'),
//     );
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['result'];
//     } else {
//       print('Failed to fetch place details: ${response.body}');
//       return null;
//     }
//   }
//
//   Future<String?> reverseGeocode(LatLng location) async {
//     final String? apiKey = dotenv.env['MAPS_API_KEY']; // Replace with your Google API Key
//     const url = 'https://maps.googleapis.com/maps/api/geocode/json';
//
//     final response = await http.get(
//       Uri.parse('$url?latlng=${location.latitude},${location.longitude}&key=$apiKey'),
//     );
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['results'] != null && data['results'].isNotEmpty) {
//         return data['results'][0]['formatted_address'];
//       }
//     }
//     return null;
//   }
//
//   void goToLocation(double lat, double lng) {
//     mapController.animateCamera(
//       CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
//     );
//     setState(() {
//       selectedLocation = LatLng(lat, lng);
//     });
//   }
//
//   void onOkPressed() async {
//     if (selectedLocation != null) {
//       final address = await reverseGeocode(selectedLocation!);
//       if (address != null) {
//         Navigator.pop(context, address); // Pass the address back
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBar(title: 'Select Location',backgroundColor: AppColors.primary,textColor: AppColors.white,),
//       body: Stack(
//         children: [
//           IgnorePointer(
//             ignoring: _suggestions.isNotEmpty, // Ignore touches if dropdown is visible
//             child: GoogleMap(
//               initialCameraPosition: CameraPosition(
//                 target: widget.initialLocation,
//                 zoom: 15.0,
//               ),
//               myLocationEnabled: true,
//               compassEnabled: true,
//               zoomGesturesEnabled: true,
//               tiltGesturesEnabled: true,
//               zoomControlsEnabled: true,
//               onMapCreated: (controller) {
//                 mapController = controller;
//               },
//               onTap: (LatLng location) {
//                 setState(() {
//                   selectedLocation = location;
//                 });
//               },
//               markers: selectedLocation != null
//                   ? {
//                 Marker(
//                   markerId: const MarkerId("selected-location"),
//                   position: selectedLocation!,
//                 )
//               }
//                   : {},
//             ),
//           ),
//           Positioned(
//             top: 10,
//             left: 10,
//             right: 10,
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _controller,
//                   decoration: InputDecoration(
//                     hintText: "Search location",
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide.none,
//                     ),
//                     contentPadding: const EdgeInsets.all(15),
//                     suffixIcon: IconButton(
//                       icon: const Icon(Icons.clear),
//                       onPressed: () {
//                         setState(() {
//                           _controller.clear();
//                           _suggestions = [];
//                         });
//                       },
//                     ),
//                   ),
//                   onChanged: (value) async {
//                     if (value.isNotEmpty) {
//                       _suggestions = await fetchGooglePlaceSuggestions(value);
//                       setState(() {});
//                     } else {
//                       setState(() {
//                         _suggestions = [];
//                       });
//                     }
//                   },
//                 ),
//                 if (_suggestions.isNotEmpty)
//                   Container(
//                     color: Colors.white,
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: _suggestions.length,
//                       itemBuilder: (context, index) {
//                         final suggestion = _suggestions[index];
//                         return ListTile(
//                           title: Text(suggestion['description']),
//                           onTap: () async {
//                             final placeDetails = await fetchGooglePlaceDetails(
//                                 suggestion['place_id']);
//                             if (placeDetails != null) {
//                               final location = placeDetails['geometry']['location'];
//                               goToLocation(location['lat'], location['lng']);
//                               setState(() {
//                                 _suggestions = [];
//                                 _controller.text = suggestion['description'];
//                               });
//                             }
//                           },
//                         );
//                       },
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           if (selectedLocation != null)
//             Positioned(
//               bottom: 20,
//               left: 20,
//               right: 20,
//               child: ElevatedButton(
//                 onPressed: onOkPressed,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                   textStyle: const TextStyle(fontSize: 18),
//                 ),
//                 child: const Text("OK"),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }