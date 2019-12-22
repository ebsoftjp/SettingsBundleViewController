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

	// EventToggleSwitch
	open func updateCellEventToggleSwitch(_ cell: SettingsTableViewCell, _ data: SettingsCellData) {
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

		eventStore?.calendars(for: entityType).forEach {
			UserDefaults.standard.rx.observe(Bool.self, data.key! + $0.calendarIdentifier)
				.subscribe(onNext: { _ in
					let n = eventStore?.calendars(for: entityType).reduce(0) { acc, calendar in
						acc + (UserDefaults.standard.bool(forKey: data.key! + calendar.calendarIdentifier) ? 1 : 0)
					}
					if let n = n {
						cell.detailTextLabel?.text = "\(n)"
					} else {
						cell.detailTextLabel?.text = nil
					}
				})
				.disposed(by: cell.disposeBag)
		}
	}

}
