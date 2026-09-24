import 'dart:math';

import 'zone_gating.dart';

/// Pure readers for ports.json rows (see portsSchema), shared by the boat,
/// port and camp screens and their tests.
String portNameFor(Map<String, dynamic> port, bool fr) {
  final name = port['portName']?.toString() ?? port['portID']?.toString() ?? '';
  final nameFr = port['portName_fr']?.toString() ?? '';
  return fr && nameFr.isNotEmpty ? nameFr : name;
}

String portDescriptionFor(Map<String, dynamic> port, bool fr) {
  final text = port['description']?.toString() ?? '';
  final textFr = port['description_fr']?.toString() ?? '';
  return fr && textFr.isNotEmpty ? textFr : text;
}

List<String> portZoneIds(Map<String, dynamic> port) =>
    (port['zoneIds'] as List?)?.map((e) => e.toString()).toList() ?? const [];

List<String> portShopIds(Map<String, dynamic> port) =>
    (port['shopIds'] as List?)?.map((e) => e.toString()).toList() ?? const [];

int portChapter(Map<String, dynamic> port) =>
    max(1, (port['chapter'] as num?)?.toInt() ?? 1);

/// Days at sea to reach the port, never below 1.
int portVoyageLength(Map<String, dynamic> port) =>
    max(1, (port['voyageLength'] as num?)?.toInt() ?? 2);

bool portIsHome(Map<String, dynamic> port) => port['isHome'] == true;

/// The camp's own shore -- the port a fresh boat starts moored at.
String? homePortId(Map<String, dynamic> ports) {
  for (final entry in ports.entries) {
    final port = entry.value;
    if (port is Map<String, dynamic> && portIsHome(port)) return entry.key;
  }
  return null;
}

/// A port is on the chart once the story has reached its chapter and its
/// required flags are set.
bool portUnlocked(
  Map<String, dynamic> port, {
  required int chapter,
  required Iterable<String> flags,
}) =>
    portChapter(port) <= chapter && meetsRequiredFlags(port, flags);

/// Where the boat is moored: the saved port, else the home port, else the
/// first port on the chart.
String? currentPortIdFor(Map<String, dynamic> ports, String savedPortId) {
  if (savedPortId.isNotEmpty && ports.containsKey(savedPortId)) {
    return savedPortId;
  }
  return homePortId(ports) ?? (ports.keys.isEmpty ? null : ports.keys.first);
}
