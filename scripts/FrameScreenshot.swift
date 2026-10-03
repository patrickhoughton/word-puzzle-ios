#!/usr/bin/env swift
// Reproducible App Store screenshot compositor (UX-04 / D-09).
// Usage: swift scripts/FrameScreenshot.swift <raw.png> <caption> <out.png>
// Takes a raw Simulator capture, adds the gold marketing caption above it, and
// draws a simple rounded device bezel. The output canvas matches the raw
// capture's size, so a 6.9" iPhone raw (1320x2868) yields a 1320x2868 final and
// a 13" iPad raw (2064x2752) yields a 2064x2752 final. Requires no third-party
// tooling (fastlane/frameit and ImageMagick are not installed).
import SwiftUI
import AppKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - Constants

/// The exact AccentColor value: sRGB 0xF5/0xB8/0x00.
let gold = Color(red: Double(0xF5) / 255, green: Double(0xB8) / 255, blue: Double(0x00) / 255)

/// Canvas sizes App Store Connect accepts for the slots this project targets.
let supportedSizes: [(width: Int, height: Int, name: String)] = [
    (1320, 2868, "6.9\" iPhone"),
    (2064, 2752, "13\" iPad"),
]

// MARK: - Composition

struct FramedScreenshot: View {
    let screenshot: CGImage
    let caption: String
    let canvas: CGSize

    /// All metrics are tuned at the 1320pt-wide iPhone canvas and scaled by
    /// width, so the iPad canvas keeps the same proportions.
    private var unit: CGFloat { canvas.width / 1320 }

    /// The iPad canvas is nearly square, so the device must shrink further to
    /// leave room for the caption.
    private var deviceWidthFraction: CGFloat {
        canvas.height / canvas.width > 1.8 ? 0.78 : 0.66
    }

    private var deviceSize: CGSize {
        let width = canvas.width * deviceWidthFraction
        let aspect = CGFloat(screenshot.height) / CGFloat(screenshot.width)
        return CGSize(width: width, height: width * aspect)
    }

    /// iPhone screens have proportionally rounder corners than iPad screens; using
    /// the iPhone ratio on iPad clips the status bar text in the corners.
    private var cornerRadius: CGFloat {
        deviceSize.width * (canvas.height / canvas.width > 1.8 ? 0.07 : 0.03)
    }

    var body: some View {
        ZStack {
            Color(white: 0.08)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Text(caption)
                    .font(.system(size: 84 * unit, weight: .bold, design: .rounded))
                    .foregroundStyle(gold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 100 * unit)
                Spacer(minLength: 0)
                Image(decorative: screenshot, scale: 1)
                    .resizable()
                    .frame(width: deviceSize.width, height: deviceSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color(white: 0.25), lineWidth: 10 * unit)
                    )
                    .padding(.bottom, 90 * unit)
            }
        }
        .frame(width: canvas.width, height: canvas.height)
    }
}

// MARK: - Load / render / write

func fail(_ message: String) -> Never {
    FileHandle.standardError.write("ERROR: \(message)\n".data(using: .utf8)!)
    exit(1)
}

func loadImage(at path: String) -> CGImage {
    guard FileManager.default.fileExists(atPath: path) else {
        fail("input file not found: \(path)")
    }
    let url = URL(fileURLWithPath: path) as CFURL
    guard let source = CGImageSourceCreateWithURL(url, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fail("could not decode image at \(path)")
    }
    return image
}

@MainActor
func render(rawPath: String, caption: String, outputPath: String) {
    let screenshot = loadImage(at: rawPath)
    guard supportedSizes.contains(where: { $0.width == screenshot.width && $0.height == screenshot.height }) else {
        let expected = supportedSizes.map { "\($0.width)x\($0.height) (\($0.name))" }.joined(separator: " or ")
        fail("raw capture is \(screenshot.width)x\(screenshot.height), expected \(expected)")
    }

    let canvas = CGSize(width: screenshot.width, height: screenshot.height)
    let renderer = ImageRenderer(content: FramedScreenshot(screenshot: screenshot, caption: caption, canvas: canvas))
    renderer.scale = 1

    guard let rendered = renderer.cgImage else {
        fail("ImageRenderer produced a nil cgImage")
    }
    guard rendered.width == screenshot.width, rendered.height == screenshot.height else {
        fail("rendered \(rendered.width)x\(rendered.height), expected \(screenshot.width)x\(screenshot.height)")
    }

    let url = URL(fileURLWithPath: outputPath)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil
    ) else {
        fail("failed to create CGImageDestination for \(outputPath)")
    }

    CGImageDestinationAddImage(destination, rendered, nil)
    guard CGImageDestinationFinalize(destination) else {
        fail("failed to finalize PNG at \(outputPath)")
    }
    print("Wrote \(outputPath) (\(rendered.width)x\(rendered.height))")
}

// MARK: - Entry point

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    fail("""
    usage: swift scripts/FrameScreenshot.swift <raw.png> <caption> <out.png>
    Got \(arguments.count - 1) argument(s): \(arguments.dropFirst().joined(separator: " "))
    """)
}

let rawPath = arguments[1]
let caption = arguments[2]
let outputPath = arguments[3]

guard !caption.trimmingCharacters(in: .whitespaces).isEmpty else {
    fail("caption is empty — check shell quoting (an unescaped $ in the caption expands to nothing)")
}

MainActor.assumeIsolated {
    render(rawPath: rawPath, caption: caption, outputPath: outputPath)
}
