// swift-tools-version: 5.8

import AppleProductTypes
import PackageDescription

let package = Package(
    name: "Phantom",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Phantom",
            targets: ["AppModule"],
            bundleIdentifier: "com.phantom.app",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .moon),
            accentColor: .presetColor(.purple),
            supportedDeviceFamilies: [
                .pad
            ],
            supportedInterfaceOrientations: [
                .landscapeLeft,
                .landscapeRight
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources"
        )
    ]
)
