import 'package:flutter/material.dart';

/// Regex matching official VEX Tournament SKUs (supports RE- and VE- prefixes)
final RegExp skuRegex = RegExp(
  r'^(RE|VE)-(VRC|V5RC|VEXU|VURC|VIQRC|VIQC|VAIRC|IQ|V5|U|AI)-[0-9]{2}-[0-9]{4,6}$',
  caseSensitive: false,
);

/// Validate whether a string is a correctly formatted VEX SKU
bool isValidSku(String sku) {
  return skuRegex.hasMatch(sku.trim());
}

/// Check if a search query looks like an event SKU query (starts with RE- or VE-)
bool isSkuQuery(String? query) {
  if (query == null || query.isEmpty) return false;
  final upper = query.trim().toUpperCase();
  return upper.startsWith('RE-') || upper.startsWith('VE-');
}

/// Check if the SKU represents a VEX IQ Robotics Competition event
bool isVIQRC(String? sku) {
  if (sku == null || sku.isEmpty) return false;
  final upper = sku.toUpperCase();
  return upper.contains('VIQRC') ||
      upper.contains('VIQC') ||
      upper.contains('VE-IQ') ||
      upper.contains('-IQ-') ||
      upper == 'IQ';
}

/// Check if the SKU represents a VEX AI Robotics Competition event
bool isVAIRC(String? sku) {
  if (sku == null || sku.isEmpty) return false;
  final upper = sku.toUpperCase();
  return upper.contains('VAIRC') ||
      upper.contains('VAIC') ||
      upper.contains('VEX AI') ||
      upper.contains('VE-AI') ||
      upper.contains('-AI-') ||
      upper == 'AI';
}

/// Check if the SKU represents a VEX U competition event
bool isVEXU(String? sku) {
  if (sku == null || sku.isEmpty) return false;
  final upper = sku.toUpperCase();
  return upper.contains('VEXU') ||
      upper.contains('VURC') ||
      upper.contains('VE-U') ||
      upper.contains('-U-') ||
      upper == 'U';
}

/// Check if the SKU represents a V5RC / VRC / VEX U competition event
bool isV5(String? sku) {
  if (sku == null || sku.isEmpty) return false;
  final upper = sku.toUpperCase();
  return upper.contains('V5RC') ||
      upper.contains('VRC') ||
      upper.contains('VEXU') ||
      upper.contains('VURC') ||
      upper.contains('VE-V5') ||
      upper.contains('-V5-') ||
      upper.contains('V5') ||
      isVEXU(upper);
}

/// Extract readable program code from SKU
String getSkuProgram(String? sku) {
  if (sku == null || sku.isEmpty) return 'VEX';
  if (isVIQRC(sku)) return 'VIQRC';
  if (isVAIRC(sku)) return 'VEX AI';
  if (isVEXU(sku)) return 'VEX U';
  if (isV5(sku)) return 'V5RC';
  return 'VEX';
}

/// Extract program brand color
Color getProgramColor(String program) {
  switch (program.toUpperCase()) {
    case 'V5RC':
    case 'VRC':
    case 'V5':
      return const Color(0xFFC8102E); // V5 Crimson
    case 'VIQRC':
    case 'VIQC':
    case 'IQ':
      return const Color(0xFF0072CE); // VIQRC Blue
    case 'VEX U':
    case 'VURC':
    case 'U':
      return const Color(0xFF5C2D91); // VEX U Purple
    case 'VEX AI':
    case 'VAIRC':
    case 'AI':
      return const Color(0xFF107C41); // VEX AI Green
    default:
      return const Color(0xFF64748B); // Slate Grey
  }
}
