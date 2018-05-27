//
//  network.swift
//  WhyFiMac
//
//  Created by Tom on 2018/5/27.
//  Copyright © 2018年 Tom. All rights reserved.
//

import Foundation
import Cocoa
import KeychainAccess
import SwiftyJSON
import PlainPing
import CoreWLAN

class Network{
    static var success = false
    
    static func getSSID() -> String? {
        let wifi = CWWiFiClient.shared().interface()
        return wifi?.ssid()
    }
    
    static func savePassword(userName:String,password:String){
        let keychain = Keychain(service: "org.ShanghaiTech.WhyFiMac").synchronizable(false)
        UserDefaults.standard.set(userName, forKey: "UserName")
        UserDefaults.standard.set(password, forKey: "Password")
        do{
            //keychain[userName] = password
//            try keychain
//                .synchronizable(false)
//                .set(password, key: userName)
        }
        catch let error {
            print("KeyChain error: \(error)")
        }
    }
    
    private static func showNotify(title:String,detail:String,informativeText:String){
        let notification = NSUserNotification()
        notification.identifier = String(arc4random())
        notification.title = title
        notification.subtitle = detail
        notification.informativeText = informativeText
        notification.soundName = NSUserNotificationDefaultSoundName
        let notificationCenter = NSUserNotificationCenter.default
        notificationCenter.deliver(notification)
    }
    static func messageOccurred(isError:Bool,detail:String,window:ViewController?){
        DispatchQueue.main.async {
            if window != nil{
                window!.indicator.isHidden = true
                window!.indicator.stopAnimation(nil)
                window!.lblStatus.stringValue = ""
                window!.txfUserName.isEnabled = true
                window!.txfPassword.isEnabled = true
                window!.chkRemember.isEnabled = true
                window!.chkAutoStart.isEnabled = true
                let alert = NSAlert()
                if isError{
                    alert.messageText = "登录时遇到了问题"
                    alert.alertStyle = NSAlert.Style.critical
                }else{
                    alert.messageText = "提示"
                    alert.alertStyle = NSAlert.Style.informational
                }
                
                alert.informativeText = detail
                
                alert.addButton(withTitle: "OK")
                alert.beginSheetModal(for: window!.view.window!, completionHandler: nil)
                window!.txfUserName.becomeFirstResponder()
                window!.btnLogin.isEnabled = true
            }else{

                if isError{
                    showNotify(title: "登录时遇到了问题", detail: detail, informativeText: "请确认信息输入是否正确")
                }else{
                    showNotify(title: "提示", detail: detail, informativeText: "尽情享受吧")
                }
               
            }

        }
        
    }
    
    fileprivate static func syncRequest(ip:String)->(Bool,String){
        var ansrequest = URLRequest(url: URL(string: "https://controller.shanghaitech.edu.cn:8445/PortalServer/Webauth/webAuthAction!syncPortalAuthResult.action")!)
        var success = false
        var message = ""
        let semaphore = DispatchSemaphore(value: 0)
        
        let anspostString = "authLan=zh_CN&hasValidateCode=False&validCode=&hasValidateNextUpdatePassword=true&rememberPwd=false&browserFlag=zh&hasCheckCode=false&checkcode=&saveTime=14&autoLogin=false&userMac=&isBoardPage=false&browserFlag=zh&clientIp=\(ip)"
        ansrequest.httpBody = anspostString.data(using: .utf8)
        URLSession.shared.dataTask(with: ansrequest) { data, response, error in
            //print("TASK BEGIN")
            guard let data = data, error == nil else {
                // ERROR
                message = "未能正确连接到服务器"
                semaphore.signal()
                return
            }
            guard let dataFromString = String(data: data, encoding: .utf8)?.data(using: .utf8, allowLossyConversion: false) else{
                // ERROR
                message = "返回数据格式不正确"
                semaphore.signal()
                return
            }
            //print(String(data: data, encoding: .utf8)!)
            guard let json = try? JSON(data: dataFromString) else {
                // ERROR
                message = "返回数据格式不正确"
                semaphore.signal()
                return
            }
            if json["data"]["portalAuthStatus"] == 1{
                // SUCCESS
                success = true
                semaphore.signal()
            }
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return (success,message)
    }
    
    fileprivate static func loginStatus(username:String,password:String,savePassWord:NSControl.StateValue)->(Bool,String,String) {
        let sema = DispatchSemaphore( value: 0)
        var success = false
        var message = ""
        var ip = ""
        
        var request = URLRequest(url: URL(string: "https://controller.shanghaitech.edu.cn:8445/PortalServer/Webauth/webAuthAction!login.action")!)
        request.httpMethod = "POST"
        let postString = "userName=\(username)&password=\(password)&authLan=zh_CN&hasValidateCode=False&validCode=&hasValidateNextUpdatePassword=true&rememberPwd=false&browserFlag=zh&hasCheckCode=false&checkcode=&saveTime=14&autoLogin=false&userMac=&isBoardPage=false"
        request.httpBody = postString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                // ERROR
                message = "未能正确连接到服务器"
                sema.signal()
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                // HTTP ERROR
                message = "HTTP 请求错误，请求返回为：\(httpStatus.statusCode)"
                sema.signal()
                return
            }
            
            if let dataFromString = String(data: data, encoding: .utf8)?.data(using: .utf8, allowLossyConversion: true){
                
                guard let json = try? JSON(data: dataFromString) else {
                    message = "NOT JSON DATA"
                    // NOT JSON DATA
                    sema.signal()
                    return
                }
                ip = json["data"]["ip"].stringValue
                if json["data"]["accessStatus"] != 200{
                    message = "服务器返回错误，消息为：" + json["message"].stringValue
                    sema.signal()
                }else{
                    success = true
                    sema.signal()
                }
            }else{
                // EMPTY DATA ERROR
                message = "数据格式有误"
                sema.signal()
            }
        }
        
        task.resume()
        _ = sema.wait(timeout: DispatchTime.distantFuture)
        return (success,message,ip)
    }
    
    static func login(username:String,password:String,window:ViewController?,savePassWord:NSControl.StateValue) {
        
        let sema = DispatchSemaphore( value: 0)
        if window != nil {
            DispatchQueue.main.async {
                window!.indicator.isHidden = false
                window!.indicator.startAnimation(nil)
                window!.lblStatus.stringValue = "正在登录"
                window!.btnLogin.isEnabled = false
                window!.txfUserName.isEnabled = false
                window!.txfPassword.isEnabled = false
                window!.chkRemember.isEnabled = false
                window!.chkAutoStart.isEnabled = false
                
            }
        }else{
            showNotify(title: "正在登录", detail: "正在尝试登录", informativeText: "这可能需要一点时间")
        }
        DispatchQueue.global().async {
            let (status,message,ip) = loginStatus(username:username,password:password,savePassWord:savePassWord)
            if status{
                for i in 1...10 {
                    DispatchQueue.main.async {
                        window?.lblStatus.stringValue = "正在登录..\(i)/10"
                    }
                    let (status,_) = syncRequest(ip: ip)
                    if status{
                        print("TRUE SUCCESS")
                        messageOccurred(isError:false,detail: "登录成功。已经连接到互联网。", window: window)
                        if savePassWord == .on {
                            savePassword(userName: username, password: password)
                        }
                        sema.signal()
                        return
                    }
                    sleep(3)
                }
                messageOccurred(isError:true,detail: "超时", window: window)
            }else{
                messageOccurred(isError:true,detail: message, window: window)
            }
            sema.signal()
            
        }
        _ = sema.wait(timeout: DispatchTime.distantFuture)
        
    }
}
