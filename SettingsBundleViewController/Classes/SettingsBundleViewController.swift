//
//  SettingsBundleViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit

public class SettingsBundleViewController: UISplitViewController {

	// Use bundle filename
	static var currentBundleFileName: String?
	static var bundleFileName: String { return currentBundleFileName ?? "Settings.bundle" }

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// initialize with filename
	public init() {
		super.init(nibName: nil, bundle: nil)

		// Add master and detail view controller
		viewControllers = [true, false].map {
			let viewController = SettingsViewController(splitMaster: $0, bundleFileName: SettingsBundleViewController.bundleFileName)
			return UINavigationController(rootViewController: viewController)
		}

		preferredDisplayMode = .allVisible
		delegate = self
	}

	// Get default value in UserDefaults
	public static func defaults(fileName: String? = nil) -> [String: Any] {
		currentBundleFileName = fileName
		var res = [String: Any]()
		Bundle.main.urls(forResourcesWithExtension: "plist", subdirectory: bundleFileName)?.forEach {
			let plistData = NSDictionary(contentsOf: $0)
			(plistData?["PreferenceSpecifiers"] as? NSArray)?.forEach {
				if let dic = $0 as? [String: Any],
					let key = dic["Key"] as? String,
					let value = dic["DefaultValue"] {
					res[key] = value
				}
			}
		}
		return res
	}

}

// MARK: - Split view
extension SettingsBundleViewController: UISplitViewControllerDelegate {

	public func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
		return true
	}

	public func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode {
		return .allVisible
	}

}
