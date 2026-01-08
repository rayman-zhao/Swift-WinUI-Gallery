import Foundation
import UWP
import WinAppSDK
import WindowsFoundation
import WinUI

class MainWindow: Window, @unchecked Sendable {
    // MARK: - Properties

    private let viewModel: MainWindowViewModel

    private var rootGrid: Grid
    private var titleBarGrid: Grid
    private var tbDragRegionLeft: Border?
    private var tbDragRegionRight: Border?
    private var tbCaptionSpacer: Border?
    
    private var tbLeftCluster: FrameworkElement?
    private var tbCenterCluster: FrameworkElement?
    private var tbNavCanvas: Canvas?
    private var tbNavHost: FrameworkElement?
    private let tbNavAnchorRatio: Double = 0.4
    private let tbSearchAnchorRatio: Double = 0.6
    private var navigationView: NavigationView
    private var tabView: TabView

    private var singleFrameHost: Frame
    private var contentHost: Grid
    private var isSingleTabMode: Bool = false

    private var controlsSearchBox: AutoSuggestBox
    private var currentPageTextBlock: TextBlock

    private var forwardStack: [String] = []
    private var forwardButton: Button
    private var backButton: Button
    private var stack: [String] = []
    private var appIconImage: Image
    private var avatarBorder: Border
    
    private var openInNewTabRequested: Bool = false

    // MARK: - Initialization
    override init() {
        self.viewModel = MainWindowViewModel()
        self.rootGrid = Grid()
        self.titleBarGrid = Grid()
        self.navigationView = NavigationView()
        self.tabView = TabView()
        self.controlsSearchBox = AutoSuggestBox()
        self.currentPageTextBlock = TextBlock()
        self.backButton = Button()
        self.forwardButton = Button()
        self.appIconImage = Image()
        self.avatarBorder = Border()

        self.singleFrameHost = Frame()
        self.contentHost = Grid()

        super.init()
        self.content = self.rootGrid

        self.setupUI()
        bindViewModel()
    }

    // MARK: - UI 搭建

    func setupUI() {
        self.title = "Swift WinUI3 Gallery"
        self.extendsContentIntoTitleBar = true

        let micaBackdrop = MicaBackdrop()
        micaBackdrop.kind = .base
        self.systemBackdrop = micaBackdrop

        if let appWindow = self.appWindow {
            if let iconPath = Bundle.module.path(
                forResource: "GalleryIcon",
                ofType: "ico",
                inDirectory: "Assets/Tiles"
            ) {
                do { try appWindow.setIcon(iconPath) }
                catch { debugPrint("Failed to set appWindow icon: \(error)") }
            }
        }

        setupRootGrid()
        setupTitleBarGrid()
        setupNavigationView()
    }

    private func setupRootGrid() {
        rootGrid.name = "RootGrid"

        let rowDefinition1 = RowDefinition()
        rowDefinition1.height = GridLength(value: 48, gridUnitType: .pixel)
        rootGrid.rowDefinitions.append(rowDefinition1)
        
        let rowDefinition2 = RowDefinition()
        rowDefinition2.height = GridLength(value: 1, gridUnitType: .star)
        rootGrid.rowDefinitions.append(rowDefinition2)
    }

private func setupTitleBarGrid() {
    titleBarGrid.name = "TitleBarGrid"
    titleBarGrid.height = 48
    titleBarGrid.background = SolidColorBrush(Color(a: 0, r: 0, g: 0, b: 0))

    let col0 = ColumnDefinition()
    col0.width = GridLength(value: 1, gridUnitType: .auto)
    titleBarGrid.columnDefinitions.append(col0)

    let col1 = ColumnDefinition()
    col1.width = GridLength(value: 1, gridUnitType: .star)
    titleBarGrid.columnDefinitions.append(col1)

    let col2 = ColumnDefinition()
    col2.width = GridLength(value: 1, gridUnitType: .auto)
    titleBarGrid.columnDefinitions.append(col2)

    let col3 = ColumnDefinition()
    col3.width = GridLength(value: 1, gridUnitType: .star)
    titleBarGrid.columnDefinitions.append(col3)

    let col4 = ColumnDefinition()
    col4.width = GridLength(value: 140, gridUnitType: .pixel)
    titleBarGrid.columnDefinitions.append(col4)

    // ============ 第0列：左侧内容 ============
    let leftStack = StackPanel()
    leftStack.orientation = .horizontal
    leftStack.verticalAlignment = .center
    leftStack.spacing = 0


    let hamburgerButton = Button()
    let hamburgerIcon = FontIcon()
    hamburgerIcon.glyph = "\u{E700}"
    hamburgerIcon.fontSize = 12
    hamburgerButton.content = hamburgerIcon
    hamburgerButton.verticalAlignment = .center
    hamburgerButton.width = 40
    hamburgerButton.height = 32
    hamburgerButton.margin = Thickness(left: 8, top: 0, right: 8, bottom: 0)
    hamburgerButton.background = SolidColorBrush(Color(a: 0, r: 0, g: 0, b: 0))
    hamburgerButton.borderBrush = SolidColorBrush(Color(a: 0, r: 0, g: 0, b: 0))
    hamburgerButton.click.addHandler { [weak self] _, _ in
        guard let self = self else { return }
        self.navigationView.isPaneOpen = !self.navigationView.isPaneOpen
    }

    // App Icon
    appIconImage.width = 16
    appIconImage.height = 16
    appIconImage.margin = Thickness(left: 8, top: 0, right: 8, bottom: 0)
    appIconImage.verticalAlignment = .center
    
    if Bundle.module.path(forResource: "GalleryIcon", ofType: "png", inDirectory: "Assets/Tiles") != nil {
        let uri = Uri("ms-appx:///Assets/Tiles/GalleryIcon.png")
        let bitmap = BitmapImage()
        bitmap.uriSource = uri
        appIconImage.source = bitmap
    }

    // Title
    let titleText = TextBlock()
    titleText.text = "Swift WinUI 3 Gallery"
    titleText.fontSize = 14
    titleText.verticalAlignment = .center

    // Current Page
    currentPageTextBlock.fontSize = 12
    currentPageTextBlock.opacity = 0.75
    currentPageTextBlock.verticalAlignment = .center
    currentPageTextBlock.margin = Thickness(left: 8, top: 0, right: 16, bottom: 0)
    currentPageTextBlock.text = ""

    // Back Button
    let backIcon = FontIcon()
    backIcon.glyph = "\u{E72B}"
    backIcon.fontSize = 12

    backButton.content = backIcon
    backButton.verticalAlignment = .center
    backButton.margin = Thickness(left: 0, top: 0, right: 0, bottom: 0)
    backButton.width = 40
    backButton.height = 32
    backButton.isEnabled = false
    backButton.click.addHandler { [weak self] _, _ in
        self?.navigateBack()
    }

    // Forward Button
    let forwardIcon = FontIcon()
    forwardIcon.glyph = "\u{E72A}"
    forwardIcon.fontSize = 12

    forwardButton.content = forwardIcon
    forwardButton.verticalAlignment = .center
    forwardButton.margin = Thickness(left: 0, top: 0, right: 0, bottom: 0)
    forwardButton.width = 40
    forwardButton.height = 32
    forwardButton.isEnabled = false
    forwardButton.click.addHandler { [weak self] _, _ in
        self?.navigateForward()
    }

    leftStack.children.append(hamburgerButton)
    leftStack.children.append(appIconImage)
    leftStack.children.append(titleText)
    leftStack.children.append(currentPageTextBlock)

    self.tbLeftCluster = leftStack

    titleBarGrid.children.append(leftStack)
    try? Grid.setColumn(leftStack, 0)

    let navHost = StackPanel()
    navHost.orientation = .horizontal
    navHost.verticalAlignment = .center
    navHost.spacing = 4
    navHost.children.append(backButton)
    navHost.children.append(forwardButton)
    self.tbNavHost = navHost

    let navCanvas = Canvas()
    navCanvas.isHitTestVisible = true
    navCanvas.children.append(navHost)
    self.tbNavCanvas = navCanvas

    titleBarGrid.children.append(navCanvas)
    try? Grid.setColumnSpan(navCanvas, 5)

    // ============ 第1列：左侧拖拽区域 ============
    let dragRegionLeft = Border()
    self.tbDragRegionLeft = dragRegionLeft
    dragRegionLeft.background = SolidColorBrush(Color(a: 0, r: 0, g: 0, b: 0))
    dragRegionLeft.verticalAlignment = .stretch
    dragRegionLeft.horizontalAlignment = .stretch
    dragRegionLeft.isHitTestVisible = false

    titleBarGrid.children.append(dragRegionLeft)
    try? Grid.setColumn(dragRegionLeft, 1)

    // ============ 第2列：搜索框 + 头像（居中） ============
    let centerStack = StackPanel()
    self.tbCenterCluster = centerStack
    centerStack.orientation = .horizontal
    centerStack.verticalAlignment = .center
    centerStack.spacing = 8

    // Search Box
    controlsSearchBox.name = "controlsSearchBox"
    controlsSearchBox.placeholderText = "Search controls and samples..."
    controlsSearchBox.verticalAlignment = .center
    controlsSearchBox.minWidth = 320

    // Avatar
    avatarBorder.width = 32
    avatarBorder.height = 32
    avatarBorder.cornerRadius = CornerRadius(topLeft: 16, topRight: 16, bottomRight: 16, bottomLeft: 16)
    avatarBorder.verticalAlignment = .center
    avatarBorder.background = SolidColorBrush(Color(a: 255, r: 100, g: 100, b: 250))

    let avatarText = TextBlock()
    avatarText.text = "PP"
    avatarText.verticalAlignment = .center
    avatarText.horizontalAlignment = .center
    avatarText.fontSize = 12
    avatarText.foreground = SolidColorBrush(Color(a: 255, r: 255, g: 255, b: 255))
    avatarBorder.child = avatarText

    centerStack.children.append(controlsSearchBox)
    centerStack.children.append(avatarBorder)

    navCanvas.children.append(centerStack)
    try? Canvas.setTop(centerStack, 8)

    // ============ 第3列：右侧拖拽区域 ============
    let dragRegionRight = Border()
    self.tbDragRegionRight = dragRegionRight
    dragRegionRight.background = SolidColorBrush(Color(a: 0, r: 0, g: 0, b: 0))
    dragRegionRight.verticalAlignment = .stretch
    dragRegionRight.horizontalAlignment = .stretch
    dragRegionRight.isHitTestVisible = false

    titleBarGrid.children.append(dragRegionRight)
    try? Grid.setColumn(dragRegionRight, 3)

    let captionSpacer = Border()
    captionSpacer.background = SolidColorBrush(Color(a: 0, r: 0, g: 0, b: 0))
    captionSpacer.isHitTestVisible = false
    self.tbCaptionSpacer = captionSpacer
    titleBarGrid.children.append(captionSpacer)
    try? Grid.setColumn(captionSpacer, 4)

    // 添加到根Grid
    rootGrid.children.append(titleBarGrid)
    try? Grid.setRow(titleBarGrid, 0)

    titleBarGrid.loaded.addHandler { [weak self] _, _ in
        guard let self = self else { return }
        self.updateTitleBarLayout()
        DispatchQueue.main.async { [weak self] in
            self?.updateTitleBarLayout()
        }
    }
    titleBarGrid.sizeChanged.addHandler { [weak self] _, _ in
        self?.updateTitleBarLayout()
    }
    currentPageTextBlock.sizeChanged.addHandler { [weak self] _, _ in
        self?.updateTitleBarLayout()
    }

}

    // MARK: - Ctrl 检测

    private func updateCtrlFlagFromPointer(_ args: PointerRoutedEventArgs?) {
        guard let args = args else { return }
        let raw = Int(args.keyModifiers.rawValue)
        openInNewTabRequested = (raw & 0x1) != 0
    }

    // MARK: - NavigationView + TabView

    private func setupSubCategories(category: any Category, navigationViewItem: NavigationViewItem) {
        if category.subCategories.isEmpty { return }

        for subCategory: any Category in category.subCategories {
            let subItem = NavigationViewItem()
            subItem.tag = Uri("xca://\(subCategory.rawValue)")
            subItem.content = subCategory.text

            subItem.pointerPressed.addHandler { [weak self] _, args in
                self?.updateCtrlFlagFromPointer(args)
            }

            navigationViewItem.menuItems.append(subItem)
        }
    }

    private func updateTitleBarLayout() {
        updateSearchHostPosition()
        updateNavHostPosition()
        applyTitleBarDragRegions()
    }

    private func updateSearchHostPosition() {
        guard let centerCluster = self.tbCenterCluster as? FrameworkElement else { return }
        guard let leftCluster = self.tbLeftCluster as? FrameworkElement else { return }
        guard let captionSpacer = self.tbCaptionSpacer as? FrameworkElement else { return }
        guard let navHost = self.tbNavHost as? FrameworkElement else { return }

        let barW = Double(self.titleBarGrid.actualWidth)
        if barW <= 1.0 { return }

        let centerW = Double(centerCluster.actualWidth)
        if centerW <= 1.0 {
            DispatchQueue.main.async { [weak self] in
                self?.updateSearchHostPosition()
            }
            return
        }

        let captionLeft = Double(captionSpacer.actualOffset.x)
        let leftEnd = Double(leftCluster.actualOffset.x) + Double(leftCluster.actualWidth)

        let targetCenterX = barW * self.tbSearchAnchorRatio
        var leftX = targetCenterX - centerW / 2.0

        let navW = Double(navHost.actualWidth)
        let minLeft = leftEnd + 12.0 + max(0.0, navW) + 12.0
        let maxLeft = captionLeft - 12.0 - centerW

        if maxLeft > minLeft {
            leftX = max(minLeft, min(leftX, maxLeft))
        } else {
            leftX = minLeft
        }

        let centerH = Double(centerCluster.actualHeight)
        let topY = max(0.0, (48.0 - centerH) / 2.0)

        try? Canvas.setLeft(centerCluster, leftX)
        try? Canvas.setTop(centerCluster, topY)
    }

    private func updateNavHostPosition() {
        guard let navHost = self.tbNavHost as? FrameworkElement else { return }
        guard let leftCluster = self.tbLeftCluster as? FrameworkElement else { return }
        guard let centerCluster = self.tbCenterCluster as? FrameworkElement else { return }

        let barW = Double(self.titleBarGrid.actualWidth)
        if barW <= 1.0 { return }

        let navW = Double(navHost.actualWidth)
        if navW <= 1.0 {
            DispatchQueue.main.async { [weak self] in
                self?.updateNavHostPosition()
            }
            return
        }

        let targetCenterX = barW * self.tbNavAnchorRatio
        var leftX = targetCenterX - navW / 2.0

        let leftLimit = Double(leftCluster.actualOffset.x) + Double(leftCluster.actualWidth) + 12.0
        let rightLimit = Double(centerCluster.actualOffset.x) - 12.0 - navW

        if rightLimit > leftLimit {
            leftX = max(leftLimit, min(leftX, rightLimit))
        } else {
            leftX = leftLimit
        }

        let navH = Double(navHost.actualHeight)
        let topY = max(0.0, (48.0 - navH) / 2.0)

        try? Canvas.setLeft(navHost, leftX)
        try? Canvas.setTop(navHost, topY)
    }

private func boundsInWindowPx(_ fe: FrameworkElement) -> RectInt32? {
        let scale = Double(self.rootGrid.xamlRoot?.rasterizationScale ?? 1.0)

        let wPx = Double(fe.actualWidth) * scale
        let hPx = Double(fe.actualHeight) * scale
        if wPx <= 1.0 || hPx <= 1.0 { return nil }

        do {
            guard let t = try fe.transformToVisual(nil) else { return nil }
            let p = try t.transformPoint(Point(x: 0, y: 0))
            let xPx = Double(p.x) * scale
            let yPx = Double(p.y) * scale

            return RectInt32(
                x: Int32(xPx.rounded(FloatingPointRoundingRule.down)),
                y: Int32(yPx.rounded(FloatingPointRoundingRule.down)),
                width: Int32(wPx.rounded(FloatingPointRoundingRule.up)),
                height: Int32(hPx.rounded(FloatingPointRoundingRule.up))
            )
        } catch {
            return nil
        }
    }

    private func applyTitleBarDragRegions() {
        guard let appWindow = self.appWindow else { return }

        appWindow.titleBar.extendsContentIntoTitleBar = true

        guard let leftCluster = self.tbLeftCluster as? FrameworkElement,
              let centerCluster = self.tbCenterCluster as? FrameworkElement,
              let leftRect = boundsInWindowPx(leftCluster),
              let centerRect = boundsInWindowPx(centerCluster)
        else { return }

        let navRect = (self.tbNavHost as? FrameworkElement).flatMap { boundsInWindowPx($0) }
        let captionRect = self.tbCaptionSpacer.flatMap { boundsInWindowPx($0) }

        let scale = Double(self.rootGrid.xamlRoot?.rasterizationScale ?? 1.0)
        let barHeightPx = Int32(Double(self.titleBarGrid.actualHeight) * scale)

        let leftEndX = leftRect.x + leftRect.width
        let navLeftX = navRect?.x ?? leftEndX
        let navRightX = (navRect != nil) ? (navRect!.x + navRect!.width) : leftEndX

        let centerLeftX = centerRect.x
        let centerRightX = centerRect.x + centerRect.width

        let captionLeftX = captionRect?.x ?? centerRightX

        var rects: [RectInt32] = []

        func addRect(_ x0: Int32, _ x1: Int32) {
            let w = x1 - x0
            if w <= 8 { return }
            rects.append(RectInt32(x: x0, y: leftRect.y, width: w, height: max(barHeightPx, leftRect.height)))
        }

        addRect(leftEndX, navLeftX)
        addRect(navRightX, centerLeftX)
        addRect(centerRightX, captionLeftX)

        if rects.isEmpty { return }
        do { try appWindow.titleBar.setDragRectangles(rects) }
        catch { /* 打包环境无控制台，静默失败即可 */ }
    }

    private func setupNavigationView() {
        navigationView.paneDisplayMode = .auto
        navigationView.isSettingsVisible = true
        navigationView.openPaneLength = 320
        navigationView.isBackButtonVisible = .collapsed
        navigationView.isPaneToggleButtonVisible = false

        MainCategory.allCases.forEach { c in
            let item = NavigationViewItem()
            item.tag = Uri("xca://\(c.rawValue)")

            let icon = FontIcon()
            icon.glyph = c.glyph
            item.icon = icon
            item.content = c.text

            item.pointerPressed.addHandler { [weak self] _, args in
                self?.updateCtrlFlagFromPointer(args)
            }

            setupSubCategories(category: c, navigationViewItem: item)
            navigationView.menuItems.append(item)
        }

        navigationView.selectedItem = navigationView.menuItems[0]

        tabView.tabWidthMode = .sizeToContent
        tabView.isAddTabButtonVisible = false
        tabView.canReorderTabs = true
        tabView.allowDrop = true

        contentHost = Grid()
        contentHost.children.append(tabView)
        contentHost.children.append(singleFrameHost)

        tabView.visibility = .visible
        singleFrameHost.visibility = .collapsed

        navigationView.content = contentHost
        rootGrid.children.append(navigationView)
        try? Grid.setRow(navigationView, 1)

        ensureAtLeastOneTab()
        updateTabVisibilityAndSingleHost()

        tabView.tabCloseRequested.addHandler { [weak self, weak tabView] sender, args in
            guard let self = self else { return }
            guard let tabView = tabView ?? sender else { return }
            guard let args = args else { return }
            guard let closingTab = args.tab else { return }
            guard let items = tabView.tabItems else { return }

            var idx: UInt32 = 0
            if items.indexOf(closingTab, &idx) {
                items.removeAt(idx)
            }

            self.ensureAtLeastOneTab()
            self.updateTabVisibilityAndSingleHost()
        }

        tabView.selectionChanged.addHandler { [weak self] _, _ in
            guard let self = self else { return }
            if self.isSingleTabMode { return }

            guard let tab = self.tabView.selectedItem as? TabViewItem else { return }
            if let raw = tab.tag as? String {
                let displayName = self.getDisplayName(for: raw)
                self.currentPageTextBlock.text = displayName


        selectNavigationItemByRaw(raw)
                self.selectNavigationItemByRaw(raw)
            }
        }
    }

    // MARK: - 单/多 tab 显示逻辑

    private func updateTabVisibilityAndSingleHost() {
        guard let items = tabView.tabItems else { return }
        let count = Int(items.size)

        if count <= 1 {
            isSingleTabMode = true
            tabView.visibility = .collapsed
            singleFrameHost.visibility = .visible
            syncSingleHostFromSelectedTab()
        } else {
            isSingleTabMode = false
            singleFrameHost.visibility = .collapsed
            tabView.visibility = .visible
        }
    }

    private func syncSingleHostFromSelectedTab() {
        if let tab = tabView.selectedItem as? TabViewItem,
           let raw = tab.tag as? String {
            singleFrameHost.content = createPageByRaw(raw)
            currentPageTextBlock.text = getDisplayName(for: raw)
            selectNavigationItemByRaw(raw)
        } else {
            singleFrameHost.content = HomePage()
            currentPageTextBlock.text = "Home"
        }
    }

    // MARK: - Frame / Tab 维护

    private func getOrCreateFrame(in tab: TabViewItem) -> Frame {
        if let frame = tab.content as? Frame { return frame }
        let frame = Frame()
        tab.content = frame
        return frame
    }

    private func ensureAtLeastOneTab() {
        guard let items = tabView.tabItems else { return }

        if items.size == 0 {
            let tab = TabViewItem()
            tab.header = "Home"
            tab.tag = "home"

            let iconSource = FontIconSource()
            iconSource.glyph = "\u{E80F}"
            tab.iconSource = iconSource

            let frame = Frame()
            frame.content = HomePage()
            tab.content = frame

            tab.isClosable = true

            tabView.tabItems.append(tab)
            tabView.selectedItem = tab
            currentPageTextBlock.text = "Home"
        } else if tabView.selectedItem == nil {
            if let first = items.getAt(0) as? TabViewItem {
                tabView.selectedItem = first
            }
        }
    }

    private func showInCurrentTab(raw: String, displayName: String, glyph: String?) {
        ensureAtLeastOneTab()
        guard let tab = tabView.selectedItem as? TabViewItem else { return }

        tab.header = displayName
        tab.tag = raw

        if let glyph = glyph {
            let iconSource = FontIconSource()
            iconSource.glyph = glyph
            tab.iconSource = iconSource
        } else {
            tab.iconSource = nil
        }

        let frame = getOrCreateFrame(in: tab)
        frame.content = createPageByRaw(raw)

        if isSingleTabMode {
            singleFrameHost.content = createPageByRaw(raw)
        }

        currentPageTextBlock.text = displayName
    }

    private func openNewTab(raw: String, displayName: String, glyph: String?) {
        let tab = TabViewItem()
        tab.header = displayName
        tab.tag = raw

        if let glyph = glyph {
            let iconSource = FontIconSource()
            iconSource.glyph = glyph
            tab.iconSource = iconSource
        }

        let frame = Frame()
        frame.content = createPageByRaw(raw)
        tab.content = frame

        tab.isClosable = true

        tabView.tabItems.append(tab)
        tabView.selectedItem = tab
        currentPageTextBlock.text = displayName

        updateTabVisibilityAndSingleHost()
    }
    
    // MARK: - Settings 处理
    
    private func openSettingsInCurrentTab() {
        showInCurrentTab(raw: "settings", displayName: "Settings", glyph: "\u{E713}")
    }
    
    private func openSettingsInNewTab() {
        openNewTab(raw: "settings", displayName: "Settings", glyph: "\u{E713}")
    }

    // MARK: - String到页面的映射
    
    private func createPageByRaw(_ raw: String) -> UIElement {
        switch raw {
        case "home":
            return HomePage()
        case "all":
            return AllPage()
        case "settings":
            return SettingsPage()
        
        case "resources":
            return ResourcesPage()
        case "style":
            return StylesPage()
        case "templates":
            return TemplatesPage()
        case "customUserControls":
            return CustomUserControlsPage()
        case "binding":
            return BindingPage()
        case "scratchPad":
            return ScratchPadPage()

        case "listView":
            return ListViewPage()
        case "flipView":
            return FlipViewPage()
        case "gridView":
            return GridViewPage()
        case "listBox":
            return ListBoxPage()
        case "pullToRefresh":
            return PullToRefreshPage()
        case "treeView":
            return TreeViewPage()

        case "annotatedScrollBar":
            return AnnotatedScrollBarPage()
        case "pipsPager":
            return PipsPagerPage()
        case "scrollView":
            return ScrollViewPage()
        case "scrollViewer":
            return ScrollViewerPage()
        case "semanticZoom":
            return SemanticZoomPage()

        case "grid":
            return GridPage()
        case "border":
            return BorderPage()
        case "canvas":
            return CanvasPage()
        case "expander":
            return ExpanderPage()
        case "radioButtons":
            return RadioButtonsPage()
        case "relativePanel":
            return RelativePanelPage()
        case "stackPanel":
            return StackPanelPage()
        case "variableSizedWrapGrid":
            return variableGridPage()
        case "viewBox":
            return ViewBoxPage()

        case "breadcrumbBar":
            return BreadcrumbBarPage()
        case "navigationView":
            return NavigationViewPage()
        case "pivot":
            return PivotPage()
        case "selectorBar":
            return SelectorBarPage()
        case "tabView":
            return TabViewPage()

        case "appBarButton":
            return AppBarButtonPage()
        case "appBarSeparator":
            return AppBarSeparatorPage()
        case "appBarToggleButton":
            return AppBarToggleButtonPage()
        case "commandBar":
            return CommandBarPage()
        case "commandBarFlyout":
            return CommandBarFlyoutPage()

        case "image":
            return ImagePage()
        case "personPicture":
            return PersonPicturePage()
        case "webView2":
            return WebView2Page()

        case "titleBar":
            let placeholder = Grid()
            let text = TextBlock()
            text.text = "TitleBar Page\n\n(Not available in MSIX package)"
            text.fontSize = 16
            text.horizontalAlignment = .center
            text.verticalAlignment = .center
            text.textAlignment = .center
            placeholder.children.append(text)
            return placeholder

        case "filePicker":
            return StoragePickersPage()
        case "appNotifications":
            return AppNotificationsPage()
        case "badgeNotifications":
            return BadgeNotificationsPage()

        case "contentDialog":
            return ContentDialogPage()
        case "flyout":
            return FlyoutPage()
        case "popup":
            return PopupPage()
        case "teachingTip":
            return TeachingTipPage()

        case "calendarDatePicker":
            return CalendarDatePickerPage()
        case "calendarView":
            return CalendarViewPage()
        case "datePicker":
            return DatePickerPage()
        case "timePicker":
            return TimePickerPage()

        case "infoBadge":
            return InfoBadgePage()
        case "infoBar":
            return InfoBarPage()
        case "progressBar":
            return ProgressBarPage()
        case "progressRing":
            return ProgressRingPage()
        case "toolTip":
            return ToolTipPage()

        case "autoSuggestBox":
            return AutoSuggestBoxPage()
        case "numberBox":
            return NumberBoxPage()
        case "passwordBox":
            return PasswordBoxPage()
        case "richEditBox":
            return RichEditBoxPage()
        case "richTextBlock":
            return RichTextBlockPage()
        case "textBlock":
            return TextBlockPage()
        case "textBox":
            return TextBoxPage()

        case "AcrylicBrush":
            return AcrylicBrushPage()
        case "animatedIcon":
            return AnimatedIconPage()
        case "compactSizing":
            return CompactSizingPage()
        case "iconElement":
            return IconElementPage()
        case "line":
            return LinePage()
        case "shape":
            return ShapePage()
        case "radialGradientBrush":
            return RadialGradientBrushPage()
        case "systemBackdropsMicaAcrylic":
            return SystemBackdropsPage()
        case "themeShadow":
            return ThemeShadowPage()

        default:
            let placeholder = Grid()
            let text = TextBlock()
            text.text = "Page: \(raw)\n\n(Not implemented yet)"
            text.fontSize = 16
            text.horizontalAlignment = .center
            text.verticalAlignment = .center
            text.textAlignment = .center
            text.textWrapping = .wrap
            placeholder.children.append(text)
            return placeholder
        }
    }
    
    private func getDisplayName(for raw: String) -> String {
        if raw == "settings" { return "Settings" }
        
        if let cat = findCategory(byRawValue: raw) {
            return cat.text
        }
        return raw.capitalized
    }
    
    private func getGlyph(for raw: String) -> String? {
        if raw == "settings" { return "\u{E713}" }
        
        if let cat = findCategory(byRawValue: raw) as? MainCategory {
            return cat.glyph
        }
        return nil
    }

    // MARK: - Category 查找

    private nonisolated(unsafe) static let categoryTypes: [any (RawRepresentable & Category).Type] = [
        MainCategory.self,
        FundamentalsCategory.self,
        DesignCategory.self,
        AccessibilityCategory.self,
        BasicInputCategory.self,
        CollectionsCategory.self,
        DateTimeCategory.self,
        DialogsFlyoutsCategory.self,
        LayoutCategory.self,
        MediaCategory.self,
        MenusToolbarsCategory.self,
        MotionCategory.self,
        NavigationViewCategory.self,
        ScrollingCategory.self,
        StatusInfoCategory.self,
        StylesCategory.self,
        SystemCategory.self,
        TextCategory.self,
        WindowingCategory.self
    ]

    private func findCategory(byRawValue rawValue: String) -> (any Category)? {
        for categoryType in Self.categoryTypes {
            if let category = categoryType.init(rawValue: rawValue) {
                return category
            }
        }
        return nil
    }

    // MARK: - 同步左侧选中

    private func selectNavigationItemByRaw(_ raw: String) {
        for anyItem in navigationView.menuItems {
            guard let item = anyItem as? NavigationViewItem else { continue }

            if let tag = (item.tag as? Uri)?.host, tag == raw {
                navigationView.selectedItem = item
                return
            }

            for anySub in item.menuItems {
                guard let sub = anySub as? NavigationViewItem else { continue }
                if let tag = (sub.tag as? Uri)?.host, tag == raw {
                    navigationView.selectedItem = sub
                    return
                }
            }
        }
    }

    // MARK: - 导航历史

    private func updateNavButtonsState() {
        backButton.isEnabled = stack.count > 1
        forwardButton.isEnabled = !forwardStack.isEmpty
    }

    private func seedInitialHistoryIfNeeded() {
        if stack.isEmpty {
            stack = ["home"]
            forwardStack.removeAll()
            updateNavButtonsState()
        }
    }

    private func navigateBack() {
        guard stack.count > 1 else { return }
        let current = stack.removeLast()
        forwardStack.append(current)

        let previous = stack.last ?? "home"
        
        let displayName = getDisplayName(for: previous)
        let glyph = getGlyph(for: previous)
        showInCurrentTab(raw: previous, displayName: displayName, glyph: glyph)
        updateNavButtonsState()
    }

    private func navigateForward() {
        guard let next = forwardStack.popLast() else { return }
        stack.append(next)
        
        let displayName = getDisplayName(for: next)
        let glyph = getGlyph(for: next)
        showInCurrentTab(raw: next, displayName: displayName, glyph: glyph)
        updateNavButtonsState()
    }

    // MARK: - ViewModel 绑定

    func bindViewModel() {
        navigationView.selectionChanged.addHandler { [weak self] _, _ in
            guard let self = self else { return }
            
            if let selected = self.navigationView.selectedItem {
                let itemName = (selected as? NavigationViewItem)?.name ?? ""
                
                if itemName == "SettingsItem" || itemName.isEmpty {
                    let hasTag = (selected as? NavigationViewItem)?.tag != nil
                    if !hasTag {
                        if self.openInNewTabRequested {
                            self.openSettingsInNewTab()
                            self.openInNewTabRequested = false
                        } else {
                            self.openSettingsInCurrentTab()
                            self.openInNewTabRequested = false
                        }
                        return
                    }
                }
            }
        }
        
        navigationView.itemInvoked.addHandler { [weak self] _, args in
            guard let self = self else { return }
            guard let args = args else { self.openInNewTabRequested = false; return }
            guard let container = args.invokedItemContainer as? NavigationViewItem else { self.openInNewTabRequested = false; return }
            guard let tag = (container.tag as? Uri)?.host else { self.openInNewTabRequested = false; return }
            
            if container.menuItems.size > 0 {

                if let tab = self.tabView.selectedItem as? TabViewItem,

                   let currentRaw = tab.tag as? String {

                    self.selectNavigationItemByRaw(currentRaw)

                }

                self.openInNewTabRequested = false

                return

            }

            self.seedInitialHistoryIfNeeded()

            self.forwardStack.removeAll()
            self.stack.append(tag)
            
            let displayName = self.getDisplayName(for: tag)
            let glyph = self.getGlyph(for: tag)
            
            if self.openInNewTabRequested {
                self.openNewTab(raw: tag, displayName: displayName, glyph: glyph)
                self.openInNewTabRequested = false
            } else {
                self.showInCurrentTab(raw: tag, displayName: displayName, glyph: glyph)
                self.openInNewTabRequested = false
            }
            
            self.updateNavButtonsState()
        }

        if let firstItem = navigationView.menuItems.first {
            navigationView.selectedItem = firstItem
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NaviPositionChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, let index = notification.object as? Int else { return }
            switch index {
            case 0: self.navigationView.paneDisplayMode = .left
            case 1: self.navigationView.paneDisplayMode = .top
            default: break
            }
        }

        seedInitialHistoryIfNeeded()
        showInCurrentTab(raw: "home", displayName: "Home", glyph: "\u{E80F}")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}