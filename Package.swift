// swift-tools-version:5.9

import PackageDescription

let package = Package(
	name: "SettingsBundleViewController",
	platforms: [
		.iOS(.v12),
		.tvOS(.v12),
	],
	products: [
		.library(
			name: "SettingsBundleViewController",
			targets: ["SettingsBundleViewController"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
	],
	targets: [
		.target(
			name: "SettingsBundleViewController",
			dependencies: [
				.product(name: "RxSwift", package: "RxSwift"),
				.product(name: "RxCocoa", package: "RxSwift"),
			],
			path: "SettingsBundleViewController/Classes",
			exclude: [".gitkeep"]
		),
	]
)
