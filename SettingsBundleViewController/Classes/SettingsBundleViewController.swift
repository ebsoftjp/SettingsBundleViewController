//
//  SettingsBundleViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit

public class SettingsBundleViewController: UISplitViewController {

	override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	convenience public init(file: String) {
		self.init()
		viewControllers = (0...1).map {
			let viewController = SettingsViewController(file: "\($0)")
			return UINavigationController(rootViewController: viewController)
		}

		preferredDisplayMode = .allVisible
		delegate = self
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
