//
//  ViewController.swift
//  SettingsBundleViewController
//
//  Created by Mamoru Sugihara on 12/12/2019.
//  Copyright (c) 2019 Mamoru Sugihara. All rights reserved.
//

import UIKit
import SettingsBundleViewController

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

		let defaults = SettingsBundleViewController.defaults()
		UserDefaults.standard.register(defaults: defaults)
		print("========")
		defaults.forEach {
			print("\($0.key): \($0.value)")
		}
		print("========")
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	@IBAction func openSettings(_ sender: Any) {
		let viewController = SettingsBundleViewController()
		present(viewController, animated: true, completion: nil)
	}

}

