// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-game-framework",
    products: [
        .library(name: "GameFramework", targets: ["GameFramework"]),
    ],
    dependencies: [.package(name: "GLFWSwift", url: "https://github.com/MarSe32m/GLFW-Swift.git", .branch("main")),
                    .package(name: "GLMSwift", url: "https://github.com/MarSe32m/GLMSwift.git", .branch("main"))
    ],
    targets: [
        .target(name: "stb_image"),
        .target(
            name: "GameFramework",
            dependencies: ["GLFWSwift", "GLMSwift", "stb_image"],
            linkerSettings: [.linkedLibrary("Kernel32", .when(platforms: [.windows]))]
            ),
        .target(name: "Demo",
                dependencies: ["GameFramework", "GLMSwift"],
                resources: [.copy("awesomeface.png")]),
        .testTarget(
            name: "GameFrameworkTests",
            dependencies: ["GameFramework"]),
    ]
)
