#!/usr/bin/env swift
import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Warm gradient backdrop — terracotta to deep clay
let cs = CGColorSpaceCreateDeviceRGB()
let grad = CGGradient(colorsSpace: cs, colors: [
    NSColor(red: 0.85, green: 0.455, blue: 0.31, alpha: 1).cgColor,  // #D9744F
    NSColor(red: 0.49, green: 0.18, blue: 0.08, alpha: 1).cgColor,   // #7E2D14
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: .init(x: 0, y: size), end: .init(x: size, y: 0), options: [])

// Subtle warm glow top-left
let glow = CGGradient(colorsSpace: cs, colors: [
    NSColor(white: 1.0, alpha: 0.25).cgColor,
    NSColor(white: 1.0, alpha: 0).cgColor,
] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow,
    startCenter: .init(x: size * 0.3, y: size * 0.75), startRadius: 0,
    endCenter: .init(x: size * 0.3, y: size * 0.75), endRadius: size * 0.6,
    options: [])

// Vessel silhouette — centered, bone-colored
let cx = size / 2
let vesselTop = size * 0.26
let vesselBottom = size * 0.82
let lipWidth: CGFloat = 240
let bellyWidth: CGFloat = 560
let baseWidth: CGFloat = 340
let lipDrop: CGFloat = 30

let vessel = NSBezierPath()
vessel.move(to: .init(x: cx - lipWidth/2, y: size - vesselTop))
vessel.line(to: .init(x: cx + lipWidth/2, y: size - vesselTop))
vessel.line(to: .init(x: cx + lipWidth/2, y: size - vesselTop - lipDrop))
vessel.curve(to: .init(x: cx + bellyWidth/2, y: size - (vesselTop + (vesselBottom-vesselTop) * 0.45)),
             controlPoint1: .init(x: cx + lipWidth/2 + 40, y: size - vesselTop - 90),
             controlPoint2: .init(x: cx + bellyWidth/2, y: size - vesselTop - 200))
vessel.curve(to: .init(x: cx + baseWidth/2, y: size - vesselBottom),
             controlPoint1: .init(x: cx + bellyWidth/2 - 20, y: size - vesselBottom + 40),
             controlPoint2: .init(x: cx + baseWidth/2 + 30, y: size - vesselBottom + 20))
vessel.line(to: .init(x: cx - baseWidth/2, y: size - vesselBottom))
vessel.curve(to: .init(x: cx - bellyWidth/2, y: size - (vesselTop + (vesselBottom-vesselTop) * 0.45)),
             controlPoint1: .init(x: cx - baseWidth/2 - 30, y: size - vesselBottom + 20),
             controlPoint2: .init(x: cx - bellyWidth/2 + 20, y: size - vesselBottom + 40))
vessel.curve(to: .init(x: cx - lipWidth/2, y: size - vesselTop - lipDrop),
             controlPoint1: .init(x: cx - bellyWidth/2, y: size - vesselTop - 200),
             controlPoint2: .init(x: cx - lipWidth/2 - 40, y: size - vesselTop - 90))
vessel.close()

// Shadow under vessel
ctx.saveGState()
ctx.setShadow(offset: .init(width: 0, height: -20), blur: 40, color: NSColor.black.withAlphaComponent(0.25).cgColor)
NSColor(red: 0.961, green: 0.937, blue: 0.902, alpha: 1).setFill()  // #F5EFE6
vessel.fill()
ctx.restoreGState()

// Highlight down the left side
let highlight = NSBezierPath()
highlight.move(to: .init(x: cx - bellyWidth/2 + 40, y: size - vesselTop - 80))
highlight.curve(to: .init(x: cx - baseWidth/2 + 30, y: size - vesselBottom + 60),
                controlPoint1: .init(x: cx - bellyWidth/2 + 10, y: size - vesselTop - 250),
                controlPoint2: .init(x: cx - bellyWidth/2 + 10, y: size - vesselBottom + 80))
highlight.curve(to: .init(x: cx - bellyWidth/2 + 120, y: size - (vesselTop + (vesselBottom-vesselTop) * 0.45)),
                controlPoint1: .init(x: cx - bellyWidth/2 + 80, y: size - vesselBottom + 30),
                controlPoint2: .init(x: cx - bellyWidth/2 + 120, y: size - vesselBottom - 60))
highlight.close()
NSColor.white.withAlphaComponent(0.35).setFill()
highlight.fill()

// Dark rim on lip — suggests shadow inside vessel
let rim = NSBezierPath(ovalIn: CGRect(x: cx - lipWidth/2, y: size - vesselTop - 24, width: lipWidth, height: 28))
NSColor(red: 0.247, green: 0.157, blue: 0.094, alpha: 0.55).setFill()  // #3F2818
rim.fill()

image.unlockFocus()

// Save PNG
let tiff = image.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
let png = rep.representation(using: .png, properties: [:])!
let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "./AppIcon.png"
try! png.write(to: URL(fileURLWithPath: path))
print("Wrote \(path) \(png.count) bytes")
