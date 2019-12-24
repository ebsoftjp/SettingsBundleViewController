//
//  SettingsViewController+UITableViewDataSource.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit

extension SettingsViewController: UITableViewDataSource {

	open func numberOfSections(in tableView: UITableView) -> Int {
		if let fetchedResultsController = fetchedResultsController {
			return fetchedResultsController.sections?.count ?? 0
		}
		return cellArray?.count ?? 0
	}

	open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let fetchedResultsController = fetchedResultsController {
			let sectionInfo = fetchedResultsController.sections![section]
			return sectionInfo.numberOfObjects
		}
		return cellArray?[section].childData.count ?? 0
	}

	// Create cell
	open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var data: SettingsCellData?
		if let cellArray = cellArray, cellArray.count > 0 {
			data = cellArray[indexPath.section].childData[indexPath.row]
		}
		let reuseIdentifier = data?.specifierType ?? "Cell"

		let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
			?? createCell(reuseIdentifier)

		cell.textLabel?.numberOfLines = 16
		if let cell = cell as? SettingsTableViewCell {
			if let data = data {
				updateCellContent(cell, data: data)
			} else if let event = fetchedResultsController?.object(at: indexPath) {
				updateCellContent(cell, event: event)
			} else {
				cell.textLabel?.text = "Undefined specifierType"
			}
		} else {
			cell.textLabel?.text = "Undefined specifierType"
		}

		return cell
	}

}
