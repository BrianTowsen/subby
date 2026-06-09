import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

String slugify(String input) {
  var s = input.trim().toLowerCase();
  s = s.replaceAll(RegExp(r'\(.*?\)'), '');
  s = s.replaceAll('&', 'and');
  s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll(' ', '-');
  s = s.replaceAll(RegExp(r'-+'), '-');
  s = s.replaceAll(RegExp(r'^-+|-+$'), '');
  return s;
}
