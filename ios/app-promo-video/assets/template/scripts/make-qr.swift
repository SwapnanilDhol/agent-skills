// Writes a QR code PNG with Core Image, for the ticket photo the app scans.
// Usage: swift scripts/make-qr.swift <payload> <out.png>
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
let filter = CIFilter.qrCodeGenerator()
filter.message = Data(arguments[1].utf8)
filter.correctionLevel = "M"
let image = filter.outputImage!.transformed(by: CGAffineTransform(scaleX: 16, y: 16))
let cgImage = CIContext().createCGImage(image, from: image.extent)!
let url = URL(fileURLWithPath: arguments[2]) as CFURL
let destination = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, cgImage, nil)
CGImageDestinationFinalize(destination)
