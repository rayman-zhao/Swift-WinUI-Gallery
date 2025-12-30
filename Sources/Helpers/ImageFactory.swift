import Foundation
import UWP
import WinAppSDK
import WindowsFoundation
import WinUI

class ImageFactory {
    public static func createImage(
        height: Double, 
        width: Double, 
        imagePath: String, 
        imageThickness: [Double], 
        stretch: Stretch) -> Image {
        let image: Image = Image()
        image.height = height
        image.width = width
        image.margin = Thickness(
            left: imageThickness[0], 
            top: imageThickness[1], 
            right: imageThickness[2], 
            bottom: imageThickness[3]
        )
        image.stretch = stretch
        
        if imagePath.isEmpty { fatalError("imagePath is empty!") }
        let uri = Uri(imagePath)
        let bitmapImage = BitmapImage()
        bitmapImage.uriSource = uri
        image.source = bitmapImage
        return image
    }

    public static func parsePath(_ path: String) -> (directory: String, filename: String, extension: String) {
        // 处理路径分隔符，兼容Windows和Unix风格
        let normalizedPath = path.replacingOccurrences(of: "\\", with: "/")
        
        // 分割路径组件
        let components = normalizedPath.split(separator: "/")
        
        // 获取目录名（不包括最后一个组件）
        let directoryComponents = components.dropLast()
        let directory = directoryComponents.joined(separator: "/")
        
        // 获取完整文件名（最后一个组件）
        let fullFilename = components.last ?? ""
        
        // 分离文件名和扩展名
        let filenameComponents = fullFilename.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        
        let filename: String
        let `extension`: String
        
        if filenameComponents.count == 2 {
            filename = String(filenameComponents[0])
            `extension` = String(filenameComponents[1])
        } else if filenameComponents.count == 1 {
            // 没有扩展名的情况
            filename = String(filenameComponents[0])
            `extension` = ""
        } else {
            // 多个点的情况，通常第一个是文件名，其余是扩展名
            filename = String(filenameComponents[0])
            `extension` = filenameComponents.dropFirst().joined(separator: ".")
        }
        
        return (directory: directory, filename: filename, extension: `extension`)
    }
    
    /// 获取路径中的目录名
    /// - Parameter path: 完整路径
    /// - Returns: 目录名
    public static func getDirectory(from path: String) -> String {
        return parsePath(path).directory
    }
    
    /// 获取路径中的文件名（不包括扩展名）
    /// - Parameter path: 完整路径
    /// - Returns: 文件名
    public static func getFilename(from path: String) -> String {
        return parsePath(path).filename
    }
    
    /// 获取路径中的扩展名
    /// - Parameter path: 完整路径
    /// - Returns: 扩展名
    public static func getExtension(from path: String) -> String {
        return parsePath(path).extension
    }
    
    /// 获取完整的文件名（包括扩展名）
    /// - Parameter path: 完整路径
    /// - Returns: 完整文件名
    public static func getFullFilename(from path: String) -> String {
        let parsed = parsePath(path)
        if parsed.extension.isEmpty {
            return parsed.filename
        } else {
            return "\(parsed.filename).\(parsed.extension)"
        }
    }
}