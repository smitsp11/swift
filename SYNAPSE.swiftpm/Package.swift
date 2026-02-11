// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SYNAPSE",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .iOSApplication(
            name: "SYNAPSE",
            targets: ["SYNAPSE"],
            bundleIdentifier: "com.synapse.neuralplayground",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .brain),
            accentColor: .presetColor(.cyan),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [.portrait],
            capabilities: [
                .camera(purposeString:
                    "SYNAPSE uses your camera to track hand movements "
                  + "and visualize neural signals in real time."
                )
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "SYNAPSE",
            path: "Sources"
        )
    ]
)
