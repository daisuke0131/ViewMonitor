import AVFoundation
import CoreGraphics
import Darwin
import Foundation
import ImageIO
import UniformTypeIdentifiers

private let usage = """
Usage: video-to-gif.swift <input-mp4> <output-gif> [--width 360] [--fps 10] [--max-bytes 10485760]
"""

private enum ToolError: LocalizedError {
    case invalidArgument(String)
    case invalidVideo(String)
    case conversionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidArgument(let message),
             .invalidVideo(let message),
             .conversionFailed(let message):
            return message
        }
    }
}

private struct Options {
    let inputURL: URL
    let outputURL: URL
    let width: Int
    let fps: Int
    let maxBytes: Int

    static func parse(_ arguments: [String]) throws -> Options? {
        if arguments == ["--help"] {
            print(usage)
            return nil
        }

        guard arguments.count >= 2 else {
            throw ToolError.invalidArgument(usage)
        }

        let inputURL = URL(fileURLWithPath: arguments[0]).standardizedFileURL
        let outputURL = URL(fileURLWithPath: arguments[1]).standardizedFileURL
        var width = 360
        var fps = 10
        var maxBytes = 10_485_760
        var index = 2

        while index < arguments.count {
            guard index + 1 < arguments.count else {
                throw ToolError.invalidArgument("Missing value for \(arguments[index]).\n\(usage)")
            }

            let name = arguments[index]
            let value = arguments[index + 1]
            switch name {
            case "--width":
                guard let parsed = Int(value), (1...4_096).contains(parsed) else {
                    throw ToolError.invalidArgument("--width must be between 1 and 4096.")
                }
                width = parsed
            case "--fps":
                guard let parsed = Int(value), (1...60).contains(parsed) else {
                    throw ToolError.invalidArgument("--fps must be between 1 and 60.")
                }
                fps = parsed
            case "--max-bytes":
                guard let parsed = Int(value), parsed > 0 else {
                    throw ToolError.invalidArgument("--max-bytes must be greater than zero.")
                }
                maxBytes = parsed
            default:
                throw ToolError.invalidArgument("Unknown option: \(name).\n\(usage)")
            }
            index += 2
        }

        return Options(
            inputURL: inputURL,
            outputURL: outputURL,
            width: width,
            fps: fps,
            maxBytes: maxBytes
        )
    }
}

@main
private enum VideoToGIF {
    static func main() async {
        do {
            guard let options = try Options.parse(Array(CommandLine.arguments.dropFirst())) else {
                return
            }
            try await convert(options)
        } catch {
            let message = "error: \(error.localizedDescription)\n"
            FileHandle.standardError.write(Data(message.utf8))
            exit(EXIT_FAILURE)
        }
    }

    private static func convert(_ options: Options) async throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: options.inputURL.path) else {
            throw ToolError.invalidArgument("Input video does not exist: \(options.inputURL.path)")
        }

        let asset = AVURLAsset(url: options.inputURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        guard durationSeconds.isFinite, durationSeconds > 0 else {
            throw ToolError.invalidVideo("Input video has no readable duration.")
        }

        let frameCount = max(1, Int(ceil(durationSeconds * Double(options.fps))))
        let outputDirectory = options.outputURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let temporaryURL = outputDirectory.appendingPathComponent(
            ".\(options.outputURL.lastPathComponent).\(UUID().uuidString).tmp.gif"
        )
        defer {
            try? fileManager.removeItem(at: temporaryURL)
        }

        guard let destination = CGImageDestinationCreateWithURL(
            temporaryURL as CFURL,
            UTType.gif.identifier as CFString,
            frameCount,
            nil
        ) else {
            throw ToolError.conversionFailed("Could not create GIF destination.")
        }

        let gifProperties: [CFString: Any] = [
            kCGImagePropertyGIFLoopCount: 0
        ]
        CGImageDestinationSetProperties(
            destination,
            [kCGImagePropertyGIFDictionary: gifProperties] as CFDictionary
        )

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        var outputHeight = 0
        for frameIndex in 0..<frameCount {
            let requestedSeconds = min(
                Double(frameIndex) / Double(options.fps),
                max(0, durationSeconds - 0.001)
            )
            let requestedTime = CMTime(seconds: requestedSeconds, preferredTimescale: 600)
            let generated = try await generator.image(at: requestedTime)
            let resized = try resize(generated.image, width: options.width)
            outputHeight = resized.height

            let delay = frameIndex == frameCount - 1 ? 2.0 : 1.0 / Double(options.fps)
            let frameGIFProperties: [CFString: Any] = [
                kCGImagePropertyGIFDelayTime: delay,
                kCGImagePropertyGIFUnclampedDelayTime: delay
            ]
            let frameProperties: [CFString: Any] = [
                kCGImagePropertyGIFDictionary: frameGIFProperties
            ]
            CGImageDestinationAddImage(destination, resized, frameProperties as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw ToolError.conversionFailed("ImageIO could not finalize the GIF.")
        }

        let attributes = try fileManager.attributesOfItem(atPath: temporaryURL.path)
        guard let byteCount = attributes[.size] as? NSNumber else {
            throw ToolError.conversionFailed("Could not read generated GIF size.")
        }
        let bytes = byteCount.intValue
        guard bytes > 0 else {
            throw ToolError.conversionFailed("Generated GIF is empty.")
        }
        guard bytes <= options.maxBytes else {
            throw ToolError.conversionFailed(
                "Generated GIF is \(bytes) bytes, above the \(options.maxBytes)-byte limit."
            )
        }

        if fileManager.fileExists(atPath: options.outputURL.path) {
            _ = try fileManager.replaceItemAt(options.outputURL, withItemAt: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: options.outputURL)
        }

        print("GIF: \(options.outputURL.path)")
        print("Dimensions: \(options.width)x\(outputHeight)")
        print("Frames: \(frameCount)")
        print("Bytes: \(bytes)")
    }

    private static func resize(_ image: CGImage, width: Int) throws -> CGImage {
        let scale = Double(width) / Double(image.width)
        let height = max(1, Int((Double(image.height) * scale).rounded()))
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ToolError.conversionFailed("Could not create resize context.")
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let resized = context.makeImage() else {
            throw ToolError.conversionFailed("Could not render resized frame.")
        }
        return resized
    }
}
