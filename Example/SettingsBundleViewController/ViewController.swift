//
//  ViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 12/12/2019.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import EventKit
import SettingsBundleViewController

class ViewController: UIViewController {

	var eventStore: EKEventStore?

	override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

		SettingsBundleViewController.settingsViewControllerType = SettingsViewControllerCustom.self
		let defaults = SettingsBundleViewController.defaults
		UserDefaults.standard.register(defaults: defaults)
		print("==== UserDefaults ====")
		defaults.forEach {
			print("\($0.key): \(UserDefaults.standard.value(forKey: $0.key)!) (\($0.value))")
		}
		print("========")

		createEventStore()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		openSettings(0)
	}

	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	@IBAction func openSettings(_ sender: Any) {
		let viewController = SettingsBundleViewController()
		present(viewController, animated: true, completion: nil)
	}

	@IBAction func eventAuth(_ sender: UIButton) {
		var entityType: EKEntityType!
		switch sender.titleLabel?.text {
		case "Reminder auth":
			entityType = .reminder
		default:
			entityType = .event
		}
		switch EKEventStore.authorizationStatus(for: entityType) {
		case .notDetermined:
			EKEventStore().requestAccess(to: entityType, completion: {
				(granted, error) in
				self.eventStore = nil
				self.createEventStore()
			})
		case .restricted:
			break
		case .denied:
			let alert = UIAlertController(title: "",
										  message: "Warning: Event\(entityType.rawValue) is disable",
										  preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Open settings", style: .default, handler: { alert in
				if #available(iOS 10.0, *) {
					UIApplication.shared.open(URL(string: "app-settings:")!, options: [:], completionHandler: nil)
				}
			}))
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			present(alert, animated: true, completion: nil)
		case .authorized:
			createEventStore()
		@unknown default:
			fatalError()
		}
	}

	func createEventStore() {
		if eventStore == nil,
			(EKEventStore.authorizationStatus(for: .event) == .authorized
				|| EKEventStore.authorizationStatus(for: .reminder) == .authorized) {
			eventStore = EKEventStore()
			SettingsBundleViewController.eventStore = eventStore

			let defaults = SettingsBundleViewController.defaultsForEvent
			UserDefaults.standard.register(defaults: defaults)
			print("==== UserDefaults for event ====")
			defaults.forEach {
				print("\($0.key): \(UserDefaults.standard.value(forKey: $0.key)!) (\($0.value))")
			}
			print("========")
		}
	}

}
