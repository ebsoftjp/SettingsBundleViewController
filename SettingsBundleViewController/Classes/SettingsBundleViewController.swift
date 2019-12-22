//
//  SettingsBundleViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import EventKit

open class SettingsBundleViewController: UISplitViewController {

	// Use bundle filename
	public static var bundleFileName = "Settings.bundle"
	public static var settingsViewControllerType: SettingsViewController.Type = SettingsViewController.self

	// Get default value in UserDefaults
	public static var defaults: [String: Any] {
		var res = [String: Any]()
		var eventStore: EKEventStore?
		if EKEventStore.authorizationStatus(for: .event) == .authorized
			|| EKEventStore.authorizationStatus(for: .reminder) == .authorized {
			eventStore = EKEventStore()
		}

		Bundle.main.urls(forResourcesWithExtension: "plist", subdirectory: bundleFileName)?.forEach {
			let plistData = NSDictionary(contentsOf: $0)
			(plistData?["PreferenceSpecifiers"] as? NSArray)?.forEach {
				if let dic = $0 as? [String: Any],
					let key = dic["Key"] as? String {
					switch dic["Type"] as? String {
					case "PSEventMultiValueSpecifier":
						res[key] = eventStore?.defaultCalendarForNewEvents?.calendarIdentifier
					case "PSEventToggleSwitchSpecifier":
						eventStore?.calendars(for: .event).forEach {
							res[key + $0.calendarIdentifier] = dic["DefaultValue"]
						}
					case "PSReminderMultiValueSpecifier":
						res[key] = eventStore?.defaultCalendarForNewReminders()?.calendarIdentifier
					case "PSReminderToggleSwitchSpecifier":
						eventStore?.calendars(for: .reminder).forEach {
							res[key + $0.calendarIdentifier] = dic["DefaultValue"]
						}
					default:
						res[key] = dic["DefaultValue"]
					}
				}
			}
		}
		return res
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		preferredDisplayMode = .allVisible
		delegate = self

		// Add master and detail view controller
		if viewControllers.count == 0 {
			viewControllers = [true, false].map {
				let viewController = type(of: self).settingsViewControllerType.init()
				viewController.reset(splitMaster: $0, bundleFileName: type(of: self).bundleFileName)
				return UINavigationController(rootViewController: viewController)
			}
		}
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
