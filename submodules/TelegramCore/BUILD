load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TelegramCore",
    module_name = "TelegramCore",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    linkopts = [
        "-Wl,-weak-lswiftCoreMIDI",
        "-Wl,-weak-lswiftDataDetection",
        "-Wl,-weak-lswiftFileProvider",
        "-Wl,-weak-lswiftUniformTypeIdentifiers",
        "-Wl,-weak-lswiftAVFoundation",
        "-Wl,-lswiftCore",
        "-Wl,-weak-lswiftCoreAudio",
        "-Wl,-weak-lswiftCoreFoundation",
        "-Wl,-weak-lswiftCoreImage",
        "-Wl,-weak-lswiftCoreLocation",
        "-Wl,-weak-lswiftCoreMedia",
        "-Wl,-weak-lswiftDarwin",
        "-Wl,-lswiftDispatch",
        "-Wl,-weak-lswiftMetal",
        "-Wl,-weak-lswiftNetwork",
        "-Wl,-lswiftObjectiveC",
        "-Wl,-weak-lswiftPhotos",
        "-Wl,-weak-lswiftQuartzCore",
        "-Wl,-weak-lswiftUIKit",
        "-Wl,-weak-lswiftos",
        "-Wl,-weak-lswiftsimd",
        "-Wl,-lswiftFoundation",
        "-Wl,-lswiftCloudKit",
        "-Wl,-weak-lswiftCoreGraphics",
    ],
    deps = [
        "//submodules/TelegramApi:TelegramApi",
        "//submodules/MtProtoKit:MtProtoKit",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Postbox:Postbox",
        "//submodules/CloudData:CloudData",
        "//submodules/EncryptionProvider:EncryptionProvider",
        "//submodules/CryptoUtils:CryptoUtils",
        "//submodules/NetworkLogging:NetworkLogging",
        "//submodules/Reachability:Reachability",
        "//submodules/ManagedFile:ManagedFile",
        "//submodules/Utils/RangeSet:RangeSet",
        "//submodules/Utils/DarwinDirStat",
        "//submodules/Emoji",
    ],
    visibility = [
        "//visibility:public",
    ],
)
