//
//  SettingsViewController+Event.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/21.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import EventKit
import RxSwift
import RxCocoa

extension SettingsViewController {

	// EventMultiValue
	open func updateCellEventMultiValue(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
		cell.textLabel?.text = localized(data.title)
		cell.accessoryType = .disclosureIndicator
		cell.didSelectHandler = { tableView, indexPath in
			self.showChild(tableView, indexPath)
		}

		let entityType = EKEntityType.event
		var eventStore: EKEventStore?
		if EKEventStore.authorizationStatus(for: entityType) == .authorized {
			eventStore = EKEventStore()
		}

		UserDefaults.standard.rx.observe(String.self, data.key!)
			.subscribe(onNext: { value in
				cell.detailTextLabel?.text = eventStore?.calendars(for: entityType).filter { $0.calendarIdentifier == value }.first?.title
			})
			.disposed(by: cell.disposeBag)
	}

}
