//
//  ViewController.swift
//  WZToast
//
//  Created by zhuangyz on 11/07/2024.
//  Copyright (c) 2024 zhuangyz. All rights reserved.
//

import UIKit
import WZToastV2

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white;
        
        let btn = UIButton(type: .custom)
        btn.setTitle("click", for: .normal)
        btn.setTitleColor(UIColor.systemBlue, for: .normal)
        btn.frame = CGRect(x: 100, y: 200, width: 50, height: 44);
        btn.addTarget(self, action: #selector(action), for: .touchUpInside)
        view.addSubview(btn)
    }

    @objc func action() {
        print("\(Date())")
        WZToast.shared.show(message: "short message", style: .warn, location: .bottom, duration: .average)
        WZToast.shared.show(message: "长文字长文字长文字长文字长文字长文字长文字长文字长文字长文字长文字长文字长文字长文字", style: .success, location: .top, duration: .custom(5))
        WZToast.shared.show(message: "asdasd", style: WZToast.Style(backgroundColor: UIColor.white, textColor: UIColor.black, font: UIFont.systemFont(ofSize: 12)))
        print("\(Date())")
    }

}

