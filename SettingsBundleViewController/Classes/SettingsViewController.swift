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
	private var fileName: String!
	private var cellArray = [String]()
	private let reuseIdentifier = "Cell"

	override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	convenience public init(splitMaster: Bool, fileName: String) {
		self.init()
		self.splitMaster = splitMaster
		self.fileName = fileName
	}

	override public func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .clear
		title = fileName

		// Close button
		if splitMaster {
			let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
			navigationItem.leftBarButtonItem = closeButton
		}

		// Create cell data
		if let filePath = Bundle.main.path(forResource: fileName, ofType: "plist") {
			(NSDictionary(contentsOfFile: filePath)?["PreferenceSpecifiers"] as? NSArray)?.enumerated().forEach {
				if let dic = $0.element as? Dictionary<String, Any>,
					let type = dic["Type"] as? String {
					let title = dic["Title"] as? String ?? "--"
					cellArray.append(type + ": " + title)
				}
			}
		}

		// Create table view
		let tableView = UITableView(frame: .zero, style: .grouped)
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
		tableView.delegate = self
		tableView.dataSource = self
		view.addSubview(tableView)
		addConstraintsView(tableView)
	}

	func addConstraintsView(_ view: UIView) {
		view.translatesAutoresizingMaskIntoConstraints = false
		view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		for attr in [.leading, .trailing, .top, .bottom] as [NSLayoutConstraint.Attribute] {
			view.superview?.addConstraint(
				NSLayoutConstraint(
					item: view,
					attribute: attr,
					relatedBy: .equal,
					toItem: view.superview,
					attribute: attr,
					multiplier: 1,
					constant: 0))
		}
	}

}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {

	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}

}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {

	public func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cellArray.count
	}

	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
		cell.textLabel?.text = cellArray[indexPath.row]
		return cell
	}

}
