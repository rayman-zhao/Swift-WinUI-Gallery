import Foundation
import UWP
import WinAppSDK
import WindowsFoundation
import WinUI

class MainWindow: Window, @unchecked Sendable {

    private let viewModel: MainWindowViewModel

    private static let isMSIX: Bool = ProcessInfo.processInfo.environment["APPX_PACKAGE_FAMILY_NAME"] != nil

    private var rootGrid: Grid
    private var titleBar: TitleBar?
    private var navigationView: NavigationView
    private var tabView: TabView

    private var singleFrameHost: Frame
    private var contentHost: Grid
    private var isSingleTabMode: Bool = false

    private var controlsSearchBox: AutoSuggestBox
    private var currentPageTextBlock: TextBlock

    private var forwardStack: [any Category] = []
    private var forwardButton: Button
    private var backButton: Button
    private var stack: [any Category] = []
    
    private var tbCurrentPageHost: Border?
    private var tbDragGap: Border?
    private var tbDragFiller: Border?
    private var tbNavButtonsHost: StackPanel?
    private var tbContentGrid: Grid?
    private var openInNewTabRequested: Bool = false

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
            return
        }

        setupTitleBar()
        setupNavigationView()
    }
    private func setupTitleBar() {
        let appTitleBar = Grid()
        appTitleBar.name = "AppTitleBar"
        appTitleBar.height = 48
        appTitleBar.verticalAlignment = .stretch
        appTitleBar.horizontalAlignment = .stretch

        appTitleBar.background = SolidColorBrush(Color(a: 0, r: 0, g: 0, b: 0))

        let captionButtonsReservedWidth: Double = 140
        appTitleBar.padding = Thickness(left: 0, top: 0, right: captionButtonsReservedWidth, bottom: 0)

        let c0 = ColumnDefinition(); c0.width = GridLength(value: 1, gridUnitType: .auto)
        let c1 = ColumnDefinition(); c1.width = GridLength(value: 1, gridUnitType: .auto)
        let c2 = ColumnDefinition(); c2.width = GridLength(value: 1, gridUnitType: .star)
        let c3 = ColumnDefinition(); c3.width = GridLength(value: 1, gridUnitType: .auto)
        let c4 = ColumnDefinition(); c4.width = GridLength(value: 1, gridUnitType: .auto)
        appTitleBar.columnDefinitions.append(c0)
        appTitleBar.columnDefinitions.append(c1)
        appTitleBar.columnDefinitions.append(c2)
        appTitleBar.columnDefinitions.append(c3)
        appTitleBar.columnDefinitions.append(c4)

        func makeMdl2Icon(_ glyph: String, fontSize: Double = 14) -> FontIcon {
            let icon = FontIcon()
            icon.glyph = glyph
            icon.fontSize = fontSize
            icon.verticalAlignment = .center
            return icon
        }

        let paneButton = Button()
        paneButton.content = makeMdl2Icon("\u{E700}")
        paneButton.verticalAlignment = .center
        paneButton.margin = Thickness(left: 8, top: 0, right: 4, bottom: 0)
        paneButton.padding = Thickness(left: 10, top: 6, right: 10, bottom: 6)
        paneButton.isTabStop = false
        let transparent = SolidColorBrush(Color(a: 0, r: 0, g: 0, b: 0))
        paneButton.useSystemFocusVisuals = false
        paneButton.focusVisualPrimaryBrush = transparent
        paneButton.focusVisualSecondaryBrush = transparent
        paneButton.focusVisualPrimaryThickness = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        paneButton.focusVisualSecondaryThickness = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        paneButton.focusVisualMargin = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        paneButton.resources["FocusVisualPrimaryBrush"] = transparent
        paneButton.resources["FocusVisualSecondaryBrush"] = transparent
        paneButton.resources["FocusVisualPrimaryThickness"] = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        paneButton.resources["FocusVisualSecondaryThickness"] = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        paneButton.resources["FocusVisualMargin"] = Thickness(left: 0, top: 0, right: 0, bottom: 0)

        paneButton.background = transparent
        paneButton.borderBrush = transparent

        paneButton.resources["ButtonBackground"] = transparent
        paneButton.resources["ButtonBackgroundPointerOver"] = transparent
        paneButton.resources["ButtonBackgroundPressed"] = transparent
        paneButton.resources["ButtonBackgroundDisabled"] = transparent

        paneButton.resources["ButtonBorderBrush"] = transparent
        paneButton.resources["ButtonBorderBrushPointerOver"] = transparent
        paneButton.resources["ButtonBorderBrushPressed"] = transparent
        paneButton.resources["ButtonBorderBrushDisabled"] = transparent

        paneButton.click.addHandler { [weak self] _, _ in
            guard let self = self else { return }
            self.navigationView.isPaneOpen.toggle()
        }

        appTitleBar.children.append(paneButton)
        try? Grid.setColumn(paneButton, 0)

        let subtitleReservedWidth: Double = 200
        let navButtonsLeftGap: Double = 0

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
        appIcon.isHitTestVisible = false

        let titleText = TextBlock()
        titleText.text = "Swift WinUI 3 Gallery"
        titleText.fontSize = 14
        titleText.verticalAlignment = .center
        titleText.isHitTestVisible = false

        currentPageTextBlock.fontSize = 12
        currentPageTextBlock.opacity = 0.75
        currentPageTextBlock.verticalAlignment = .center
        currentPageTextBlock.text = ""
        currentPageTextBlock.width = subtitleReservedWidth
        currentPageTextBlock.textTrimming = .characterEllipsis
        currentPageTextBlock.margin = Thickness(left: 8, top: 0, right: 0, bottom: 0)
        currentPageTextBlock.isHitTestVisible = false

        backButton.content = makeMdl2Icon("\u{E72B}")
        forwardButton.content = makeMdl2Icon("\u{E72A}")
        backButton.verticalAlignment = .center
        forwardButton.verticalAlignment = .center

        backButton.margin = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        forwardButton.margin = Thickness(left: 0, top: 0, right: 0, bottom: 0)
        backButton.padding = Thickness(left: 10, top: 6, right: 10, bottom: 6)
        forwardButton.padding = Thickness(left: 10, top: 6, right: 10, bottom: 6)

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

        appTitleBar.children.append(leftHeaderStack)
        try? Grid.setColumn(leftHeaderStack, 1)

        controlsSearchBox.name = "controlsSearchBox"
        controlsSearchBox.placeholderText = "Search controls and samples..."
        controlsSearchBox.verticalAlignment = .center
        controlsSearchBox.minWidth = 320

        appTitleBar.children.append(controlsSearchBox)
        try? Grid.setColumn(controlsSearchBox, 3)

        let avatar = Border()
        avatar.width = 32
        avatar.height = 32
        avatar.cornerRadius = CornerRadius(topLeft: 16, topRight: 16, bottomRight: 16, bottomLeft: 16)
        avatar.verticalAlignment = .center
        avatar.margin = Thickness(left: 12, top: 0, right: 12, bottom: 0)
        avatar.background = SolidColorBrush(Color(a: 255, r: 240, g: 240, b: 240))
        avatar.isHitTestVisible = false

        let avatarText = TextBlock()
        avatarText.text = "PP"
        avatarText.verticalAlignment = .center
        avatarText.horizontalAlignment = .center
        avatarText.fontSize = 12
        avatarText.isHitTestVisible = false
        avatar.child = avatarText

        appTitleBar.children.append(avatar)
        try? Grid.setColumn(avatar, 4)

        rootGrid.children.append(appTitleBar)
        try? Grid.setRow(appTitleBar, 0)

        try? self.setTitleBar(appTitleBar)
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


    private func setupMSIXFallbackUI() {
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

    private func updateCtrlFlagFromPointer(_ args: PointerRoutedEventArgs?) {
        guard let args = args else { return }
        let raw = Int(args.keyModifiers.rawValue)
        openInNewTabRequested = (raw & 0x1) != 0
    }

    private func updateTitleBarDragRectangles() {
        guard let appWindow = self.appWindow else { return }
        guard let currentPageHost = self.tbCurrentPageHost,
            let dragGap = self.tbDragGap,
            let dragFiller = self.tbDragFiller else { return }

        let scale = Double(self.rootGrid.xamlRoot?.rasterizationScale ?? 1.0)

        func boundsInWindowPx(_ fe: FrameworkElement) -> RectInt32? {
            do {
                // 注意：transformToVisual 是 throws，并且返回 GeneralTransform?
                guard let t = try fe.transformToVisual(nil) else { return nil }

                // 注意：transformPoint 在你这个绑定里也是 throws
                let p = try t.transformPoint(Point(x: 0, y: 0))

                let wD = Double(fe.actualWidth) * scale
                let hD = Double(fe.actualHeight) * scale
                if wD <= 1 || hD <= 1 { return nil }

                // p.x / p.y 是 Float，所以要转 Double 再乘 scale
                let x = Int32(Double(p.x) * scale)
                let y = Int32(Double(p.y) * scale)
                let w = Int32(wD)
                let h = Int32(hD)

                return RectInt32(x: x, y: y, width: w, height: h)
            } catch {
                return nil
            }
        }

        var rects: [RectInt32] = []
        if let r = boundsInWindowPx(currentPageHost) { rects.append(r) }
        if let r = boundsInWindowPx(dragGap) { rects.append(r) }
        if let r = boundsInWindowPx(dragFiller) { rects.append(r) }

        guard !rects.isEmpty else { return }

        // setDragRectangles 也可能 throws，保险起见用 try?
        try? appWindow.titleBar.setDragRectangles(rects)
    }


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
        navigationView.compactModeThresholdWidth = 0 // 始终令navigationView不消失
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
            if let raw = tab.tag as? String, let cat = self.findCategory(byRawValue: raw) {
                self.currentPageTextBlock.text = cat.text
                self.selectNavigationItem(for: cat)
            }
        }
    }


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

        updateTabVisibilityAndSingleHost()
    }


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


    func bindViewModel() {
        navigationView.itemInvoked.addHandler { [unowned self] _, args in
            guard let args = args else { self.openInNewTabRequested = false; return }
            guard let container = args.invokedItemContainer as? NavigationViewItem else { self.openInNewTabRequested = false; return }
            guard let tag = (container.tag as? Uri)?.host else { self.openInNewTabRequested = false; return }
            guard let category = self.findCategory(byRawValue: tag) else { self.openInNewTabRequested = false; return }
            if !category.canSelect { self.openInNewTabRequested = false; return }

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