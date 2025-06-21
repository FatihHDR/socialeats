// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "SocialEats",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SocialEats",
            targets: ["SocialEats"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            from: "10.0.0"
        ),
        .package(
            url: "https://github.com/googlemaps/ios-maps-sdk",
            from: "8.0.0"
        )
    ],
    targets: [
        .target(
            name: "SocialEats",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "GoogleMaps", package: "ios-maps-sdk"),
                .product(name: "GooglePlaces", package: "ios-maps-sdk")
            ]
        ),
        .testTarget(
            name: "SocialEatsTests",
            dependencies: ["SocialEats"]
        ),
    ]
)
