// swift-tools-version: 6.2

import PackageDescription

let GUILinkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS"], .when(configuration: .release)),
    // Update the entry point to point to the generated swift function, this lets us keep the same main method
    // for debug/release
    .unsafeFlags(["-Xlinker", "/ENTRY:mainCRTStartup"], .when(configuration: .release)),
]

let package = Package(
    name: "Swift-WinUI-Gallery",
    dependencies: [
        .package(url: "https://github.com/rayman-zhao/swift-cwinrt", branch: "wasdk1.8"),
        .package(url: "https://github.com/rayman-zhao/swift-windowsfoundation", branch: "wasdk1.8"),
        .package(url: "https://github.com/rayman-zhao/swift-uwp", branch: "wasdk1.8"),
        .package(url: "https://github.com/rayman-zhao/swift-windowsappsdk", branch: "wasdk1.8"),
        .package(url: "https://github.com/rayman-zhao/swift-winui", branch: "wasdk1.8"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftWinUIGallery",
            dependencies: [
                .product(name: "CWinRT", package: "swift-cwinrt"),
                .product(name: "WindowsFoundation", package: "swift-windowsfoundation"),
                .product(name: "UWP", package: "swift-uwp"),
                .product(name: "WinAppSDK", package: "swift-windowsappsdk"),
                .product(name: "WinUI", package: "swift-winui"),
            ],
            linkerSettings: GUILinkerSettings
        ), 
    ]
)
