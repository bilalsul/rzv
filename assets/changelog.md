# Changelog

## 0.6.7
- Fix: Fix broken theme for different dialogs in Zip Manager and About
- Feat: Add Changelog Viewing and App Licenses in About
- Clean: Replace About in Drawer with Default About

- Fix： 修复 Zip 管理器和“关于”对话框中不同对话框的主题显示问题
- Feat： 在“关于”中添加更新日志查看和应用许可证信息
- Clean： 将抽屉式菜单中的“关于”替换为默认的“关于”信息

## 0.6.6
- Fix: Fix broken donwload due to setting default branch
- Feat: Add set branch name to download zip for the providers

- Fix: 修复因设置默认分支导致的下载失败问题
- Feat: 为提供商添加设置分支名称以下载压缩包的功能

## 0.6.4
- Fix: Fix download cancelling and robustly allow another download
- Clean: Remove unused app deps to minimize build size

- Fix： 修复下载取消问题，并允许再次下载。
- Clean： 移除未使用的应用程序依赖项，以最小化构建大小

## 0.6.1
- Fix: Give INTERNET permission for downloading ZIPs and Check for Updates
- Fix: Udate changelog Check for Updates

 Fix： 允许通过 Internet 下载 ZIP 文件并检查更新
- Fix： 更新变更日志并检查更新

## 0.6.0
- Feat: In App Zip Download, Add Multi-Provider (Github, Gitlab, Bitbucket) Zip Download and Manager

- Feat： 应用内 ZIP 下载，添加多提供商（GitHub、GitLab、Bitbucket）ZIP 下载和管理

## 0.3.1
- Fix: Rebranded application to "repo zip Viewer (rzv)" with updated app name across all platforms
- Fix: Udated and fixed all external links (GitHub, Telegram, website) to ensure they point to latest versions

- Fix: 将应用重新品牌化为 "repo zip Viewer (rzv)"，在所有平台上更新了应用名称
- Fix: 更并修复了所有外部链接（GitHub, Telegram, 网站），确保指向最新版本

# 0.2.0
- Feat: Added auto-detection for new app updates directly from the Google Play Console
- Fix: Updated and fixed all production links across the app to ensure they point to the correct live environmnts

- Feat: 添加了从 Google Play Console 自动检测新版本更新的功能
- Fix: 修复并更新了应用内所有生产环境链接，确保指向正确的线上地址

# 0.1.6
- Fix: Upgrade editor layout to support two different views, one when opening a file and another when using direct bttom navigation

- Fix： 升级编辑器布局，支持两种不同视图：打开文件时一种，直接底部导航时另一种

## 0.1.0
- Feat: Support Lock Editor to force locking Editor from interaction
- Fix: Fix broken theme colors for different screens
- Fix: Rmove forced annoying keyboard from showing up in the editor
- UI: Add lock and unlock icon buttons for locking Editor from interaction
- UI: Removed Button feedbacks when clicked
- UI: Add a back navigation in Editor takes back to Project Browser
- Chore: Set Default Plugins Enabled in first launch

- Feat: 支持锁定编辑器，强制防止与编辑器的交互
- Fix: 修复不同屏幕的主题颜色问题
- Fix: 移编辑器中强制弹出的烦人键盘
- UI: 为定编辑器交互添加锁定和解锁图标按钮
- UI: 移除按钮点击时的反馈效果
- UI： 在编辑器中添加返回导航，可回到项目浏览器
- Chore： 在首次启动时默认启用插件

## 0.0.14
- Feat: Support setting up both secondary and accent colors in onboarding
- Fix: Support Dark mode for Onboarding users
- Fix: Support Dark mode for About Gzip Explorer in Settings
- Fix: Theme Customizer not showing current selected theme
- Fix: Removed features that have broken links yet. Will be added when they are fully supported

- Feat: 支持在首次使用引导中设置次要颜色和强调色
- Fix: 为首次使用用户支持深色模式
- Fix: 为置中的"关于 Gzip Explorer"支持深色模式
- Fix: 主自定义器未显示当前选中的主题
- Fix: 移了链接已损坏的功能。将在完全支持时重新添加

# 0.0.12
- Feat: Added app onboarding explaining app's purpose
- Feat: Added App About in settings
- Fix Added a way to detect where new app instance start should take you.

- Feat: 添加了应用首次使用引导，解释应用用途
- Feat: 在设置中添加了"关于应用"
- Fix: 添加了检测新应用实例启动位置的方法

# 0.0.11
- Fix: Detect device language, not supported? show english by default.

 Fix: 检测设备语言，如果不支持？默认显示英文

# 0.0.10
- Fix: Cleaned plugin definitions from breakage
- Fix: Removed unused packages and minimized app size from bloating user's device.

- Fix: 清理了损坏的插件定义
- Fix: 移未使用的包并减小应用体积，防止用户设备膨胀

# 0.0.8
- Feat: Added home action buttons (delete all projects, refresh)
- Feat: Unfocus popping up keyboard on editor screen
- Fix: Fixed not working markdown previewer in home screen
- Feat: Added button to open current markdown in editor
- Fix: Fixed not working refresh projects action button
- Fix: Udated cached home screen and cached editor screen to not rebuild fully
- Fix: Ceaned up broken scroll controller breaking app internal

- Feat: 添加了主页操作按钮（删除所有项目、刷新）
- Feat: 编辑器屏幕取消焦点时弹出键盘
- Fix: 修复了主页中无法工作的 Markdown 预览器
- Feat: 添加了在编辑器中打开当前 Markdown 的按钮
- Fix: 修复了无法工作的刷新项目操作按钮
- Fix: 更了缓存的主页屏幕和编辑器屏幕，避免完全重建
- Fix: 清了破坏应用内部的损坏滚动控制器

# 0.0.7
- UI: Cleaned up settings screen UI
- UI: Enhanced theme selector and language selector widgets
- UI: Updated legacy BottomNavigationBar with scroll detection
- Feat:  Added font family selector
- UI: Improved floating action buttons alignment

- UI: 清理了设置屏幕界面
- UI: 增强了主题选择器和语言选择器小组件
- UI: 使用滚动检测更新了旧版 BottomNavigationBar
- Feat:  添加了字体家族选择器
- UI: 改进了浮动操作按钮的对齐方式

## 0.0.6
- Feat:  Cleaned up hardcoded feature disabled and feature not supported screens localizations
- Feat:  Added supported features list
- Feat:  Added zoom in/out changing editor font size
- Feat:  Added font family options
- Feat:  Updated empty editor file placeholder message
- Feat:  Render unsupported characters in editor with warning bell
- Feat:  Implemented app about and send feedback with URL navigation

- Feat:  清理了硬编码的功能禁用和功能不支持屏幕的本地化
- Feat:  添加了支持的功能列表
- Feat:  添加了缩放更改编辑器字体大小
- Feat:  添加了字体家族选项
- Feat:  更新了空编辑器文件占位符消息
- Feat:  在编辑器中用警告铃渲染不支持的字符
- Feat:  实现了应用关于和通过 URL 导航发送反馈

## 0.0.4
- Feat:  Placed native ads placeholders in settings and app-drawer
- Feat:  Added Italian language support
- Feat:  Added Turkish language support
- Feat:  Added Portuguese language support
- Feat:  Added Russian language support
- Feat:  Added Japanese language support
- Feat:  Added Korean language support
- Feat:  Added Chinese language variants support

- Feat:  在设置和应用抽屉中放置了原生广告占位符
- Feat:  添加了意大利语支持
- Feat:  添加了土耳其语支持
- Feat:  添加了葡萄牙语支持
- Feat:  添加了俄语支持
- Feat:  添加了日语支持
- Feat:  添加了韩语支持
- Feat:  添加了中文变体支持

## 0.0.2
- Feat:  Added theme customization support
- Fix: Updated release pipeline to release app for different Android platforms
- UI: Aded loading indicator to remove empty state flashing

- Feat:  添加了主题自定义支持
- Fix: 更新了发布流水线，为不同的 Android 平台发布应用
- UI: 添了加载指示器以消除空状态闪烁

## 0.0.1
- Feat:  Added timer that tracks when current project was last opened
- Feat:  Fixed i18n support issue
- Feat:  Supported localization for home and settings screens
- Feat:  Supported app_drawer localization
- Feat:  Fixed unzipping archives and showing them from file
- Feat:  Added MonacoEditor to editor
- Feat:  Added French language support
- Feat:  Added German language support
- Feat:  Added Arabic language support
- Fix: Fixed MaterialApp not rebuilding when language is changed
- UI: Aded branding app icon

- Feat:  添加了跟踪当前项目上次打开时间的计时器
- Feat:  修复了 i18n 支持问题
- Feat:  支持主页和设置屏幕的本地化
- Feat:  支持应用抽屉的本地化
- Feat:  修复了解压归档文件并从文件显示的问题
- Feat:  在编辑器中添加了 MonacoEditor
- Feat:  添加了法语支持
- Feat:  添加了德语支持
- Feat:  添加了阿拉伯语支持
- Fix: 修复了更改语言时 MaterialApp 不重建的问题
- UI: 添了品牌应用图标