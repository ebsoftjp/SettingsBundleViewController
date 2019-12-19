//
//  SettingsViewController+UITableViewDelegate.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit

extension SettingsViewController: UITableViewDelegate {

	// Will select
	open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		return (tableView.cellForRow(at: indexPath) as? SettingsTableViewCell)?.didSelectHandler != nil
	}

	// Did select
	open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		(tableView.cellForRow(at: indexPath) as? SettingsTableViewCell)?.didSelectHandler?(tableView, indexPath)
	}

	// Header title
	open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return localized(cellArray?[section].headerTitle)
	}

	// Footer title
	open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return localized(cellArray?[section].footerTitle)
	}

}
