//
//  SettingsViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import QuickLook

open class SettingsViewController: UIViewController {

	open var splitMaster = false
	open var bundleFileName: String!
	open var currentFileName: String!
	open var fileName: String { return currentFileName ?? "Root" }
	open var selectedIndexPath: IndexPath?
	open var orgSelectedIndexPath: IndexPath?
	open var cellArray: [SettingsCellData]?
	open var titleText = Bundle(for: QLPreviewController.self)
		.localizedString(forKey: "Settings", value: "Settings", table: nil)
	
	// Init view controller
	open func reset(splitMaster: Bool, bundleFileName: String, fileName: String? = nil, indexPath: IndexPath? = nil) {
		self.splitMaster = splitMaster
		self.bundleFileName = bundleFileName
		reset(fileName: fileName, indexPath: indexPath)
	}

	// Reset view controller
	open func reset(fileName: String? = nil, indexPath: IndexPath? = nil) {
		currentFileName = fileName
		selectedIndexPath = indexPath
		cellArray = createData()
		view.subviews.compactMap { $0 as? UITableView }.forEach {
			$0.reloadData()
		}
	}

	open override func viewDidLoad() {
		super.viewDidLoad()

		// Title
		title = titleText

		// View
		view.backgroundColor = .clear

		// Close button
		if splitMaster {
			let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeViewController))
			navigationItem.leftBarButtonItem = closeButton
		}

		// Create table view
		let tableView = UITableView(frame: .zero, style: .grouped)
		tableView.delegate = self
		tableView.dataSource = self
		view.addSubview(tableView)

		// Add constraint to table view
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		for attr in [.leading, .trailing, .top, .bottom] as [NSLayoutConstraint.Attribute] {
			view.addConstraint(
				NSLayoutConstraint(
					item: tableView,
					attribute: attr,
					relatedBy: .equal,
					toItem: view,
					attribute: attr,
					multiplier: 1,
					constant: 0))
		}
	}

	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Deselect selected cell
		view.subviews.compactMap { $0 as? UITableView }.forEach {
			if let indexPath = $0.indexPathForSelectedRow {
				$0.deselectRow(at: indexPath, animated: true)
			} else if splitMaster,
				!(splitViewController?.isCollapsed ?? false),
				let indexPath = orgSelectedIndexPath {
				$0.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			}
		}
	}

	// Create cell data
	open func createData() -> [SettingsCellData] {
		var res = [SettingsCellData]()
		if let filePath = Bundle.main.path(forResource: bundleFileName + "/" + fileName, ofType: "plist") {
			(NSDictionary(contentsOfFile: filePath)?["PreferenceSpecifiers"] as? NSArray)?.enumerated().forEach {
				if let plistData = $0.element as? Dictionary<String, Any> {
					var data = SettingsCellData(plistData: plistData)
					if data.isGroup {
						if data.specifierType == "PSRadioGroupSpecifier" {
							// Use PSMultiValueSelectorSpecifier
							data.appendChild(data)
						}
						res.append(data)
					} else {
						if res.count == 0 {
							res.append(SettingsCellData(plistData: [
								"Type": "PSGroupSpecifier",
							]))
						}
						res[res.count - 1].childData.append(data)
					}
				}
			}
		}
		res.enumerated().forEach { section, data in
			data.childData.enumerated().forEach { row, child in
				if orgSelectedIndexPath == nil, child.isPush {
					orgSelectedIndexPath = IndexPath(row: row, section: section)
				}
			}
		}
		if !splitMaster, currentFileName == nil {
			if orgSelectedIndexPath == nil {
				res.removeAll()
			} else {
				selectedIndexPath = orgSelectedIndexPath
			}
		}
		if let indexPath = selectedIndexPath {
			selectedIndexPath = nil
			let data = res[indexPath.section].childData[indexPath.row]
			titleText = localized(data.title) ?? titleText
			if let file = data.file {
				currentFileName = file
				res = createData()
			} else {
				res.removeAll()
				res.append(SettingsCellData(plistData: [
					"Type": "PSGroupSpecifier",
				]))
				res[res.count - 1].appendChild(data)
			}
		}
		return res
	}

	// Localized text from Settings.bundle
	open func localized(_ text: String?) -> String? {
		guard let text = text else {
			return nil
		}
		return NSLocalizedString(
			text,
			tableName: bundleFileName + "/\(Locale.current.languageCode ?? "en").lproj/Root",
			bundle: Bundle.main,
			value: text,
			comment: text)
	}

	// Show ChildPane
	open func showChild(_ tableView: UITableView, _ indexPath: IndexPath) {
		if splitMaster, !(splitViewController?.isCollapsed ?? false) {
			// Master with detail view controller
			let navigationController = splitViewController?.viewControllers.last as? UINavigationController
			if indexPath == orgSelectedIndexPath {
				navigationController?.popViewController(animated: true)
			} else {
				orgSelectedIndexPath = indexPath
				navigationController?.popToRootViewController(animated: false)
				let viewController = navigationController?.topViewController as? SettingsViewController
				viewController?.reset(fileName: fileName, indexPath: indexPath)
			}
		} else {
			let viewController = type(of: self).init()
			viewController.reset(splitMaster: false, bundleFileName: bundleFileName, fileName: fileName, indexPath: indexPath)
			navigationController?.pushViewController(viewController, animated: true)
		}
	}

	// Close
	@objc open func closeViewController() {
		dismiss(animated: true, completion: nil)
	}
	
	open func createCell(_ reuseIdentifier: String) -> SettingsTableViewCell {
		switch reuseIdentifier {
		case "PSChildPaneSpecifier",
			 "PSTitleValueSpecifier",
			 "PSMultiValueSpecifier":
			return SettingsTableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
		default:
			return SettingsTableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
		}
	}

	open func updateCellContent(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		switch data.specifierType {
		case "PSChildPaneSpecifier":
			updateCellChildPane(cell, data)
		case "PSToggleSwitchSpecifier":
			updateCellToggleSwitch(cell, data)
		case "PSSliderSpecifier":
			updateCellSlider(cell, data)
		case "PSTitleValueSpecifier":
			updateCellTitleValue(cell, data)
		case "PSTextFieldSpecifier":
			updateCellTextField(cell, data)
		case "PSMultiValueSpecifier":
			updateCellMultiValue(cell, data)
		case "PSMultiValueSelectorSpecifier":
			updateCellMultiValueSelector(cell, data)
		default:
			break
		}
	}

}
