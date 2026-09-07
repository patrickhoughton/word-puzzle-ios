#!/usr/bin/env swift
// Reproducible app-icon generator (UX-04 / D-08).
// Usage: swift scripts/GenerateAppIcon.swift <a|b> <light|dark|tinted> <out.png>
// Renders at 1024x1024, strips the alpha channel (iOS icons must be opaque),
// and writes a PNG. Requires no third-party tooling.
import SwiftUI
import AppKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - Shape

/// Regular hexagon with a vertex pointing up (matches the icon's own
/// concept geometry — see 05-03-PLAN.md interfaces section).
struct IconHexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3 - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Colors

/// The exact AccentColor value: sRGB 0xF5/0xB8/0x00.
let gold = Color(red: Double(0xF5) / 255, green: Double(0xB8) / 255, blue: Double(0x00) / 255)

enum Appearance: String {
    case light, dark, tinted

    var backgroundColor: Color {
        switch self {
        case .light: return .white
        case .dark: return Color(white: 0.07)
        case .tinted: return Color(white: 0.07)
        }
    }

    /// Opaque CGColor used to flatten the render (matches backgroundColor).
    var backgroundCGColor: CGColor {
        switch self {
        case .light: return CGColor(gray: 1.0, alpha: 1.0)
        case .dark, .tinted: return CGColor(gray: 0.07, alpha: 1.0)
        }
    }

    var centerFill: Color {
        self == .tinted ? Color(white: 0.85) : gold
    }

    var glyphColor: Color {
        self == .tinted ? Color(white: 0.15) : .black
    }

    var outerFill: Color {
        switch self {
        case .light: return Color(white: 0.85)
        case .dark: return Color(white: 0.22)
        case .tinted: return Color(white: 0.35)
        }
    }
}

enum Concept: String {
    case a, b
}

// MARK: - Concept views

struct ConceptAView: View {
    let appearance: Appearance

    var body: some View {
        ZStack {
            appearance.backgroundColor
            IconHexagon()
                .fill(appearance.centerFill)
                .frame(width: 720, height: 720)
            Text("W")
                .font(.system(size: 420, weight: .bold, design: .rounded))
                .foregroundStyle(appearance.glyphColor)
        }
        .frame(width: 1024, height: 1024)
    }
}

struct ConceptBView: View {
    let appearance: Appearance

    /// Seven-tile honeycomb: one centre + six outer at 60-degree intervals,
    /// scaled so the whole cluster occupies ~80% of the 1024 canvas.
    /// Ratio matches GameTheme.outerRingRadius = hexSize * 1.6 so the icon
    /// echoes the in-game flower's actual proportions (no overlap gaps).
    private let hexSize: CGFloat = 195
    private let outerRadius: CGFloat = 312

    private var outerOffsets: [CGSize] {
        (0..<6).map { i in
            let angle = Double(i) * .pi / 3 - .pi / 2
            return CGSize(
                width: outerRadius * cos(angle),
                height: outerRadius * sin(angle)
            )
        }
    }

    var body: some View {
        ZStack {
            appearance.backgroundColor
            ForEach(0..<6, id: \.self) { i in
                IconHexagon()
                    .fill(appearance.outerFill)
                    .frame(width: hexSize, height: hexSize)
                    .offset(outerOffsets[i])
            }
            IconHexagon()
                .fill(appearance.centerFill)
                .frame(width: hexSize, height: hexSize)
            Text("W")
                .font(.system(size: 85, weight: .bold, design: .rounded))
                .foregroundStyle(appearance.glyphColor)
        }
        .frame(width: 1024, height: 1024)
    }
}

// MARK: - Render + flatten + write

@MainActor
func render(concept: Concept, appearance: Appearance, outputPath: String) {
    let content: AnyView
    switch concept {
    case .a: content = AnyView(ConceptAView(appearance: appearance))
    case .b: content = AnyView(ConceptBView(appearance: appearance))
    }

    let renderer = ImageRenderer(content: content)
    renderer.scale = 1

    guard let rendered = renderer.cgImage else {
        FileHandle.standardError.write("ERROR: ImageRenderer produced a nil cgImage\n".data(using: .utf8)!)
        exit(1)
    }

    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil, width: 1024, height: 1024,
        bitsPerComponent: 8, bytesPerRow: 0, space: cs,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        FileHandle.standardError.write("ERROR: failed to create flattening CGContext\n".data(using: .utf8)!)
        exit(1)
    }

    ctx.setFillColor(appearance.backgroundCGColor)
    ctx.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    ctx.draw(rendered, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))

    guard let flattened = ctx.makeImage() else {
        FileHandle.standardError.write("ERROR: failed to create flattened CGImage\n".data(using: .utf8)!)
        exit(1)
    }

    let url = URL(fileURLWithPath: outputPath) as CFURL
    guard let destination = CGImageDestinationCreateWithURL(
        url, UTType.png.identifier as CFString, 1, nil
    ) else {
        FileHandle.standardError.write("ERROR: failed to create CGImageDestination for \(outputPath)\n".data(using: .utf8)!)
        exit(1)
    }

    CGImageDestinationAddImage(destination, flattened, nil)
    guard CGImageDestinationFinalize(destination) else {
        FileHandle.standardError.write("ERROR: failed to finalize PNG at \(outputPath)\n".data(using: .utf8)!)
        exit(1)
    }
}

// MARK: - Entry point

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    FileHandle.standardError.write("""
    Usage: swift scripts/GenerateAppIcon.swift <a|b> <light|dark|tinted> <out.png>
    Got \(arguments.count - 1) argument(s): \(arguments.dropFirst().joined(separator: " "))
    """.data(using: .utf8)!)
    exit(1)
}

guard let concept = Concept(rawValue: arguments[1]) else {
    FileHandle.standardError.write("ERROR: unknown concept '\(arguments[1])' — expected 'a' or 'b'\n".data(using: .utf8)!)
    exit(1)
}

guard let appearance = Appearance(rawValue: arguments[2]) else {
    FileHandle.standardError.write("ERROR: unknown appearance '\(arguments[2])' — expected 'light', 'dark' or 'tinted'\n".data(using: .utf8)!)
    exit(1)
}

let outputPath = arguments[3]

MainActor.assumeIsolated {
    render(concept: concept, appearance: appearance, outputPath: outputPath)
}
