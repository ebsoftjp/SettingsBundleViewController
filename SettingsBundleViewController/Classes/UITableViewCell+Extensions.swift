//
//  UITableViewCell+Extensions.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/13.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit

extension UITableViewCell {

	var tableView: UITableView? {
		var view: UIView? = self
		while view != nil {
			if let view = view as? UITableView {
				return view
			}
			view = view?.superview
		}
		return nil
	}

	convenience init(data: SettingsCellData, reuseIdentifier: String?) {
		self.init(style: .value1, reuseIdentifier: reuseIdentifier)

		if data.specifierType == "PSToggleSwitchSpecifier" {
			accessoryView = UISwitch()
		}
	}

}
