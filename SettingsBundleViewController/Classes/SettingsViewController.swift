//
//  SettingsViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import EventKit
import StoreKit
import QuickLook
import RxSwift
import RxCocoa

open class SettingsViewController: UIViewController {

	open var splitMaster = false
	open var bundleFileName: String!
	open var currentFileName: String!
	open var fileName: String { return currentFileName ?? "Root" }
	open var selectedIndexPath: IndexPath?
	open var orgSelectedIndexPath: IndexPath?

	open var tableView: UITableView?
	open var cellArray: [SettingsCellData]?
	open var titleText = Bundle(for: QLPreviewController.self)
		.localizedString(forKey: "Settings", value: "Settings", table: nil)

	open var products = BehaviorRelay<[SKProduct]?>(value: nil)

	open var fadeDuration = 0.2
	open var indicatorView: UIActivityIndicatorView?

	open var disposeBag = DisposeBag()

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
		tableView?.reloadData()
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
		self.tableView = tableView

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

		// Request products
		startRequestProducts()
	}

	open override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Deselect selected cell
		if let tableView = tableView {
			if let indexPath = tableView.indexPathForSelectedRow {
				tableView.deselectRow(at: indexPath, animated: true)
			} else if splitMaster,
				!(splitViewController?.isCollapsed ?? false),
				let indexPath = orgSelectedIndexPath {
				tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
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
							data.childData += appendChild(data)
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
				//res.removeAll()
				res = createData(withChildData: data)
			}
		}
		return res
	}

	// Add child for MultiValue and RadioGroup
	open func appendChild(_ data: SettingsCellData) -> [SettingsCellData] {
		var res = [SettingsCellData]()
		if let key = data.key,
			!key.isEmpty,
			let titles = data.plistData["Titles"] as? [String],
			let values = data.plistData["Values"] as? [Any] {
			for i in 0..<titles.count {
				res.append(SettingsCellData(plistData: [
					"Type": "PSMultiValueSelectorSpecifier",
					"Title": titles[i],
					"Value": values[i],
					"Key": key,
				]))
			}
		}
		return res
	}

	// Add child for MultiValue and RadioGroup
	open func createData(withChildData data: SettingsCellData) -> [SettingsCellData] {
		var res = [SettingsCellData]()

		guard let key = data.key, !key.isEmpty else {
			return res
		}

		switch data.specifierType {
		case "PSEventMultiValueSpecifier":
			return createEventMultiValue(data, entityType: .event)

		case "PSEventToggleSwitchSpecifier":
			return createEventToggleSwitch(data, entityType: .event)

		case "PSReminderMultiValueSpecifier":
			return createEventMultiValue(data, entityType: .reminder)

		case "PSReminderToggleSwitchSpecifier":
			return createEventToggleSwitch(data, entityType: .reminder)

		default:
			res = [
				SettingsCellData(plistData: [
					"Type": "PSGroupSpecifier",
				])
			]
			res[res.count - 1].childData = appendChild(data)
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

	// Localized title with color bar
	open func localizedTitle(_ data: SettingsCellData) -> NSAttributedString? {
		let text = NSMutableAttributedString()
		if let color = data.plistData["Color"] as? UIColor {
			text.append(NSAttributedString(string: "  ", attributes: [
				.backgroundColor: color,
			]))
			text.append(NSAttributedString(string: "  ", attributes: [:]))
		}
		if let title = localized(data.title) {
			text.append(NSAttributedString(string: title, attributes: [:]))
		}
		return text.length > 0 ? text : nil
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

	// Start indicator
	open func startIndicator() {
		guard indicatorView == nil else {
			return
		}

		indicatorView = UIActivityIndicatorView(style: .white)

		DispatchQueue.main.async {
			guard let indicatorView = self.indicatorView else {
				return
			}

			if #available(iOS 13.0, *) {
				indicatorView.style = .medium
				indicatorView.color = .white
			}
			self.view.addSubview(indicatorView)
			indicatorView.backgroundColor = .init(white: 0, alpha: 0.4)
			indicatorView.startAnimating()

			// Constraints
			indicatorView.translatesAutoresizingMaskIntoConstraints = false
			indicatorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			for attr in [.leading, .trailing, .top, .bottom] as [NSLayoutConstraint.Attribute] {
				indicatorView.superview!.addConstraint(
					NSLayoutConstraint(
						item: indicatorView,
						attribute: attr,
						relatedBy: .equal,
						toItem: indicatorView.superview,
						attribute: attr,
						multiplier: 1,
						constant: 0))
			}

			// Fade-in
			indicatorView.layer.removeAllAnimations()
			indicatorView.alpha = 0
			UIView.animate(withDuration: self.fadeDuration, delay: 0, options: .curveEaseOut, animations: {
				indicatorView.alpha = 1
			})
		}
	}

	// Stop indicator
	open func stopIndicator() {
		guard let indicatorView = indicatorView else {
			return
		}

		self.indicatorView = nil

		// Fade-out
		DispatchQueue.main.async {
			indicatorView.layer.removeAllAnimations()
			UIView.animate(withDuration: self.fadeDuration, delay: 0, options: .curveEaseOut, animations: {
				indicatorView.alpha = 0
			}, completion: { flag in
				indicatorView.removeFromSuperview()
			})
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
			 "PSMultiValueSpecifier",
			 "PSEventMultiValueSpecifier",
			 "PSEventToggleSwitchSpecifier",
			 "PSReminderMultiValueSpecifier",
			 "PSReminderToggleSwitchSpecifier",
			 "PSProductButtonSpecifier":
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

		// Custom
		case "PSButtonSpecifier":
			cell.textLabel?.text = localized(data.title)
		case "PSEventMultiValueSpecifier":
			updateCellEventMultiValue(cell, data, entityType: .event)
		case "PSEventToggleSwitchSpecifier":
			updateCellEventToggleSwitch(cell, data, entityType: .event)
		case "PSReminderMultiValueSpecifier":
			updateCellEventMultiValue(cell, data, entityType: .reminder)
		case "PSReminderToggleSwitchSpecifier":
			updateCellEventToggleSwitch(cell, data, entityType: .reminder)
		case "PSProductButtonSpecifier":
			updateCellProductButton(cell, data)

		default:
			break
		}
	}

}
