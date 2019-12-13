//
//  SettingsViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit

public class SettingsViewController: UIViewController {

	private var splitMaster = false
	private var bundleFileName: String!
	private var cellArray = [SettingsCellData]()
	private let reuseIdentifier = "Cell"

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public init(splitMaster: Bool, bundleFileName: String) {
		super.init(nibName: nil, bundle: nil)
		self.splitMaster = splitMaster
		self.bundleFileName = bundleFileName
	}

	override public func viewDidLoad() {
		super.viewDidLoad()

		// Title
		title = bundleFileName

		// View
		view.backgroundColor = .clear

		// Close button
		if splitMaster {
			let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
			navigationItem.leftBarButtonItem = closeButton
		}

		// Create cell data
		if let filePath = Bundle.main.path(forResource: bundleFileName + "/Root", ofType: "plist") {
			(NSDictionary(contentsOfFile: filePath)?["PreferenceSpecifiers"] as? NSArray)?.enumerated().forEach {
				if let plistData = $0.element as? Dictionary<String, Any> {
					let data = SettingsCellData(plistData: plistData)
					if data.isGroup {
						cellArray.append(data)
					} else {
						if cellArray.count == 0 {
							cellArray.append(SettingsCellData(plistData: ["Type": "PSGroupSpecifier"]))
						}
						cellArray[cellArray.count - 1].childData.append(data)
					}
				}
			}
		}

		// Create table view
		let tableView = UITableView(frame: .zero, style: .grouped)
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
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

}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {

	// Did select
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}

	// Header title
	public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return localized(cellArray[section].headerTitle)
	}

	// Footer title
	public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return localized(cellArray[section].footerTitle)
	}

}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {

	public func numberOfSections(in tableView: UITableView) -> Int {
		return cellArray.count
	}

	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cellArray[section].childData.count
	}

	// Cell
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
		let data = cellArray[indexPath.section].childData[indexPath.row]
		cell.textLabel?.text = localized(data.title)
		return cell
	}

}
