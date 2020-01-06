//
//  SettingsViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import EventKit
import CoreData
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

	open var tableViewSetting = TableViewSetting()
	open var scrollIndexPath: IndexPath?
	open var fetchedResultsController: NSFetchedResultsController<NSManagedObject>? = nil

	open var bottomConstraint: NSLayoutConstraint?

	open var disposeBag = DisposeBag()

	// Checks if the specified file exists
	open func isExistFile(_ fileName: String) -> Bool {
		return Bundle.main.path(forResource: bundleFileName + "/" + fileName, ofType: "plist") != nil
	}

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
		tableView.isEditing = tableViewSetting.isEditing
		view.addSubview(tableView)
		self.tableView = tableView

		// Add constraint to table view
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		for attr in [.leading, .trailing, .top, .bottom] as [NSLayoutConstraint.Attribute] {
			let constraint = NSLayoutConstraint(
					item: tableView,
					attribute: attr,
					relatedBy: .equal,
					toItem: view,
					attribute: attr,
					multiplier: 1,
					constant: 0)
			view.addConstraint(constraint)
			if attr == .bottom {
				bottomConstraint = constraint
			}
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

		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector:#selector(willShowKeyboard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		notificationCenter.addObserver(self, selector:#selector(didShowKeyboard(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		notificationCenter.addObserver(self, selector:#selector(willHideKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	open override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		let notificationCenter = NotificationCenter.default
		notificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		notificationCenter.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
		notificationCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	// Will show keyboard
	@objc open func willShowKeyboard(_ notification: Notification) {
		if let userInfo = notification.userInfo as? [String: Any],
			let keyboardInfo = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
			bottomConstraint?.constant = -keyboardInfo.cgRectValue.size.height
			afterKeyboardAnimation(notification)
		}
	}

	// Did show keyboard
	@objc open func didShowKeyboard(_ notification: Notification) {
		// Find an enabled keyboard and scroll to it
		if let tableView = tableView {
			var focusIndexPath: IndexPath?
			tableView.visibleCells.forEach { cell in
				// UITextView on contentView
				cell.contentView.subviews.forEach {
					if let textView = $0 as? UITextView,
						textView.isFirstResponder,
						let indexPath = tableView.indexPath(for: cell) {
						focusIndexPath = indexPath
					}
				}
				// UITextField on accessoryView
				if let textField = cell.accessoryView as? UITextField,
					textField.isFirstResponder,
					let indexPath = tableView.indexPath(for: cell) {
					focusIndexPath = indexPath
				}
			}
			// Scroll
			if let indexPath = focusIndexPath {
				tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
			}
		}
	}

	// Will hide keyboard
	@objc open func willHideKeyboard(_ notification: Notification) {
		bottomConstraint?.constant = 0
		afterKeyboardAnimation(notification)
	}

	open func afterKeyboardAnimation(_ notification: Notification) {
		if let userInfo = notification.userInfo as? [String: Any],
			let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
			UIView.animate(withDuration: duration, animations: { () -> Void in
				self.view.layoutIfNeeded()
			})
		}
	}

	// Create cell data
	open func createData() -> [SettingsCellData] {
		var res = [SettingsCellData]()
		if let filePath = Bundle.main.path(forResource: bundleFileName + "/" + fileName, ofType: "plist") {
			(NSDictionary(contentsOfFile: filePath)?["PreferenceSpecifiers"] as? NSArray)?.enumerated().forEach {
				if let plistData = $0.element as? Dictionary<String, Any> {
					let data = SettingsCellData(plistData: plistData)
					if !isAddCellData(data) {
						// No add data
					} else if data.isGroup {
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
				res = createData(withChildData: data)
			}
		}
		return res
	}

	// Check add cell data
	open func isAddCellData(_ data: SettingsCellData) -> Bool {
		return true
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

		switch data.specifierType {
		case "PSEventMultiValueSpecifier":
			return createEventMultiValue(data, entityType: .event)

		case "PSEventToggleSwitchSpecifier":
			return createEventToggleSwitch(data, entityType: .event)

		case "PSReminderMultiValueSpecifier":
			return createEventMultiValue(data, entityType: .reminder)

		case "PSReminderToggleSwitchSpecifier":
			return createEventToggleSwitch(data, entityType: .reminder)

		case "PSCoreDataSpecifier":
			createCoreData(withChildData: data)

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

	// Add fetchedResultsController for custom
	open func createCoreData(withChildData data: SettingsCellData) {
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

		if #available(iOS 13.0, *) {
			indicatorView = UIActivityIndicatorView(style: .medium)
			indicatorView?.color = .white
		} else {
			indicatorView = UIActivityIndicatorView(style: .white)
		}

		DispatchQueue.main.async {
			guard let indicatorView = self.indicatorView else {
				return
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

	open func updateCellContent(_ cell: SettingsTableViewCell, data: SettingsCellData) {
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
		case "PSTextViewSpecifier":
			updateCellTextView(cell, data)
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
		case "PSCoreDataSpecifier":
			updateCellChildPane(cell, data)

		default:
			break
		}
	}

	open func updateCellContent(_ cell: SettingsTableViewCell, event: NSManagedObject) {
		guard let fetchedResultsController = fetchedResultsController else {
			return
		}

		if let key = fetchedResultsController.fetchRequest.sortDescriptors?.first?.key {
			cell.textLabel?.text = String(describing: event.value(forKey: key))
		}
	}

}
