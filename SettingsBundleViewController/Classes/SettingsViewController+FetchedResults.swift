//
//  SettingsViewController+FetchedResults.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/23.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import CoreData

extension SettingsViewController: NSFetchedResultsControllerDelegate {

	public struct TableViewSetting {
		var editingStyle = UITableViewCell.EditingStyle.none
		var isEditing = false
		var canEdit = false
		var canMove = false

		mutating func set(_ data: SettingsCellData) {
			switch data.string("EditingStyle") {
			case "delete":
				editingStyle = .delete
			case "insert":
				editingStyle = .insert
			default:
				editingStyle = .none
			}
			isEditing = data.bool("IsEditing") ?? false
			canEdit = data.bool("CanEdit") ?? false
			canMove = data.bool("CanMove") ?? false
		}
	}

	open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView?.beginUpdates()
	}
	
	open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		switch type {
		case .insert:
			tableView?.insertSections(IndexSet(integer: sectionIndex), with: .fade)
		case .delete:
			tableView?.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
		default:
			return
		}
	}
	
	open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			if let indexPath = newIndexPath {
				tableView?.insertRows(at: [indexPath], with: .fade)
				scrollIndexPath = newIndexPath
			}
		case .delete:
			if let indexPath = indexPath {
				tableView?.deleteRows(at: [indexPath], with: .fade)
			}
		case .update:
			if let indexPath = indexPath,
				let cell = tableView?.cellForRow(at: indexPath) as? SettingsTableViewCell,
				let event = anObject as? NSManagedObject {
				updateCellContent(cell, event: event)
			}
		case .move:
			if let indexPath = indexPath,
				let cell = tableView?.cellForRow(at: indexPath) as? SettingsTableViewCell,
				let newIndexPath = newIndexPath,
				let event = anObject as? NSManagedObject {
				updateCellContent(cell, event: event)
				tableView?.moveRow(at: indexPath, to: newIndexPath)
			}
		@unknown default:
			fatalError()
		}
	}
	
	open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView?.endUpdates()
		if let indexPath = scrollIndexPath {
			tableView?.scrollToRow(at: indexPath, at: .none, animated: true)
			scrollIndexPath = nil
		}
	}


	// MARK: - etc

	open func createFetchedResultsController(context: NSManagedObjectContext, data: SettingsCellData) {
		if #available(iOS 10.0, *),
			let entity = data.string("Entity"),
			let sortKey = data.string("SortKey"),
			let sortAscending = data.bool("SortAscending") {

			tableViewSetting.set(data)

			let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entity)
			fetchRequest.fetchBatchSize = 50
			fetchRequest.sortDescriptors = [
				NSSortDescriptor(key: sortKey, ascending: sortAscending),
			]

			fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "Master")
			fetchedResultsController?.delegate = self
			try? fetchedResultsController?.performFetch()
		}
	}

	open func removeAllItems() {
		guard let fetchedResultsController = fetchedResultsController else {
			return
		}

		do {
			let context = fetchedResultsController.managedObjectContext
			try context.fetch(fetchedResultsController.fetchRequest).forEach {
				context.delete($0)
			}
			try context.save()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}

}
