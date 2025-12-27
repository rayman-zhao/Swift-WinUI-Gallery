import Foundation
import UWP
import WinAppSDK
import WindowsFoundation
import WinUI

class MainWindow: Window, @unchecked Sendable {
    // MARK: - Properties

    private let viewModel: MainWindowViewModel

    /// 是否在 MSIX 打包环境下运行（避免 TitleBar / Category / ReleaseInfo 冲突）
    private static let isMSIX: Bool = ProcessInfo.processInfo.environment["APPX_PACKAGE_FAMILY_NAME"] != nil

    private var rootGrid: Grid
    private var titleBar: TitleBar?
    private var navigationView: NavigationView
    private var tabView: TabView

    // ✅ 单 tab 模式显示用（不做 UIElement 搬家，只显示“新实例页面”）
    private var singleFrameHost: Frame
    private var contentHost: Grid
    private var isSingleTabMode: Bool = false

    private var controlsSearchBox: AutoSuggestBox
    private var currentPageTextBlock: TextBlock

    private var forwardStack: [any Category] = []
    private var forwardButton: Button
    private var backButton: Button
    private var stack: [any Category] = []
    

    /// ✅ 由 NavigationViewItem.pointerPressed 捕获 Ctrl 状态
    private var openInNewTabRequested: Bool = false

    // MARK: - Initialization
    override init() {
        self.viewModel = MainWindowViewModel()
        self.rootGrid = Grid()
        self.navigationView = NavigationView()
        self.tabView = TabView()
        self.titleBar = Self.isMSIX ? nil : TitleBar()
        self.controlsSearchBox = AutoSuggestBox()
        self.currentPageTextBlock = TextBlock()
        self.backButton = Button()
        self.forwardButton = Button()

        self.singleFrameHost = Frame()
        self.contentHost = Grid()

        super.init()
        self.content = self.rootGrid

        self.setupUI()
        if !Self.isMSIX {
            bindViewModel()
        } else {
            setupMSIXFallbackUI()
        }
    }

    // MARK: - UI 搭建

    func setupUI() {
        self.title = "Swift WinUI3 Gallery"
        self.extendsContentIntoTitleBar = !Self.isMSIX

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

        if Self.isMSIX {
            // MSIX 下禁用自定义 TitleBar / Category 导航，避免已知冲突
            return
        }

        setupTitleBar()
        setupNavigationView()
    }

    private func setupRootGrid() {
        rootGrid.name = "RootGrid"

        let row1 = RowDefinition()
        row1.height = Self.isMSIX ? GridLength(value: 0, gridUnitType: .pixel) : GridLength(value: 1, gridUnitType: .auto)
        rootGrid.rowDefinitions.append(row1)

        let row2 = RowDefinition()
        row2.height = GridLength(value: 1, gridUnitType: .star)
        rootGrid.rowDefinitions.append(row2)
    
    }


    /// MSIX 打包运行的最小 UI：只展示 Home，避免 TitleBar / Category / ReleaseInfo 冲突导致的闪退
    private func setupMSIXFallbackUI() {
        // rootGrid 第一行高度已设为 0，仅显示内容区
        let frame = Frame()
        frame.content = HomePage()
        rootGrid.children.append(frame)
        try? Grid.setRow(frame, 1)

        self.title = "Swift WinUI3 Gallery"
    }

    private func createImage(
        height: Double,
        width: Double,
        imagePath: String,
        imageThickness: [Double]
    ) -> Image {
        let image = Image()
        image.height = height
        image.width = width
        image.margin = Thickness(
            left: imageThickness[0],
            top: imageThickness[1],
            right: imageThickness[2],
            bottom: imageThickness[3]
        )
        image.stretch = .uniform

        if imagePath.isEmpty {
            debugPrint("createImage: empty imagePath, returning empty Image")
            return image
        }
        let uri = Uri(imagePath)
        let bitmapImage = BitmapImage()
        bitmapImage.uriSource = uri
        image.source = bitmapImage
        return image
    }

    private func setupTitleBar() {
        guard let titleBar = self.titleBar else { return }

        titleBar.name = "TitleBar"
        titleBar.title = ""

        titleBar.isBackButtonVisible = false
        titleBar.isPaneToggleButtonVisible = true

        titleBar.paneToggleRequested.addHandler { [weak self] _, _ in
            guard let self = self else { return }
            self.navigationView.isPaneOpen.toggle()
        }

        let subtitleReservedWidth: Double = 200
        let navButtonsLeftGap: Double = 8

        let appIcon = createImage(
            height: 16,
            width: 16,
            imagePath: Bundle.module.path(
                forResource: "GalleryIcon",
                ofType: "ico",
                inDirectory: "Assets/Tiles"
            )!,
            imageThickness: [8, 0, 8, 0]
        )

        let titleText = TextBlock()
        titleText.text = "Swift WinUI 3 Gallery"
        titleText.fontSize = 14
        titleText.verticalAlignment = .center

        currentPageTextBlock.fontSize = 12
        currentPageTextBlock.opacity = 0.75
        currentPageTextBlock.verticalAlignment = .center
        currentPageTextBlock.text = ""

        currentPageTextBlock.width = subtitleReservedWidth
        currentPageTextBlock.textTrimming = .characterEllipsis
        currentPageTextBlock.margin = Thickness(left: 8, top: 0, right: 0, bottom: 0)

        func makeMdl2Icon(_ glyph: String, fontSize: Double = 12) -> FontIcon {
            let icon = FontIcon()
            icon.glyph = glyph
            icon.fontSize = fontSize
            icon.verticalAlignment = .center
            return icon
        }

        backButton.content = makeMdl2Icon("\u{E72B}")
        forwardButton.content = makeMdl2Icon("\u{E72A}")

        backButton.verticalAlignment = .center
        forwardButton.verticalAlignment = .center

        backButton.margin = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        forwardButton.margin = Thickness(left: 0, top: 0, right: 0, bottom: 0)

        backButton.padding = Thickness(left: 10, top: 6, right: 10, bottom: 6)
        forwardButton.padding = Thickness(left: 10, top: 6, right: 10, bottom: 6)

        backButton.isEnabled = false
        forwardButton.isEnabled = false

        backButton.click.addHandler { [weak self] _, _ in self?.navigateBack() }
        forwardButton.click.addHandler { [weak self] _, _ in self?.navigateForward() }

        let navButtonsStack = StackPanel()
        navButtonsStack.orientation = .horizontal
        navButtonsStack.verticalAlignment = .center
        navButtonsStack.children.append(backButton)
        navButtonsStack.children.append(forwardButton)

        navButtonsStack.margin = Thickness(left: navButtonsLeftGap, top: 0, right: 0, bottom: 0)

        let leftHeaderStack = StackPanel()
        leftHeaderStack.orientation = .horizontal
        leftHeaderStack.verticalAlignment = .center
        leftHeaderStack.children.append(appIcon)
        leftHeaderStack.children.append(titleText)
        leftHeaderStack.children.append(currentPageTextBlock)
        leftHeaderStack.children.append(navButtonsStack)

        titleBar.leftHeader = leftHeaderStack

        controlsSearchBox.name = "controlsSearchBox"
        controlsSearchBox.placeholderText = "Search controls and samples..."
        controlsSearchBox.verticalAlignment = .center
        controlsSearchBox.minWidth = 320

        let contentGrid = Grid()
        let cc0 = ColumnDefinition(); cc0.width = GridLength(value: 1, gridUnitType: .star) // drag region
        let cc1 = ColumnDefinition(); cc1.width = GridLength(value: 1, gridUnitType: .auto) // search
        contentGrid.columnDefinitions.append(cc0)
        contentGrid.columnDefinitions.append(cc1)

        let dragRegion = Border()
        dragRegion.background = SolidColorBrush(Color(a: 0, r: 0, g: 0, b: 0))
        dragRegion.verticalAlignment = .stretch
        dragRegion.horizontalAlignment = .stretch

        contentGrid.children.append(dragRegion)
        try? Grid.setColumn(dragRegion, 0)

        contentGrid.children.append(controlsSearchBox)
        try? Grid.setColumn(controlsSearchBox, 1)

        titleBar.content = contentGrid

        let avatar = Border()
        avatar.width = 32
        avatar.height = 32
        avatar.cornerRadius = CornerRadius(topLeft: 16, topRight: 16, bottomRight: 16, bottomLeft: 16)
        avatar.verticalAlignment = .center
        avatar.background = SolidColorBrush(Color(a: 255, r: 240, g: 240, b: 240))

        let avatarText = TextBlock()
        avatarText.text = "PP"
        avatarText.verticalAlignment = .center
        avatarText.horizontalAlignment = .center
        avatarText.fontSize = 12
        avatar.child = avatarText

        titleBar.rightHeader = avatar

        rootGrid.children.append(titleBar)
        try? Grid.setRow(titleBar, 0)

        try? self.setTitleBar(titleBar)
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

        // ✅ host：单 tab 时显示 singleFrameHost，多 tab 时显示 tabView
        contentHost = Grid()
        contentHost.children.append(tabView)
        contentHost.children.append(singleFrameHost)

        // 默认先让 tabView 可见，后续 updateTabVisibility 决定
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
            if self.isSingleTabMode { return } // 单 tab 模式不看 TabView selection

            guard let tab = self.tabView.selectedItem as? TabViewItem else { return }
            if let raw = tab.tag as? String, let cat = self.findCategory(byRawValue: raw) {
                self.currentPageTextBlock.text = cat.text
                self.selectNavigationItem(for: cat)
            }
        }
    }

    // MARK: - 单/多 tab 显示逻辑（不搬 UIElement，只重建页面）

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
        // 单 tab 显示：用“页面新实例”，避免同一 UIElement 复挂导致崩溃
        let cat = currentSelectedCategoryFallback()
        singleFrameHost.content = createPage(for: cat)
        currentPageTextBlock.text = cat.text
        selectNavigationItem(for: cat)
    }

    private func currentSelectedCategoryFallback() -> any Category {
        if let tab = tabView.selectedItem as? TabViewItem,
           let raw = tab.tag as? String,
           let cat = findCategory(byRawValue: raw) {
            return cat
        }
        return viewModel.selectedCategory
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
            let home = MainCategory.home
            let tab = TabViewItem()
            tab.header = home.text
            tab.tag = home.rawValue

            let iconSource = FontIconSource()
            iconSource.glyph = home.glyph
            tab.iconSource = iconSource

            let frame = Frame()
            frame.content = createPage(for: home)
            tab.content = frame

            tab.isClosable = true

            tabView.tabItems.append(tab)
            tabView.selectedItem = tab
            currentPageTextBlock.text = home.text
        } else if tabView.selectedItem == nil {
            if let first = items.getAt(0) as? TabViewItem {
                tabView.selectedItem = first
            }
        }
    }

    private func showInCurrentTab(_ category: any Category) {
        ensureAtLeastOneTab()
        guard let tab = tabView.selectedItem as? TabViewItem else { return }

        tab.header = category.text
        tab.tag = category.rawValue

        if let main = category as? MainCategory {
            let iconSource = FontIconSource()
            iconSource.glyph = main.glyph
            tab.iconSource = iconSource
        } else {
            tab.iconSource = nil
        }

        let frame = getOrCreateFrame(in: tab)
        frame.content = createPage(for: category)

        // ✅ 单 tab 模式同时刷新 singleFrameHost（用新实例）
        if isSingleTabMode {
            singleFrameHost.content = createPage(for: category)
        }

        currentPageTextBlock.text = category.text
    }

    private func openNewTab(for category: any Category) {
        let tab = TabViewItem()
        tab.header = category.text
        tab.tag = category.rawValue

        if let main = category as? MainCategory {
            let iconSource = FontIconSource()
            iconSource.glyph = main.glyph
            tab.iconSource = iconSource
        }

        let frame = Frame()
        frame.content = createPage(for: category)
        tab.content = frame

        tab.isClosable = true

        tabView.tabItems.append(tab)
        tabView.selectedItem = tab
        currentPageTextBlock.text = category.text

        // ✅ 多 tab 了，显示 TabView
        updateTabVisibilityAndSingleHost()
    }

    // MARK: - 页面创建（保持你原来的 switch）

    private func createPage(for category: any Category) -> UIElement {
        switch category {
        case MainCategory.home:
            return HomePage()
        case MainCategory.all:
            return AllPage()
        
        case FundamentalsCategory.resources:
            return ResourcesPage()
        case FundamentalsCategory.style:
            return StylesPage()
        case FundamentalsCategory.templates:
            return TemplatesPage()
        case FundamentalsCategory.customUserControls:
            return CustomUserControlsPage()
        case FundamentalsCategory.binding:
            return BindingPage()
        case FundamentalsCategory.scratchPad:
            return ScratchPadPage()

        case CollectionsCategory.listView:
            return ListViewPage()
        case CollectionsCategory.flipView:
            return FlipViewPage()
        case CollectionsCategory.gridView:
            return GridViewPage()
        case CollectionsCategory.listBox:
            return ListBoxPage()
        case CollectionsCategory.pullToRefresh:
            return PullToRefreshPage()
        case CollectionsCategory.treeView:
            return TreeViewPage()

        case ScrollingCategory.annotatedScrollBar:
            return AnnotatedScrollBarPage()
        case ScrollingCategory.pipsPager:
            return PipsPagerPage()
        case ScrollingCategory.scrollView:
            return ScrollViewPage()
        case ScrollingCategory.scrollViewer:
            return ScrollViewerPage()
        case ScrollingCategory.semanticZoom:
            return SemanticZoomPage()

        case LayoutCategory.grid:
            return GridPage()
        case LayoutCategory.border:
            return BorderPage()
        case LayoutCategory.canvas:
            return CanvasPage()
        case LayoutCategory.expander:
            return ExpanderPage()
        case LayoutCategory.radioButtons:
            return RadioButtonsPage()
        case LayoutCategory.relativePanel:
            return RelativePanelPage()
        case LayoutCategory.stackPanel:
            return StackPanelPage()
        case LayoutCategory.variableSizedWrapGrid:
            return variableGridPage()
        case LayoutCategory.viewBox:
            return ViewBoxPage()

        case NavigationViewCategory.breadcrumbBar:
            return BreadcrumbBarPage()
        case NavigationViewCategory.navigationView:
            return NavigationViewPage()
        case NavigationViewCategory.pivot:
            return PivotPage()
        case NavigationViewCategory.selectorBar:
            return SelectorBarPage()
        case NavigationViewCategory.tabView:
            return TabViewPage()

        case MenusToolbarsCategory.appBarButton:
            return AppBarButtonPage()
        case MenusToolbarsCategory.appBarSeparator:
            return AppBarSeparatorPage()
        case MenusToolbarsCategory.appBarToggleButton:
            return AppBarToggleButtonPage()
        case MenusToolbarsCategory.commandBar:
            return CommandBarPage()
        case MenusToolbarsCategory.commandBarFlyout:
            return CommandBarFlyoutPage()

        case MediaCategory.image:
            return ImagePage()
        case MediaCategory.personPicture:
            return PersonPicturePage()
        case MediaCategory.webView2:
            return WebView2Page()

        case WindowingCategory.titleBar:
            return TitlebarPage()

        case SystemCategory.filePicker:
            return StoragePickersPage()
        case SystemCategory.appNotifications:
            return AppNotificationsPage()
        case SystemCategory.badgeNotifications:
            return BadgeNotificationsPage()

        case DialogsFlyoutsCategory.contentDialog:
            return ContentDialogPage()
        case DialogsFlyoutsCategory.flyout:
            return FlyoutPage()
        case DialogsFlyoutsCategory.popup:
            return PopupPage()
        case DialogsFlyoutsCategory.teachingTip:
            return TeachingTipPage()

        case DateTimeCategory.calendarDatePicker:
            return CalendarDatePickerPage()
        case DateTimeCategory.calendarView:
            return CalendarViewPage()
        case DateTimeCategory.datePicker:
            return DatePickerPage()
        case DateTimeCategory.timePicker:
            return TimePickerPage()

        case StatusInfoCategory.infoBadge:
            return InfoBadgePage()
        case StatusInfoCategory.infoBar:
            return InfoBarPage()
        case StatusInfoCategory.progressBar:
            return ProgressBarPage()
        case StatusInfoCategory.progressRing:
            return ProgressRingPage()
        case StatusInfoCategory.toolTip:
            return ToolTipPage()

        case TextCategory.autoSuggestBox:
            return AutoSuggestBoxPage()
        case TextCategory.numberBox:
            return NumberBoxPage()
        case TextCategory.passwordBox:
            return PasswordBoxPage()
        case TextCategory.richEditBox:
            return RichEditBoxPage()
        case TextCategory.richTextBlock:
            return RichTextBlockPage()
        case TextCategory.textBlock:
            return TextBlockPage()
        case TextCategory.textBox:
            return TextBoxPage()

        case StylesCategory.AcrylicBrush:
            return AcrylicBrushPage()
        case StylesCategory.animatedIcon:
            return AnimatedIconPage()
        case StylesCategory.compactSizing:
            return CompactSizingPage()
        case StylesCategory.iconElement:
            return IconElementPage()
        case StylesCategory.line:
            return LinePage()
        case StylesCategory.shape:
            return ShapePage()
        case StylesCategory.radialGradientBrush:
            return RadialGradientBrushPage()
        case StylesCategory.systemBackdropsMicaAcrylic:
            return SystemBackdropsPage()
        case StylesCategory.themeShadow:
            return ThemeShadowPage()

        case MotionCategory.animationInterop:
            return AnimationInteropPage()
        case MotionCategory.connectedAnimation:
            return ConnectedAnimationPage()
        case MotionCategory.easingFunctions:
            return EasingFunctionsPage()
        case MotionCategory.implicitTransitions:
            return ImplicitTransitionsPage()
        case MotionCategory.pageTransitions:
            return PageTransitionsPage()
        case MotionCategory.themeTransitions:
            return ThemeTransitionsPage()
        case MotionCategory.parallaxView:
            return ParallaxViewPage()

        default:
            return Grid()
        }
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

    private func selectNavigationItem(for category: any Category) {
        let raw = category.rawValue

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

    // MARK: - 导航历史（Back/Forward）

    private func updateNavButtonsState() {
        backButton.isEnabled = stack.count > 1
        forwardButton.isEnabled = !forwardStack.isEmpty
    }

    private func seedInitialHistoryIfNeeded() {
        if stack.isEmpty {
            stack = [viewModel.selectedCategory]
            forwardStack.removeAll()
            updateNavButtonsState()
        }
    }

    private func navigateBack() {
        guard stack.count > 1 else { return }
        let current = stack.removeLast()
        forwardStack.append(current)

        let previous = stack.last ?? MainCategory.home
        viewModel.navigateCommand.execute(parameter: previous)
        updateNavButtonsState()
    }

    private func navigateForward() {
        guard let next = forwardStack.popLast() else { return }
        stack.append(next)
        viewModel.navigateCommand.execute(parameter: next)
        updateNavButtonsState()
    }

    // MARK: - ViewModel 绑定（用 itemInvoked 做导航）

    func bindViewModel() {
        navigationView.itemInvoked.addHandler { [unowned self] _, args in
            guard let args = args else { self.openInNewTabRequested = false; return }
            guard let container = args.invokedItemContainer as? NavigationViewItem else { self.openInNewTabRequested = false; return }
            guard let tag = (container.tag as? Uri)?.host else { self.openInNewTabRequested = false; return }
            guard let category = self.findCategory(byRawValue: tag) else { self.openInNewTabRequested = false; return }
            if !category.canSelect { self.openInNewTabRequested = false; return }

            // ✅ 关键修复：第一次能回退到 Home（保证 stack 里有初始项）
            self.seedInitialHistoryIfNeeded()

            self.forwardStack.removeAll()
            self.stack.append(category)
            self.viewModel.navigateCommand.execute(parameter: category)
            self.updateNavButtonsState()
        }

        if let firstItem = navigationView.menuItems.first {
            navigationView.selectedItem = firstItem
        }

        viewModel.propertyChanged = { [unowned self] propertyName in
            self.handlePropertyChanged(propertyName)
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

        handlePropertyChanged("selectedCategory")
        seedInitialHistoryIfNeeded()
    }

    private func handlePropertyChanged(_ propertyName: String) {
        switch propertyName {
        case "selectedCategory":
            let item: any Category = viewModel.selectedCategory
            currentPageTextBlock.text = item.text

            if openInNewTabRequested {
                openNewTab(for: item)
            } else {
                showInCurrentTab(item)
            }

            // ✅ 用完就复位，避免影响下一次点击
            openInNewTabRequested = false

            selectNavigationItem(for: item)

            if isSingleTabMode {
                syncSingleHostFromSelectedTab()
            }

        default:
            break
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}