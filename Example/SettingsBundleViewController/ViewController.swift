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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

		SettingsBundleViewController.settingsViewControllerType = SettingsViewControllerCustom.self
		let defaults = SettingsBundleViewController.defaults
		UserDefaults.standard.register(defaults: defaults)
		print("========")
		defaults.forEach {
			print("\($0.key): \(UserDefaults.standard.value(forKey: $0.key)!) (\($0.value))")
		}
		print("========")
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
			break
		@unknown default:
			fatalError()
		}
	}

}
