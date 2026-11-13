load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MyChannelsUI",
    module_name = "MyChannelsUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/AsyncDisplayKit",
        "//submodules/Display",
        "//submodules/TelegramCore",
        "//submodules/TelegramPresentationData",
        "//submodules/AccountContext",
        "//submodules/AppBundle",
        "//submodules/AvatarNode",
        "//submodules/ItemListUI",
        "//submodules/ItemListPeerItem",
        "//submodules/ItemListPeerActionItem",
    ],
    visibility = [
        "//visibility:public",
    ],
)
