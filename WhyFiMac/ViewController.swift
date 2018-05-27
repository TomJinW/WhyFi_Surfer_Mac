//
//  ViewController.swift
//  WhyFiMac
//
//  Created by Tom on 2018/5/27.
//  Copyright © 2018年 Tom. All rights reserved.
//

import Cocoa
import KeychainAccess

class ViewController: NSViewController {
    let keychain = Keychain(service: "org.ShanghaiTech.WhyFiMac").synchronizable(false)
    @IBOutlet weak var txfUserName: NSTextField!
    @IBOutlet weak var txfPassword: NSSecureTextField!
    @IBOutlet weak var chkRemember: NSButton!
    @IBOutlet weak var chkAutoStart: NSButton!
    @IBOutlet weak var btnLogin: NSButton!
    @IBOutlet weak var indicator: NSProgressIndicator!
    @IBOutlet weak var lblStatus: NSTextField!
    @IBOutlet weak var tbAutoStart: NSButton!
    @IBOutlet weak var tbRemember: NSButton!
    var logging = false
    
    func recover(){
        chkRemember.state = (UserDefaults.standard.object(forKey: "Remember") as? NSControl.StateValue) ?? .on
        chkAutoStart.state = (UserDefaults.standard.object(forKey: "AutoStart") as? NSControl.StateValue) ?? .off
        changeStateString(prefix:"自动启动",sender:chkAutoStart,tbButton:tbAutoStart)
        changeStateString(prefix:"记住密码",sender:chkRemember,tbButton:tbRemember)
        if let username = UserDefaults.standard.string(forKey: "UserName"){
            txfUserName.stringValue = username
            txfPassword.stringValue = UserDefaults.standard.string(forKey: "Password") ?? ""

        }

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear() {
        recover()
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func befLogin(){
        if logging{
           return
        }
        logging = true
        if txfUserName.stringValue == "" || txfPassword.stringValue == ""{
            Network.messageOccurred(isError:true,detail: "用户名或密码不能为空", window: self)
            logging = false
            return
        }
        let username = self.txfUserName.stringValue;let password = self.txfPassword.stringValue;let state = self.chkRemember.state
        DispatchQueue.global().async {
            Network.login(username: username, password: password, window: self, savePassWord: state)
            self.logging = false
        }
       
    }
    @IBAction func returnPressed(_ sender: NSSecureTextField) {
        befLogin()
    }
    @IBAction func performLogin(_ sender: NSButton) {
        befLogin()
    }
    @IBAction func touchBarPerformLogin(_ sender: NSButton) {
        befLogin()
    }
    func changeStateString(prefix:String,sender:NSButton,tbButton:NSButton){
        switch sender.state {
        case .on:
            tbButton.title = prefix + "：开"
        case .off:
            tbButton.title = prefix + "：关"
        default:break
        }
    }
    @IBAction func remember(_ sender: NSButton) {
        switch chkRemember.state {
        case .on:
            chkRemember.state = .off
        case .off:
            chkRemember.state = .on
        default:
            break
        }
        changeStateString(prefix: "记住密码", sender: chkRemember,tbButton: sender)
    }
    @IBAction func autoStart(_ sender: NSButton) {
        switch chkAutoStart.state {
        case .on:
            chkAutoStart.state = .off
        case .off:
            chkAutoStart.state = .on
        default:
            break
        }
        changeStateString(prefix: "自动启动", sender: chkAutoStart,tbButton: sender)
    }
    
    @IBAction func tbUserName(_ sender: NSButton) {
        txfUserName.becomeFirstResponder()
    }
    
    @IBAction func chkRememberChg(_ sender: NSButton) {
        changeStateString(prefix: "记住密码", sender: chkRemember,tbButton: tbRemember)
    }
    @IBAction func chkAutoStartChg(_ sender: NSButton) {
        switch chkAutoStart.state {
        case .on:
            print("on")
        case .off:
            print("off")
        default:
            break
        }
        changeStateString(prefix: "自动启动", sender: chkAutoStart,tbButton: tbAutoStart)
    }
    @IBAction func tbPassword(_ sender: NSButton) {
        txfPassword.becomeFirstResponder()
    }


    
    override func viewWillDisappear() {
        UserDefaults.standard.set(chkRemember.state, forKey: "Remember")
        UserDefaults.standard.set(chkAutoStart.state, forKey: "AutoStart")
        UserDefaults.standard.set(txfUserName.stringValue, forKey: "UserName")
        if chkRemember.state == .off{
            UserDefaults.standard.set("", forKey: "Password")
        }else{
            UserDefaults.standard.set(txfPassword.stringValue, forKey: "Password")
        }
    }
}

