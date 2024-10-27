import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:isolate/location_Data_model.dart';

// Future<List<double>> filterLocationsByDistance(
//     List<LocationData> dataPoints) async {
//   // Get the current location of the user
//   Position userPosition = await Geolocator.getCurrentPosition();

//   // Calculate distances directly without isolate
//   return dataPoints.map((point) {
//     final distance = Geolocator.distanceBetween(
//       userPosition.latitude,
//       userPosition.longitude,
//       point.latitude,
//       point.longitude,
//     );
//     return distance;
//   }).toList();
// }

//Helper class to pass multiple parameters in compute
class DistanceParams {
  final List<LocationData> dataPoints;
  final Position userPosition;

  DistanceParams(this.dataPoints, this.userPosition);
}

// Function for distance calculations
Future<List<double>> calculateDistances(DistanceParams params) async {
  return params.dataPoints.map((point) {
    final distance = Geolocator.distanceBetween(
      params.userPosition.latitude,
      params.userPosition.longitude,
      point.latitude,
      point.longitude,
    );
    return distance;
  }).toList();
}

// Main function to filter data points by distance
Future<List<double>> filterLocationsByDistance(
    List<LocationData> dataPoints) async {
  Position userPosition = await Geolocator.getCurrentPosition();

  // Use Isolate.compute to filter data points
  return await compute(
      calculateDistances, DistanceParams(dataPoints, userPosition));
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  List<double> filteredData = [];
  bool isLoading = false;

  Future<void> _getFilteredLocations() async {
    setState(() {
      isLoading = true;
    });
    filteredData = await filterLocationsByDistance(dataPoints);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permissions are denied."),
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location permissions are permanently denied."),
        ),
      );
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    checkPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Filtered Locations")),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            ElevatedButton(
                onPressed: () async {
                  await _getFilteredLocations();
                },
                child: const Text("Get Filtered Locations")),
            isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: ListView.builder(
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        filteredData[index];
                        return ListTile(
                          title: Text("Distance: ${filteredData[index]}}"),
                        );
                      },
                    ),
                  ),
          ],
        ));
  }
}
