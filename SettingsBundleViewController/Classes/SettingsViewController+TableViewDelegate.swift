//
//  SettingsViewController+TableViewDelegate.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/12.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import CoreData

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
		if let _ = fetchedResultsController {
			return nil
		}
		return localized(cellArray?[section].headerText)
	}

	// Footer title
	open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if let _ = fetchedResultsController {
			return nil
		}
		return localized(cellArray?[section].footerText)
	}

	open func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		guard let fetchedResultsController = fetchedResultsController else {
			return
		}

		if sourceIndexPath == destinationIndexPath {
			return
		}

		var dataArray = [NSManagedObject]()
		let add = sourceIndexPath < destinationIndexPath ? 1 : -1
		for i in stride(from: sourceIndexPath.row, through: destinationIndexPath.row, by: add) {
			dataArray.append(fetchedResultsController.object(at: IndexPath(row: i, section: sourceIndexPath.section)))
		}

		if let key = fetchedResultsController.fetchRequest.sortDescriptors?.first?.key {
			for i in 1..<dataArray.count {
				let value = dataArray[0].value(forKey: key)
				dataArray[0].setValue(dataArray[i].value(forKey: key), forKey: key)
				dataArray[i].setValue(value, forKey: key)
			}
		}

		do {
			try fetchedResultsController.managedObjectContext.save()
		} catch {
			// Replace this implementation with code to handle the error appropriately.
			// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}

	open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete, let fetchedResultsController = fetchedResultsController {
			let context = fetchedResultsController.managedObjectContext
			context.delete(fetchedResultsController.object(at: indexPath))

			do {
				try context.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}

	open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return tableViewSetting.canEdit
	}

	open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return tableViewSetting.canMove
	}

	open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return tableViewSetting.editingStyle
	}

	open func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}

}
