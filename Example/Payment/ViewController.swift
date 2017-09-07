//
//  ViewController.swift
//  Payment
//
//  Created by lzc1104 on 09/07/2017.
//  Copyright (c) 2017 lzc1104. All rights reserved.
//

import UIKit
import Payment

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// 支付宝暂时不用注册账号 - 现在支付宝使用的是旧版本SDK -
        PaymentManagers.registerAccount(PaymentManagers.Account.alipay(appID: "???"))
        /// 微信必须注册账号
        PaymentManagers.registerAccount(PaymentManagers.Account.wechat(appID: "", appKey: ""))
    }
    
    @IBAction func wechatPay(_ sender: Any) {
        
        let req = PaymentManagers.WechatPayRequest(
            partnerId: "",
            prepayId: "",
            nonceStr: "",
            timeStamp: 0,
            package: "",
            sign: ""
        )
        let order = PaymentManagers.Order.weChat(req: req)
        
        PaymentManagers.deliver(order) { (result) in
            switch result {
            case .success:
                debugPrint("FUCK YOU")
                break
            case .error(let error):
                switch error {
                case .cancel:
                    debugPrint("FUCK YOU CANCEL???")
                default:
                    debugPrint("FUCK ME")
                }
                break
            }
        }
        
    }
    
    
    @IBAction func alipay(_ sender: Any) {
        //RESERVER
        //此处的模板为 观赛日支付模板
        let req = PaymentManagers.AlipayRequest(urlString : "",scheme: "")
        let order = PaymentManagers.Order.alipay(req: req)
        
        PaymentManagers.deliver(order, completionHandler: { result in
            switch result {
            case .success:
                debugPrint("FUCK YOU")
                break
            case .error(let error):
                switch error {
                case .cancel:
                    debugPrint("FUCK YOU CANCEL???")
                default:
                    debugPrint("FUCK ME")
                }
                break
            }
        })
        
    }
    

}

