# 上科大 Why-Fi Surfer Mac 登录器

## 简介

把之前 https://github.com/TomJinW/WhyFi_Surfer iOS 版登录器的代码一大部分移植到了 Mac 上。简单的做了一个登录小工具。右键点击.app文件打开，如果不行的话，可能要设置一下从任意来源安装App（http://www.orsoon.com/news/168373.html）。


## 主要功能
- 支持 OS X El Capitan 10.11 以上的 Mac。
- 支持右上方小工具常驻。支持从通知中心显示登录状态。
- 支持 Touch Bar 按钮。（虽然没什么卵用）
- 与学校登录认证相同的结果反馈。
- 支持记住密码（Mac 因为 App 签名问题，使用 UserDefault 存储密码，相对于钥匙串安全性稍差）。
- 支持通过 Ping 来检查互联网连接情况。
- 支持简体中文。

## 其他
- 欢迎反馈任何 BUG，因时间关系我可能无法及时修补。但是还是会努力的。
- 需要开机自动启动的话，可以自行在系统偏好设置中设定(https://jingyan.baidu.com/article/77b8dc7fbc943c6175eab64e.html)。
- 由于自己没多少时间，这个东西匆匆忙忙就上线了，请多谅解。

## 使用的第三方库
- SwiftyJSON https://github.com/SwiftyJSON/SwiftyJSON
- KeyChainAccess https://github.com/kishikawakatsumi/KeychainAccess
- PlainPing https://github.com/naptics/PlainPing
- SVWebViewController https://github.com/TransitApp/SVWebViewController