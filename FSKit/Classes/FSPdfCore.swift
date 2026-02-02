//
//  FSPdfCore.swift
//  FSKit
//
//  Translated from Objective-C to Swift
//

import UIKit
import CoreText

public class FSPdf: NSObject {
    
    // MARK: - PDF from String
    public static func pdf(forString text: String, pdfName: String? = nil, password: String? = nil) -> String? {
        guard !text.isEmpty else { return nil }
        
        let fileName = pdfName ?? "\(Int(Date().timeIntervalSince1970)).pdf"
        let pdfPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        
        var auxiliaryInfo: [CFString: Any] = [
            kCGPDFContextTitle: "扶氏软件" as CFString,
            kCGPDFContextCreator: "FuSoft" as CFString
        ]
        
        if let password = password {
            auxiliaryInfo[kCGPDFContextUserPassword] = password as CFString
            auxiliaryInfo[kCGPDFContextOwnerPassword] = password as CFString
        }
        
        guard let attributedString = CFAttributedStringCreate(nil, text as CFString, nil),
              let framesetter = CTFramesetterCreateWithAttributedString(attributedString) as CTFramesetter? else {
            return nil
        }
        
        UIGraphicsBeginPDFContextToFile(pdfPath, .zero, auxiliaryInfo as [AnyHashable: Any])
        
        var currentRange = CFRange(location: 0, length: 0)
        var currentPage = 0
        var done = false
        
        let screenBounds = UIScreen.main.bounds
        
        while !done {
            UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: screenBounds.width, height: screenBounds.height), nil)
            currentPage += 1
            drawPageNumber(currentPage)
            currentRange = renderPage(currentPage, textRange: currentRange, framesetter: framesetter)
            
            if currentRange.location == CFAttributedStringGetLength(attributedString) {
                done = true
            }
        }
        
        UIGraphicsEndPDFContext()
        return pdfPath
    }
    
    private static func renderPage(_ pageNum: Int, textRange currentRange: CFRange, framesetter: CTFramesetter) -> CFRange {
        guard let context = UIGraphicsGetCurrentContext() else { return currentRange }
        
        context.textMatrix = .identity
        
        let screenBounds = UIScreen.main.bounds
        let frameRect = CGRect(x: 20, y: 20, width: screenBounds.width - 40, height: screenBounds.height - 50)
        
        let framePath = CGMutablePath()
        framePath.addRect(frameRect)
        
        let frameRef = CTFramesetterCreateFrame(framesetter, currentRange, framePath, nil)
        
        context.translateBy(x: 0, y: screenBounds.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        CTFrameDraw(frameRef, context)
        
        var newRange = CTFrameGetVisibleStringRange(frameRef)
        newRange.location += newRange.length
        newRange.length = 0
        
        return newRange
    }
    
    private static func drawPageNumber(_ pageNum: Int) {
        let pageString = "- \(pageNum) -"
        let font = UIFont.systemFont(ofSize: 10)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.lightGray
        ]
        
        let size = (pageString as NSString).boundingRect(
            with: CGSize(width: 100, height: 20),
            options: .usesFontLeading,
            attributes: attributes,
            context: nil
        )
        
        let screenBounds = UIScreen.main.bounds
        let stringRect = CGRect(
            x: screenBounds.width / 2 - size.width / 2,
            y: screenBounds.height - 20,
            width: size.width,
            height: 20
        )
        
        (pageString as NSString).draw(in: stringRect, withAttributes: attributes)
    }
    
    // MARK: - PDF from View
    public static func pdf(forView view: UIView, pdfName: String) -> String? {
        guard !pdfName.isEmpty else { return nil }
        
        let path = (NSTemporaryDirectory() as NSString).appendingPathComponent(pdfName)
        let url = URL(fileURLWithPath: path) as CFURL
        
        var mediaBox = view.bounds
        guard let pdfContext = CGContext(url, mediaBox: &mediaBox, nil) else { return nil }
        
        pdfContext.beginPage(mediaBox: nil)
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: 0, y: view.bounds.height)
        transform = transform.scaledBy(x: 1.0, y: -1.0)
        pdfContext.concatenate(transform)
        
        view.layer.render(in: pdfContext)
        
        pdfContext.endPage()
        pdfContext.closePDF()
        
        return path
    }
    
    // MARK: - PDF from Image
    public static func pdf(forImage image: UIImage, pdfName: String? = nil, password: String? = nil) -> String? {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }
        return pdf(forImageData: data, pdfName: pdfName, password: password)
    }
    
    public static func pdf(forImageData data: Data, pdfName: String? = nil, password: String? = nil) -> String? {
        guard !data.isEmpty else { return nil }
        
        let fileName = pdfName ?? "\(Int(Date().timeIntervalSince1970)).pdf"
        let path = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        
        guard let image = UIImage(data: data) else { return nil }
        let rect = CGRect(origin: .zero, size: image.size)
        
        var auxiliaryInfo: [CFString: Any] = [
            kCGPDFContextTitle: "Photo from iPrivate Album" as CFString,
            kCGPDFContextCreator: "iPrivate Album" as CFString
        ]
        
        if let password = password {
            auxiliaryInfo[kCGPDFContextUserPassword] = password as CFString
            auxiliaryInfo[kCGPDFContextOwnerPassword] = password as CFString
        }
        
        let url = URL(fileURLWithPath: path) as CFURL
        var mediaBox = rect
        
        guard let pdfContext = CGContext(url, mediaBox: &mediaBox, auxiliaryInfo as CFDictionary) else { return nil }
        
        let boxData = Data(bytes: &mediaBox, count: MemoryLayout<CGRect>.size) as CFData
        let pageInfo: [CFString: Any] = [kCGPDFContextMediaBox: boxData]
        
        pdfContext.beginPDFPage(pageInfo as CFDictionary)
        
        guard let dataProvider = CGDataProvider(data: data as CFData),
              let cgImage = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            return nil
        }
        
        pdfContext.draw(cgImage, in: rect)
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        return path
    }
}
