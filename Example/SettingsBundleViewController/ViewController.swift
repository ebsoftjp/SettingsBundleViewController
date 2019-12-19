//
//  ViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 12/12/2019.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
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

}

// MARK: - Custom class of SettingsViewController
class SettingsViewControllerCustom: SettingsViewController {

	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		// Display header title including lowercase letters
		(view as? UITableViewHeaderFooterView)?.textLabel?.text = cellArray?[section].headerTitle
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		super.tableView(tableView, didSelectRowAt: indexPath)
	}

	override func updateCellContent(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		switch data.specifierType {
		// Button
		case "PSButtonSpecifier":
			cell.textLabel?.text = localized(data.title)
			cell.didSelectHandler = { tableView, indexPath in
				let alert = UIAlertController(title: nil, message: data.title, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
					tableView.deselectRow(at: indexPath, animated: true)
				}))
				self.present(alert, animated: true, completion: nil)
			}
		default:
			super.updateCellContent(cell, data)
		}
	}

}
