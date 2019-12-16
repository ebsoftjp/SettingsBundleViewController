//
//  SettingsViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import QuickLook

public class SettingsViewController: UIViewController {

	private var splitMaster = false
	private var bundleFileName: String!
	private var currentFileName: String!
	private var fileName: String { return currentFileName ?? "Root" }
	private var selectedIndexPath: IndexPath?
	private var cellArray: [SettingsCellData]?
	private let settingsTitle = Bundle(for: QLPreviewController.self)
		.localizedString(forKey: "Settings", value: "Settings", table: nil)

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public init(splitMaster: Bool, bundleFileName: String, fileName: String? = nil, indexPath: IndexPath? = nil) {
		super.init(nibName: nil, bundle: nil)
		self.splitMaster = splitMaster
		self.bundleFileName = bundleFileName
		self.currentFileName = fileName
		self.selectedIndexPath = indexPath
	}

	override public func viewDidLoad() {
		super.viewDidLoad()

		// Title
		title = settingsTitle

		// View
		view.backgroundColor = .clear

		// Close button
		if splitMaster {
			let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeViewController))
			navigationItem.leftBarButtonItem = closeButton
		}

		// Create cell data
		cellArray = createData()

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

	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Deselect selected cell
		view.subviews.compactMap { $0 as? UITableView }.forEach {
			if let indexPath = $0.indexPathForSelectedRow {
				$0.deselectRow(at: indexPath, animated: true)
			}
		}
	}

	// Create cell data
	func createData() -> [SettingsCellData] {
		var res = [SettingsCellData]()
		if let filePath = Bundle.main.path(forResource: bundleFileName + "/" + fileName, ofType: "plist") {
			(NSDictionary(contentsOfFile: filePath)?["PreferenceSpecifiers"] as? NSArray)?.enumerated().forEach {
				if let plistData = $0.element as? Dictionary<String, Any> {
					let data = SettingsCellData(plistData: plistData)
					if data.isParent {
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
		if !splitMaster, currentFileName == nil {
			res.enumerated().forEach { section, data in
				data.childData.enumerated().forEach { row, child in
					if selectedIndexPath == nil, child.isPush {
						selectedIndexPath = IndexPath(row: row, section: section)
					}
				}
			}
			if selectedIndexPath == nil {
				res.removeAll()
			}
		}
		if let indexPath = selectedIndexPath {
			selectedIndexPath = nil
			let data = res[indexPath.section].childData[indexPath.row]
			title = localized(data.title)
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
	func localized(_ text: String?) -> String? {
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

	// Close
	@objc func closeViewController() {
		dismiss(animated: true, completion: nil)
	}

}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {

	// Did select
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if cellArray?[indexPath.section].childData[indexPath.row].isPush ?? false {
			let viewController = SettingsViewController(splitMaster: false, bundleFileName: bundleFileName, fileName: fileName, indexPath: indexPath)
			navigationController?.pushViewController(viewController, animated: true)
		} else {
			tableView.deselectRow(at: indexPath, animated: true)
		}
	}

	// Header title
	public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return localized(cellArray?[section].headerTitle)
	}

	// Footer title
	public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return localized(cellArray?[section].footerTitle)
	}

}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {

	public func numberOfSections(in tableView: UITableView) -> Int {
		return cellArray?.count ?? 0
	}

	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cellArray?[section].childData.count ?? 0
	}

	// Create cell
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let data = cellArray?[indexPath.section].childData[indexPath.row]
		let reuseIdentifier = data?.specifierType ?? "Cell"

		var cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
		if cell == nil {
			cell = SettingsTableViewCell(reuseIdentifier: reuseIdentifier)
		}

		if let data = data {
			(cell as? SettingsTableViewCell)?.updateContext(text: localized(data.title) ?? "", data: data)
		} else {
			cell?.textLabel?.text = "Undefined specifierType"
		}

		return cell!
	}

}
