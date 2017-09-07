//
//  PaymentManagers.swift
//
//
//  Created by lzc1104 on 2017/9/6.
//
//

import Foundation

open class PaymentManagers {
    
    public static let shared: PaymentManagers = PaymentManagers()
    public typealias PayCompletionHandler = (PaymentResult) -> Void
    private var paymentHandler: PayCompletionHandler?
    private var customAlipayOrderScheme: String = ""
    private var accountSet = Set<Account>()
    private var alipayManager: Alipaymanger = Alipaymanger.shared()!
    
    /// 支付账号
    ///
    /// - wechat: 微信
    /// - alipay: 支付宝
    public enum Account: Hashable {
        case wechat(appID: String , appKey: String)
        case alipay(appID: String)
        
        public var hashValue: Int {
            switch self {
            case .wechat(let appID, _):
                return appID.hashValue
            case .alipay(let appID):
                return appID.hashValue
            }
        }
        
        public static func ==(lhs: Account, rhs: Account) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        public var isAppInstalled: Bool {
            switch self {
            case .wechat(_, _):
                return PaymentManagers.canOpenURL(urlString: "weixin://")
            case .alipay:
                return PaymentManagers.canOpenURL(urlString: "alipay://")
            }
        }
    }
    /// 订单实体
    ///
    /// - alipay: 支付宝
    /// - weChat: 微信
    public enum Order {
        case alipay(req: AlipayRequest)
        case weChat(req: WechatPayRequest)
        
        public var canBeDelivered: Bool {
            var scheme = ""
            switch self {
            case .alipay:
                scheme = "alipay://"
            case .weChat:
                scheme = "weixin://"
            }
            guard !scheme.isEmpty else { return false }
            guard let url = URL(string: scheme) else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
        
    }
    
    /// 支付错误类型
    ///
    /// - cancel: 用户中途取消
    /// - timeout: 超时
    /// - invalidParameter: 参数错误
    /// - unReachable: 打不开对应的app
    /// - unknowned: 未知错误
    /// - processing: 支付宝 - 正在处理中，支付结果未知（有可能已经支付成功），请查询商户订单列表中订单的支付状态
    /// - connectionError: 网络连接出错
    /// - failure: 订单支付失败
    public enum PaymentError: Swift.Error {
        case cancel
        case timeout
        case invalidParameter
        case unReachable
        case unknowned
        case processing
        case connectionError
        case failure
        
    }
    
    /// 支付结果
    ///
    /// - success: 成功
    /// - error: 失败
    public enum PaymentResult {
        case success
        case error(PaymentError)
    }
    
    /// 支付宝支付实体
    public struct AlipayRequest {
        
        /// api返回的签名字符串
        var urlString: String
        
        /// xproj 中为alipay 注册的 URLtype , 需保持一致，不然跳不回来
        var scheme: String
        
        func asPaymentUrlString() -> String {
            //TODO??? - newVersion is not avalieable
            
//            let json = "{\"fromAppUrlScheme\":\"\(self.scheme)\",\"requestType\":\"SafePay\",\"dataString\":\"\(self.urlString)\"}"
//            let jsonUrlEncoded = json.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
//            let entireUrl = "alipay://alipayclient/?" + jsonUrlEncoded
        
            return urlString
        }
        
        public init(urlString: String , scheme: String) {
            self.urlString = urlString
            self.scheme = scheme
        }
    }
    
    /// 发起微信支付的实体
    public struct WechatPayRequest {
        /// 商家向财付通申请的商家id
        public var partnerId: String
        /// 预支付订单
        public var prepayId: String
        /// 随机串，防重发
        public var nonceStr: String
        /// 时间戳，防重发
        public var timeStamp: UInt32
        /// 商家根据财付通文档填写的数据和签名
        public var package: String
        /// 商家根据微信开放平台文档对数据做的签名
        public var sign: String
        
        var appid: String {
            for account in PaymentManagers.shared.accountSet {
                if case .wechat(let appID,_) = account {
                    return appID
                }
            }
            return ""
        }
        
        func asPaymentUrlString() -> String {
            //TODO???
            let string = "weixin://app/\(self.appid)/pay/?nonceStr=\(self.nonceStr)&package=Sign%3DWXPay&partnerId=\(self.partnerId)&prepayId=\(self.prepayId)&timeStamp=\(self.timeStamp)&sign=\(self.sign)&signType=MD5"
            return string
        }
        
        public init(partnerId: String, prepayId: String, nonceStr: String ,timeStamp: UInt32, package: String, sign: String) {
            self.partnerId = partnerId
            self.prepayId = prepayId
            self.nonceStr = nonceStr
            self.timeStamp = timeStamp
            self.package = package
            self.sign = sign
        }
        
    }
    
    
    
    
    /// 注册支付账号
    ///
    /// - Parameter account: account
    public class func registerAccount(_ account: PaymentManagers.Account) {
        guard account.isAppInstalled else {
            return
        }
        
        for oldAccount in self.shared.accountSet {
            
            switch oldAccount {
                
            case .wechat(_, _):
                if case .wechat(_ , _) = account {
                    self.shared.accountSet.remove(oldAccount)
                }
            
            case .alipay:
                if case .alipay = account {
                    self.shared.accountSet.remove(oldAccount)
                }
            }
        }
        
        self.shared.accountSet.insert(account)
        
    }
    
    /// 处理回调 - 需要放在Appdelegate 对应方法内 ，只会拦截支付相关的url
    ///
    /// - Parameter url: url
    /// - Returns: 处理结果
    public class func handleOpenURL(_ url: URL) -> Bool {
        guard let urlScheme = url.scheme else { return false }
        /// 微信支付
        if urlScheme.hasPrefix("wx") {
            let urlString = url.absoluteString
            if urlString.contains("://pay/") {
                /// ???
                let queryDictionary = url.payment_queryDictionary
                guard let ret = queryDictionary["ret"] as? String else {
                    let errorResult = PaymentResult.error(PaymentManagers.PaymentError.unknowned)
                    self.shared.paymentHandler?(errorResult)
                    return false
                }
                let resultCode = (ret as NSString).integerValue
                /// https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=8_5
                switch resultCode {
                case 0:
                    let successResult = PaymentResult.success
                    self.shared.paymentHandler?(successResult)
                case -1:
                    let errorResult = PaymentResult.error(PaymentManagers.PaymentError.invalidParameter)
                    self.shared.paymentHandler?(errorResult)
                case -2:
                    let errorResult = PaymentResult.error(PaymentManagers.PaymentError.cancel)
                    self.shared.paymentHandler?(errorResult)
                default:
                    let errorResult = PaymentResult.error(PaymentManagers.PaymentError.unknowned)
                    self.shared.paymentHandler?(errorResult)
                }
                return true
            }
        }
        
        /// 支付宝支付
        if urlScheme == self.shared.customAlipayOrderScheme {
            let urlString = url.absoluteString
            if urlString.contains("//safepay/?") {
                guard
                    let query = url.query,
                    let response = query.PaymentManagers_urlDecodedString?.data(using: .utf8),
                    let json = response.PaymentManagers_json,
                    let memo = json["memo"] as? [String: Any],
                    let status = memo["ResultStatus"] as? String else {
                        return false
                }
                let resultCode = (status as NSString).integerValue
                switch resultCode {
                /// https://doc.open.alipay.com/docs/doc.htm?spm=a219a.7629140.0.0.3f7xBl&treeId=59&articleId=103671&docType=1
                case 9000:
                    let successResult = PaymentResult.success
                    self.shared.paymentHandler?(successResult)
                case 8000:
                    let errorResult = PaymentResult.error(PaymentManagers.PaymentError.processing)
                    self.shared.paymentHandler?(errorResult)
                case 4000:
                    let errorResult = PaymentResult.error(PaymentManagers.PaymentError.failure)
                    self.shared.paymentHandler?(errorResult)
                case 6001:
                    let errorResult = PaymentResult.error(PaymentManagers.PaymentError.cancel)
                    self.shared.paymentHandler?(errorResult)
                case 6002:
                    let errorResult = PaymentResult.error(PaymentManagers.PaymentError.connectionError)
                    self.shared.paymentHandler?(errorResult)
                case 6004:
                    let errorResult = PaymentResult.error(PaymentManagers.PaymentError.unknowned)
                    self.shared.paymentHandler?(errorResult)
                default:
                    let errorResult = PaymentResult.error(PaymentManagers.PaymentError.unknowned)
                    self.shared.paymentHandler?(errorResult)
                }
                return true
            }
            
        }
        
        return false
    }
    
    
    /// 发起订单支付
    ///
    /// - Parameters:
    ///   - order: 订单实体
    ///   - completionHandler: 回调结果
    public class func deliver(_ order: Order, completionHandler: @escaping PayCompletionHandler) {
        
        if !order.canBeDelivered {
            let result = PaymentResult.error(PaymentManagers.PaymentError.unReachable)
            completionHandler(result)
            return
        }
        self.shared.paymentHandler = completionHandler
        switch order {
        case .weChat(let request):
            self.openURL(urlString: request.asPaymentUrlString(), completionHandler: { flag in
                if flag { return }
                let result = PaymentResult.error(PaymentManagers.PaymentError.unReachable)
                completionHandler(result)
            })
        case .alipay(let requestBody):
            ///custom scheme
            self.shared.customAlipayOrderScheme = requestBody.scheme
            self.shared.alipayManager.deliver(requestBody.urlString, scheme: requestBody.scheme, callback: nil)
        }
        
    }
    
    
    class func openURL(urlString: String, options: [String: Any] = [:], completionHandler completion: ((Bool) -> Swift.Void)? = nil) {
        
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            completion?(false)
            return
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: options, completionHandler: { (flag) in
                completion?(flag)
            })
        } else {
            completion?(UIApplication.shared.openURL(url))
        }
    }
    
   
    
    
    fileprivate class func canOpenURL(urlString: String) -> Bool {
        
        guard let url = URL(string: urlString) else {
            return false
        }
        
        return UIApplication.shared.canOpenURL(url)
    }
    
    
}

extension URL {
    
    var payment_queryDictionary: [String: Any] {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        guard let items = components?.queryItems else {
            return [:]
        }
        var infos = [String: Any]()
        items.forEach {
            if let value = $0.value {
                infos[$0.name] = value
            }
        }
        return infos
    }
}

extension String {
    var PaymentManagers_urlDecodedString: String? {
        return replacingOccurrences(of: "+", with: " ").removingPercentEncoding
    }
    
   
}

extension Data {
    
    var PaymentManagers_json: [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: .allowFragments) as? [String: Any]
        } catch {
            return nil
        }
    }
}

