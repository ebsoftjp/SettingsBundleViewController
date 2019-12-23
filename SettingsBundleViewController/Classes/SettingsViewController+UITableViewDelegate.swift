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
		if let _ = fetchedResultsController {
			return false
		}
		return (tableView.cellForRow(at: indexPath) as? SettingsTableViewCell)?.didSelectHandler != nil
	}

	// Did select
	open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let _ = fetchedResultsController {
			return
		}
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
		if let _ = fetchedResultsController {
			return
		}

		if sourceIndexPath == destinationIndexPath {
			return
		}

//		var dataArray = [T]()
//		let add = sourceIndexPath < destinationIndexPath ? 1 : -1
//		for i in stride(from: sourceIndexPath.row, through: destinationIndexPath.row, by: add) {
//			dataArray.append(fetchedResultsController.object(at: IndexPath(row: i, section: sourceIndexPath.section)))
//		}
//
//		for i in 1..<dataArray.count {
////			print("\(i)/\(dataArray.count)")
//			dataArray[0].swap(dataArray[i])
//		}

		do {
			try fetchedResultsController?.managedObjectContext.save()
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
		return true
	}

	open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return editingStyle
	}

	open func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}

}
