//
//  AppDelegate.swift
//  WhyFiMac
//
//  Created by Tom on 2018/5/27.
//  Copyright © 2018年 Tom. All rights reserved.
//

import Cocoa
import KeychainAccess
import PlainPing

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate,NSUserNotificationCenterDelegate,NSMenuDelegate {
    let menu = NSMenu()
    let mainViewController = NSStoryboard(name: .init(rawValue: "Main"), bundle: nil).instantiateController(withIdentifier: .init(rawValue: "MainView")) as! NSWindowController
    var item : NSStatusItem? = nil
    let keychain = Keychain(service: "org.ShanghaiTech.WhyFiMac").synchronizable(false)
    var username = ""
    var password = ""
    var KeepConnection = false
    var logging = false
    //var lastLoginTime = ""
    
    private func showNotify(title:String,detail:String,informativeText:String){
        let notification = NSUserNotification()
        notification.identifier = "NOUserNameOrP"
        notification.title = title
        notification.subtitle = detail
        notification.informativeText = informativeText
        notification.soundName = NSUserNotificationDefaultSoundName
        let notificationCenter = NSUserNotificationCenter.default
        notificationCenter.deliver(notification)
    }
    
    @objc func showMe(){
        mainViewController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func trueLogin(silence:Int){
        DispatchQueue.global().async {
            self.username = UserDefaults.standard.string(forKey: "UserName") ?? ""
            self.password = UserDefaults.standard.string(forKey: "Password") ?? "" //self.keychain[self.username] ?? ""
            let state = (UserDefaults.standard.object(forKey: "Remember") as? NSControl.StateValue) ?? .off

            
            if (self.username == "" || self.password == "") {
                DispatchQueue.main.async {
                    if silence != 0{
                        self.mainViewController.showWindow(self)
                        NSApp.activate(ignoringOtherApps: true)
                        self.showNotify(title: "没有保存用户名和密码", detail: "请打开应用窗口", informativeText: "保存用户名和密码")
                    }
                    
                }
                
            }else{
                DispatchQueue.main.async {
                    self.menu.items[2].isHidden = true
                    self.menu.items[3].isHidden = true
                    self.menu.items[4].isHidden = true
                    self.mainViewController.close()
                }
                self.logging = true
                let loginResult = Network.login(username: self.username, password: self.password, window: nil, savePassWord: (UserDefaults.standard.object(forKey: "Remember") as? NSControl.StateValue) ?? .on, silence: silence)
                if loginResult.0 {
                    DispatchQueue.main.async {
                        self.menu.items[7].title = "上次登录：" + loginResult.1
                    }
                    
                }
            }
            DispatchQueue.main.async {
                self.logging = false
                self.menu.items[2].isHidden = false
                self.menu.items[3].isHidden = false
                self.menu.items[4].isHidden = false
                if self.username != "" && self.password != "" {
                    self.menu.items[0].title = "已保存用户名: " + self.username
                }else{
                    self.menu.items[0].title = "已保存用户名: " + "N/A"
                }
            }
        }
    }
    @objc func Login(){
        trueLogin(silence: 1)
    }
    @objc func quitMe(){
        NSApplication.shared.terminate(self)
    }
    @objc func check(){
        KeepConnection = !KeepConnection
        UserDefaults.standard.set(KeepConnection, forKey: "KeepConnection")
    }
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func backgroundLoop(){
        DispatchQueue.global().async {
            repeat{
                if self.KeepConnection && !self.logging {
                    PlainPing.ping("controller.shanghaitech.edu.cn", withTimeout: 8.0, completionBlock: { (timeElapsed:Double?, error:Error?) in
                        if let latency = timeElapsed {
                            print("latency (ms): \(latency)")
                            self.trueLogin(silence: 0)
                        }
                        if let error = error {
                            print("error: \(error.localizedDescription)")
                        }
                    })
                }
                sleep(1800)
            }while true
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        KeepConnection = UserDefaults.standard.bool(forKey: "KeepConnection")
        
        username = UserDefaults.standard.string(forKey: "UserName") ?? ""
        password = UserDefaults.standard.string(forKey: "Password") ?? "" //keychain[username] ?? ""
        NSUserNotificationCenter.default.delegate = self
        menu.delegate = self
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item?.title = "WiFi"
        if username != "" && password != "" {
            let usernameitem = NSMenuItem(title: "已保存用户名: " + username, action: nil, keyEquivalent: "")
            usernameitem.isEnabled = false
            menu.addItem(usernameitem)
        }else{
            let usernameitem = NSMenuItem(title: "已保存用户名: " + "N/A", action: nil, keyEquivalent: "")
            usernameitem.isEnabled = false
            menu.addItem(usernameitem)
        }
        

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "登录", action: #selector(AppDelegate.Login), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "显示登录窗口", action: #selector(AppDelegate.showMe), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        let wifiitem = NSMenuItem(title: "Wi-Fi: " + (Network.getSSID() ?? ("N/A")), action: nil, keyEquivalent: "")
        wifiitem.isEnabled = false
        menu.addItem(wifiitem)
        let networkitem = NSMenuItem(title: "检查网络连接", action: #selector(AppDelegate.check), keyEquivalent: "")
        networkitem.isEnabled = true
        menu.addItem(networkitem)
        
        let lastloginitem = NSMenuItem(title: "上次登录：N/A", action:nil, keyEquivalent: "")
        lastloginitem.isEnabled = false
        menu.addItem(lastloginitem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(AppDelegate.quitMe), keyEquivalent: ""))
        item?.menu = menu
        
        
        if username == "" || password == "" {
            mainViewController.showWindow(self)
        }
        backgroundLoop()
        
        // Insert code here to initialize your application
    }

    func menuWillOpen(_ menu: NSMenu) {
        username = UserDefaults.standard.string(forKey: "UserName") ?? ""
        password = UserDefaults.standard.string(forKey: "Password") ?? "" //keychain[username] ?? ""
        if !logging{
            if username != "" && password != "" {
                menu.items[0].title = "已保存用户名: " + username
            }else{
                menu.items[0].title = "已保存用户名: " + "N/A"
            }
        }else{
            menu.items[0].title = "正在登录，用户名: " + username
        }

        
        menu.items[5].title = "WiFi: " + (Network.getSSID() ?? ("N/A"))
        
        if KeepConnection{
            self.menu.items[6].title = "每半小时重新登录：开"
        }else{
            self.menu.items[6].title = "每半小时重新登录：关"
        }
        
        
//        let  dateFormater = DateFormatter.init()
//        dateFormater.dateFormat = "YYYY-MM-dd HH:mm:ss"
//
//        self.menu.items[7].title = "上次登录：" + dateFormater.string(from: Date())


    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

