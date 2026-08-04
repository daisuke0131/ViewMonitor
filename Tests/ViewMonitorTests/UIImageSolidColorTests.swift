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
}
