// swift-tools-version: 6.2

import PackageDescription

let GUILinkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS"], .when(configuration: .release)),
    // Update the entry point to point to the generated swift function, this lets us keep the same main method
    // for debug/release
    .unsafeFlags(["-Xlinker", "/ENTRY:mainCRTStartup"], .when(configuration: .release)),
    .unsafeFlags(["-Xlinker", "Sources/Assets/Tiles/AppIcon.res"]),
]

let package = Package(
    name: "Swift-WinUI-Gallery",
    dependencies: [
        .package(url: "https://github.com/rayman-zhao/swift-cwinrt", branch: "main"),
        .package(url: "https://github.com/rayman-zhao/swift-windowsfoundation", branch: "main"),
        .package(url: "https://github.com/rayman-zhao/swift-cppwinrt", branch: "main"),
        .package(url: "https://github.com/rayman-zhao/swift-uwp", branch: "main"),
        .package(url: "https://github.com/rayman-zhao/swift-windowsappsdk", branch: "main"),
        .package(url: "https://github.com/rayman-zhao/swift-winui", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftWinUIGallery",
            dependencies: [
                .product(name: "CWinRT", package: "swift-cwinrt"),
                .product(name: "WindowsFoundation", package: "swift-windowsfoundation"),
                .product(name: "CppWinRT", package: "swift-cppwinrt"),
                .product(name: "UWP", package: "swift-uwp"),
                .product(name: "WinAppSDK", package: "swift-windowsappsdk"),
                .product(name: "WinUI", package: "swift-winui"),
            ],
            resources: [
                .copy("Assets")
            ],
            linkerSettings: GUILinkerSettings
        ), 
    ]
)
