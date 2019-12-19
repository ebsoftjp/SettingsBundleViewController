//
//  SettingsTableViewCell.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 2019/12/13.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

open class SettingsTableViewCell: UITableViewCell {

	open var didSelectHandler: ((UITableView, IndexPath) -> Void)?
	open var disposeBag = DisposeBag() 

	open override func prepareForReuse() {
		super.prepareForReuse()

		didSelectHandler = nil
		// Unsubscribe when reusing
		disposeBag = DisposeBag()
	}

}
