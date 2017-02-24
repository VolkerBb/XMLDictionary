import PackageDescription

let package = Package(
    name: "XMLDictionary",
    targets: [
        Target(name: "XMLDictionary", dependencies: [])
    ],
    dependencies: [],
    exclude: ["Tests", "XMLDictionary"]
)
