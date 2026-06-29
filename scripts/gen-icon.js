#!/usr/bin/osascript -l JavaScript
//
// gen-icon.js — generate a simple app icon PNG with no external dependencies.
//
// Uses macOS's built-in JavaScript-for-Automation (JXA) ObjC bridge to draw a
// rounded-square icon with centered initials. No ImageMagick / Pillow needed.
//
// Usage:
//   osascript -l JavaScript gen-icon.js <out.png> <initials> [hexColor]
//
// Args:
//   out.png   — destination PNG path (1024x1024)
//   initials  — 1-2 characters drawn in the center
//   hexColor  — background color as 6-digit hex (no #). Default: 4A90D9
//
ObjC.import('Cocoa');

function colorFromHex(hex) {
  const r = parseInt(hex.substr(0, 2), 16) / 255;
  const g = parseInt(hex.substr(2, 2), 16) / 255;
  const b = parseInt(hex.substr(4, 2), 16) / 255;
  return $.NSColor.colorWithSRGBRedGreenBlueAlpha(r, g, b, 1.0);
}

function run(argv) {
  const out = argv[0];
  const text = (argv[1] || '?').toUpperCase();
  const hex = (argv[2] || '4A90D9').replace('#', '');
  const size = 1024;

  const img = $.NSImage.alloc.initWithSize($.NSMakeSize(size, size));
  img.lockFocus;

  // Rounded-square background.
  const inset = size * 0.06;
  const rect = $.NSMakeRect(inset, inset, size - inset * 2, size - inset * 2);
  const radius = size * 0.2;
  const path = $.NSBezierPath.bezierPathWithRoundedRectXRadiusYRadius(rect, radius, radius);
  colorFromHex(hex).set;
  path.fill;

  // Centered initials. Drawn at an explicit point so it is centered on both
  // axes regardless of paragraph-style quirks.
  const fontSize = text.length > 1 ? size * 0.38 : size * 0.5;
  const attrs = $.NSMutableDictionary.alloc.init;
  attrs.setObjectForKey($.NSFont.boldSystemFontOfSize(fontSize), $.NSFontAttributeName);
  attrs.setObjectForKey($.NSColor.whiteColor, $.NSForegroundColorAttributeName);

  const ns = $(text);
  const tSize = ns.sizeWithAttributes(attrs);
  const point = $.NSMakePoint((size - tSize.width) / 2, (size - tSize.height) / 2);
  ns.drawAtPointWithAttributes(point, attrs);

  img.unlockFocus;

  const tiff = img.TIFFRepresentation;
  const rep = $.NSBitmapImageRep.imageRepWithData(tiff);
  const png = rep.representationUsingTypeProperties(4 /* NSBitmapImageFileTypePNG */, $());
  const ok = png.writeToFileAtomically($(out), true);
  if (!ok) {
    throw new Error('failed to write ' + out);
  }
  return out;
}
