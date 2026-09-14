import 'package:flutter/material.dart';

/// Soft pastel storybook palette. Everything in the game pulls its colours from
/// here so the whole thing reads as one cohesive, cute world.
class Pal {
  const Pal._();

  // Sky & scenery
  static const skyTop = Color(0xFFFFE3F1);
  static const skyMid = Color(0xFFCDEBFF);
  static const skyBottom = Color(0xFFE8FBF3);
  static const cloud = Color(0xFFFFFFFF);
  static const hillFar = Color(0xFFD5C7F5);
  static const hillNear = Color(0xFFAFE3C8);

  // Terrain
  static const grassTop = Color(0xFF8BE0A4);
  static const grassTopLight = Color(0xFFB6F0C6);
  static const dirt = Color(0xFFE0B892);
  static const dirtDark = Color(0xFFC79A74);
  static const platform = Color(0xFFFFC9DE);
  static const platformEdge = Color(0xFFFF9EC4);

  // Emery, the princess. Warm brown skin and dark chestnut curls, kept soft
  // and pastel so she sits comfortably in the storybook world.
  static const dress = Color(0xFFFF9EC4);
  static const dressDark = Color(0xFFF279AB);
  static const skin = Color(0xFFC98F66);
  static const skinShade = Color(0xFFB37A52);
  static const hair = Color(0xFF6B4A38);
  static const hairDark = Color(0xFF523726);
  static const crown = Color(0xFFFFE066);
  static const crownGem = Color(0xFF7FD8FF);

  // Enemies
  static const blob = Color(0xFFB9A0F0);
  static const blobDark = Color(0xFF9B7EE0);
  static const hopper = Color(0xFF8FD8F5);
  static const hopperDark = Color(0xFF6BBEE0);
  static const eyeWhite = Color(0xFFFFFFFF);
  static const eyeDark = Color(0xFF453056);

  // Pickups & goal
  static const gem = Color(0xFF7FE7D8);
  static const gemLight = Color(0xFFCFFAF3);
  static const heart = Color(0xFFFF7C9C);
  static const door = Color(0xFFC58A5E);
  static const doorDark = Color(0xFF9E6B45);
  static const roof = Color(0xFFFF9EC4);

  // UI
  static const ink = Color(0xFF5A4468);
  static const sparkle = Color(0xFFFFF3B0);
}
