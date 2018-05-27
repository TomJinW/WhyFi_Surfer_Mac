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
    var logging = false
    @objc func showMe(){
        mainViewController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc func Login(){
        
        DispatchQueue.global().async {
            self.username = UserDefaults.standard.string(forKey: "UserName") ?? ""
            self.password = UserDefaults.standard.string(forKey: "Password") ?? "" //self.keychain[self.username] ?? ""
            let state = (UserDefaults.standard.object(forKey: "Remember") as? NSControl.StateValue) ?? .off
            DispatchQueue.main.async {
                self.menu.items[2].isHidden = true
                self.menu.items[3].isHidden = true
                self.menu.items[4].isHidden = true
                self.mainViewController.close()
            }
            
            if self.username == "" || self.password == "" {
                DispatchQueue.main.async {
                    self.mainViewController.showWindow(self)
                    NSApp.activate(ignoringOtherApps: true)
                }
                
            }else{
                self.logging = true
                Network.login(username: self.username, password: self.password, window: nil, savePassWord: (UserDefaults.standard.object(forKey: "Remember") as? NSControl.StateValue) ?? .on)
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
    @objc func quitMe(){
        NSApplication.shared.terminate(self)
    }
    @objc func check(){
        PlainPing.ping("www.baidu.com", withTimeout: 1.0, completionBlock: { (timeElapsed:Double?, error:Error?) in
            if let latency = timeElapsed {
                print("latency (ms): \(latency)")
                self.menu.items[6].title = "互联网：正常"
            }
            
            if let error = error {
                print("error: \(error.localizedDescription)")
                self.menu.items[6].title = "互联网：断开"
            }
        })
    }
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    func applicationDidFinishLaunching(_ aNotification: Notification) {
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
        let wifiitem = NSMenuItem(title: "WiFi: " + (Network.getSSID() ?? ("N/A")), action: nil, keyEquivalent: "")
        wifiitem.isEnabled = false
        menu.addItem(wifiitem)
        let networkitem = NSMenuItem(title: "检查网络连接", action: #selector(AppDelegate.check), keyEquivalent: "")
        networkitem.isEnabled = true
        menu.addItem(networkitem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(AppDelegate.quitMe), keyEquivalent: ""))
        item?.menu = menu
        

        if username == "" || password == "" {
            mainViewController.showWindow(self)
        }
        
        
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

        
        

        


    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

