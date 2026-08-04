import Testing
import UIKit
@testable import ViewMonitor

@Suite("UIImage+SolidColor")
@MainActor
struct UIImageSolidColorTests {

    @Test("既定では 1x1 の画像を作る")
    func createsOnePixelImageByDefault() {
        let image = UIImage.monitorSolidColor(.red)

        #expect(image.size == CGSize(width: 1, height: 1))
    }

    @Test("指定したサイズの画像を作る")
    func createsImageWithGivenSize() {
        let image = UIImage.monitorSolidColor(.red, size: CGSize(width: 4, height: 3))

        #expect(image.size == CGSize(width: 4, height: 3))
    }

    @Test("指定した色 (red) で塗りつぶされる")
    func fillsWithSpecifiedRedColor() throws {
        let image = UIImage.monitorSolidColor(.red)

        let pixel = try #require(firstPixelRGBA(of: image))
        #expect(pixel == RGBA(r: 255, g: 0, b: 0, a: 255))
    }

    @Test("指定した色 (blue) で塗りつぶされる")
    func fillsWithSpecifiedBlueColor() throws {
        let image = UIImage.monitorSolidColor(.blue)

        let pixel = try #require(firstPixelRGBA(of: image))
        #expect(pixel == RGBA(r: 0, g: 0, b: 255, a: 255))
    }

    /// 描画結果の左上1ピクセルの RGBA を取り出す。
    private func firstPixelRGBA(of image: UIImage) -> RGBA? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        var pixel: [UInt8] = [0, 0, 0, 0]
        guard let context = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return RGBA(r: pixel[0], g: pixel[1], b: pixel[2], a: pixel[3])
    }
}

/// テストで読み取ったピクセルの RGBA 値。
private struct RGBA: Equatable {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    let a: UInt8
}
