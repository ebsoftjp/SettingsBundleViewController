//
//  SettingsViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit

public class SettingsViewController: UIViewController {

	private var fileName: String!

	override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	convenience public init(file: String) {
		self.init()
		fileName = file
	}

	override public func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .white
		title = "test: " + fileName

		let label = UILabel()
		label.text = title
		label.textAlignment = .center
		label.textColor = .black
		view.addSubview(label)
		addConstraintsView(label)
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
