import WinUI
import WinAppSDK
import Foundation
import UWP
import WindowsFoundation

open class HomePage: Grid {
    // MARK: - Properties
    private var scrollViewer: ScrollViewer!
    private var rootGrid: Grid!
    
    // 数据源（先占位）
    private var recentlyVisitedSamplesList: [Any] = []
    private var recentlyAddedOrUpdatedSamplesList: [Any] = []
    private var favoriteSamplesList: [Any] = []
    
    // UI 组件
    private var recentSamplesPanel: StackPanel!
    private var favoriteSamplesPanel: StackPanel!
    private var tabContainer: StackPanel!
    
    // 顶部 Hero 区域中的横向卡片 ScrollViewer
    private var cardsScrollViewer: ScrollViewer!
    // 每次点箭头滚动的距离（大约一张卡片宽度）
    private let cardScrollAmount: Double = 280
    
    // MARK: - Initialization
    override public init() {
        super.init()
        setupView()
    }
    
    private func setupView() {
        // 设置当前 Grid 的行定义
        let rowDef = RowDefinition()
        rowDef.height = GridLength(value: 1, gridUnitType: .star)
        self.rowDefinitions.append(rowDef)
        
        // 创建并添加内容
        let content = createScrollViewer()
        self.children.append(content)
    }
    
    // MARK: - Create Main View
    private func createScrollViewer() -> ScrollViewer {
        scrollViewer = ScrollViewer()
        scrollViewer.cornerRadius = CornerRadius(topLeft: 0, topRight: 0, bottomRight: 0, bottomLeft: 0)
        scrollViewer.verticalScrollBarVisibility = .auto
        
        rootGrid = createRootGrid()
        scrollViewer.content = rootGrid
        
        return scrollViewer
    }
    
    private func createRootGrid() -> Grid {
        let grid = Grid()
        
        // 定义一行用于主内容
        let row1 = RowDefinition()
        row1.height = GridLength(value: 1, gridUnitType: .star)
        grid.rowDefinitions.append(row1)
        
        // 创建主面板
        let mainPanel = createMainPanel()
        try? Grid.setRow(mainPanel, 0)
        grid.children.append(mainPanel)
        
        return grid
    }
    
    // MARK: - Create Main Panel
    private func createMainPanel() -> StackPanel {
        let panel = StackPanel()
        panel.padding = Thickness(left: 40, top: 40, right: 40, bottom: 40)
        panel.spacing = 24
        
        // 顶部 Hero 区域（图片 + 渐变 + 卡片）
        panel.children.append(createHeroSection())
        // 后面的内容区域
        panel.children.append(createTabButtons())
        panel.children.append(createRecentSection())
        panel.children.append(createUpdatedSection())
        
        return panel
    }
    
    // MARK: - Header & Search
    private func createHeader() -> StackPanel {
        let headerPanel = StackPanel()
        headerPanel.spacing = 8
        
        let sdkText = TextBlock()
        // 修复：硬编码版本号，不使用 ReleaseInfo.asString
        sdkText.text = "Windows App SDK 1.7"
        sdkText.fontSize = 14
        sdkText.opacity = 0.6
        headerPanel.children.append(sdkText)
        
        let titleText = TextBlock()
        titleText.text = "Swift WinUI 3 Gallery"
        titleText.fontSize = 40
        headerPanel.children.append(titleText)
        
        return headerPanel
    }
    
    private func createSearchBox() -> AutoSuggestBox {
        let searchBox = AutoSuggestBox()
        searchBox.placeholderText = "Search controls and samples..."
        searchBox.width = 320
        searchBox.horizontalAlignment = .left
        searchBox.margin = Thickness(left: 0, top: 20, right: 0, bottom: 20)
        return searchBox
    }
    
    // Hero 里用的搜索框，拉伸一点
    private func createSearchBoxInHero() -> AutoSuggestBox {
        let searchBox = createSearchBox()
        searchBox.horizontalAlignment = .stretch
        searchBox.margin = Thickness(left: 0, top: 12, right: 260, bottom: 0)
        return searchBox
    }
    
    // MARK: - Hero Section：顶部图片 + 渐变 + 卡片
    private func createHeroSection() -> Border {
        let container = Border()
        container.height = 400
        container.margin = Thickness(left: 0, top: 0, right: 0, bottom: 32)
        container.cornerRadius = CornerRadius(topLeft: 12, topRight: 12, bottomRight: 12, bottomLeft: 12)
        
        let heroGrid = Grid()
        container.child = heroGrid
        
        // 背景图片（把 HomeHero.png 换成你自己的也行）
        let bgImage = Image()
        bgImage.stretch = .uniformToFill
        
        if let imagePath = Bundle.module.path(forResource: "HomeHero", ofType: "png", inDirectory: "Assets/") {
            let uri = Uri(imagePath)
            let bitmap = BitmapImage()
            bitmap.uriSource = uri
            bgImage.source = bitmap
        }
        heroGrid.children.append(bgImage)
        
        // 底部渐变层：从透明过渡到白色/透明
        let gradientBorder = Border()
        gradientBorder.horizontalAlignment = .stretch
        gradientBorder.verticalAlignment = .stretch
        
        let gradientBrush = LinearGradientBrush()
        gradientBrush.startPoint = Point(x: 0.0, y: 0.0)
        gradientBrush.endPoint = Point(x: 0.0, y: 1.0)
        
        // 顶部：黑色
        let blackStop = GradientStop()
        var black = UWP.Color()
        black.a = 255
        black.r = 0
        black.g = 0
        black.b = 0
        blackStop.color = black
        blackStop.offset = 0.0
        
        // 中间：蓝色
        let blueStop = GradientStop()
        var blue = UWP.Color()
        blue.a = 255
        blue.r = 34
        blue.g = 31
        blue.b = 137
        blueStop.color = blue
        blueStop.offset = 0.5
        
        // 底部：半透明黑
        let transparentStop = GradientStop()
        var transparent = UWP.Color()
        transparent.a = 255
        transparent.r = 0
        transparent.g = 0
        transparent.b = 0
        transparentStop.color = transparent
        transparentStop.offset = 0.7
        
        // 最底部：完全透明
        let transparentStop2 = GradientStop()
        var transparent2 = UWP.Color()
        transparent2.a = 0
        transparent2.r = 255
        transparent2.g = 255
        transparent2.b = 255
        transparentStop2.color = transparent2
        transparentStop2.offset = 1.0
        
        gradientBrush.gradientStops.append(blackStop)
        gradientBrush.gradientStops.append(blueStop)
        gradientBrush.gradientStops.append(transparentStop)
        gradientBrush.gradientStops.append(transparentStop2)
        
        gradientBorder.background = gradientBrush
        
        heroGrid.children.append(gradientBorder)
        
        // 前景内容：标题 + 搜索框 + 卡片行
        let contentPanel = StackPanel()
        contentPanel.orientation = .vertical
        contentPanel.spacing = 16
        contentPanel.horizontalAlignment = .stretch
        contentPanel.verticalAlignment = .stretch
        contentPanel.margin = Thickness(left: 40, top: 24, right: 40, bottom: 24)
        
        contentPanel.children.append(createHeader())
        contentPanel.children.append(createSearchBoxInHero())
        contentPanel.children.append(createCardsRow())
        
        heroGrid.children.append(contentPanel)
        
        return container
    }
    
    // Hero 底部横向卡片行（带左右箭头）
    private func createCardsRow() -> Grid {
        let grid = Grid()
        grid.margin = Thickness(left: 0, top: 16, right: 0, bottom: 0)
        
        // 三列：左箭头 / 中间滚动区域 / 右箭头
        let colLeft = ColumnDefinition()
        colLeft.width = GridLength(value: 40, gridUnitType: .pixel)
        grid.columnDefinitions.append(colLeft)
        
        let colCenter = ColumnDefinition()
        colCenter.width = GridLength(value: 1, gridUnitType: .star)
        grid.columnDefinitions.append(colCenter)
        
        let colRight = ColumnDefinition()
        colRight.width = GridLength(value: 40, gridUnitType: .pixel)
        grid.columnDefinitions.append(colRight)
        
        let rowDef = RowDefinition()
        rowDef.height = GridLength(value: 160, gridUnitType: .pixel)
        grid.rowDefinitions.append(rowDef)
        
        // 左箭头按钮
        let leftButton = Button()
        leftButton.content = "<"
        leftButton.width = 32
        leftButton.height = 32
        leftButton.horizontalAlignment = .center
        leftButton.verticalAlignment = .center
        leftButton.click.addHandler { [weak self] _, _ in
            guard let self = self else { return }
            self.scrollCards(by: -self.cardScrollAmount)
        }
        try? Grid.setColumn(leftButton, 0)
        try? Grid.setRow(leftButton, 0)
        grid.children.append(leftButton)
        
        // 右箭头按钮
        let rightButton = Button()
        rightButton.content = ">"
        rightButton.width = 32
        rightButton.height = 32
        rightButton.horizontalAlignment = .center
        rightButton.verticalAlignment = .center
        rightButton.click.addHandler { [weak self] _, _ in
            guard let self = self else { return }
            self.scrollCards(by: self.cardScrollAmount)
        }
        try? Grid.setColumn(rightButton, 2)
        try? Grid.setRow(rightButton, 0)
        grid.children.append(rightButton)
        
        // 中间：水平 ScrollViewer + 横向 StackPanel 放卡片
        cardsScrollViewer = ScrollViewer()
        cardsScrollViewer.horizontalScrollBarVisibility = .hidden
        cardsScrollViewer.verticalScrollBarVisibility = .disabled
        cardsScrollViewer.horizontalScrollMode = .enabled
        cardsScrollViewer.verticalScrollMode = .disabled
        cardsScrollViewer.margin = Thickness(left: 8, top: 0, right: 8, bottom: 0)
        
        let panel = StackPanel()
        panel.orientation = .horizontal
        panel.spacing = 12
        
        let cards = [
            ("Getting started", "Get started with WinUI and explore detailed documentation.", "📘"),
            ("Design", "Guidelines and toolkits for creating stunning WinUI experiences.", "🪟"),
            ("WinUI on GitHub", "Explore the WinUI source code and repository.", "🐙"),
            ("Community Toolkit", "A collection of helper functions, controls, and app services.", "🧰")
        ]
        
        for card in cards {
            let cardButton = createCard(title: card.0, description: card.1, icon: card.2)
            panel.children.append(cardButton)
        }
        
        cardsScrollViewer.content = panel
        
        try? Grid.setColumn(cardsScrollViewer, 1)
        try? Grid.setRow(cardsScrollViewer, 0)
        grid.children.append(cardsScrollViewer)
        
        return grid
    }
    
    // 备用：原来的 4 列静态卡片布局（现在没用）
    private func createCardsGrid() -> Grid {
        let grid = Grid()
        grid.margin = Thickness(left: 0, top: 0, right: 0, bottom: 32)
        
        for _ in 0..<4 {
            let colDef = ColumnDefinition()
            colDef.width = GridLength(value: 1, gridUnitType: .star)
            grid.columnDefinitions.append(colDef)
        }
        
        let rowDef = RowDefinition()
        rowDef.height = GridLength(value: 160, gridUnitType: .pixel)
        grid.rowDefinitions.append(rowDef)
        
        let cards = [
            ("Getting started", "Get started with WinUI and explore detailed documentation.", "📘"),
            ("Design", "Guidelines and toolkits for creating stunning WinUI experiences.", "🪟"),
            ("WinUI on GitHub", "Explore the WinUI source code and repository.", "🐙"),
            ("Community Toolkit", "A collection of helper functions, controls, and app services.", "🧰")
        ]
        
        for (index, card) in cards.enumerated() {
            let cardButton = createCard(title: card.0, description: card.1, icon: card.2)
            try? Grid.setColumn(cardButton, Int32(index))
            try? Grid.setRow(cardButton, 0)
            grid.children.append(cardButton)
        }
        
        return grid
    }
    
    private func createCard(title: String, description: String, icon: String) -> Button {
        let button = Button()
        button.horizontalAlignment = .stretch
        button.verticalAlignment = .stretch
        button.margin = Thickness(left: 0, top: 0, right: 12, bottom: 0)
        button.padding = Thickness(left: 20, top: 20, right: 20, bottom: 20)
        button.width = 260
        button.height = 160
        
        let panel = StackPanel()
        panel.spacing = 12
        
        let iconText = TextBlock()
        iconText.text = icon
        iconText.fontSize = 32
        panel.children.append(iconText)
        
        let titleText = TextBlock()
        titleText.text = title
        titleText.fontSize = 16
        panel.children.append(titleText)
        
        let descText = TextBlock()
        descText.text = description
        descText.fontSize = 12
        descText.textWrapping = .wrap
        descText.opacity = 0.6
        panel.children.append(descText)
        
        button.content = panel
        return button
    }
    
    // MARK: - Tab Buttons
    private func createTabButtons() -> StackPanel {
        let panel = StackPanel()
        panel.orientation = .horizontal
        panel.spacing = 12
        panel.margin = Thickness(left: 0, top: 0, right: 0, bottom: 16)
        panel.horizontalAlignment = .center
        
        let recentButton = Button()
        recentButton.content = "Recent"
        recentButton.padding = Thickness(left: 16, top: 8, right: 16, bottom: 8)
        recentButton.cornerRadius = CornerRadius(topLeft: 16, topRight: 16, bottomRight: 16, bottomLeft: 16)
        recentButton.click.addHandler { [weak self] _, _ in
            self?.showRecentContent()
        }
        panel.children.append(recentButton)
        
        let favoritesButton = Button()
        favoritesButton.content = "Favorites"
        favoritesButton.padding = Thickness(left: 16, top: 8, right: 16, bottom: 8)
        favoritesButton.cornerRadius = CornerRadius(topLeft: 16, topRight: 16, bottomRight: 16, bottomLeft: 16)
        favoritesButton.click.addHandler { [weak self] _, _ in
            self?.showFavoritesContent()
        }
        panel.children.append(favoritesButton)
        
        return panel
    }
    
    // MARK: - Recent Section
    private func createRecentSection() -> StackPanel {
        let section = StackPanel()
        section.spacing = 16
        section.margin = Thickness(left: 0, top: 0, right: 0, bottom: 32)
        
        let header = TextBlock()
        header.text = "Recently visited"
        header.fontSize = 20
        section.children.append(header)
        
        let itemsPanel = StackPanel()
        itemsPanel.orientation = .horizontal
        itemsPanel.spacing = 12
        
        let colorItem = createRecentItem(
            title: "Color",
            description: "Balanced color design creates clarity and aesthetic harmony.",
            icon: "🎨"
        )
        itemsPanel.children.append(colorItem)
        
        let resourcesItem = createRecentItem(
            title: "Resources",
            description: "Reusable definitions for shared values to ensure consistency.",
            icon: "💾"
        )
        itemsPanel.children.append(resourcesItem)
        
        section.children.append(itemsPanel)
        
        return section
    }
    
    private func createRecentItem(title: String, description: String, icon: String) -> Border {
        let border = Border()
        border.width = 280
        border.height = 100
        border.padding = Thickness(left: 16, top: 16, right: 16, bottom: 16)
        
        let panel = StackPanel()
        panel.spacing = 8
        
        let headerPanel = StackPanel()
        headerPanel.orientation = .horizontal
        headerPanel.spacing = 12
        
        let iconText = TextBlock()
        iconText.text = icon
        iconText.fontSize = 24
        headerPanel.children.append(iconText)
        
        let titleText = TextBlock()
        titleText.text = title
        titleText.fontSize = 16
        headerPanel.children.append(titleText)
        
        panel.children.append(headerPanel)
        
        let descText = TextBlock()
        descText.text = description
        descText.fontSize = 12
        descText.textWrapping = .wrap
        descText.opacity = 0.6
        panel.children.append(descText)
        
        border.child = panel
        return border
    }
    
    // MARK: - Recently Updated Section
    private func createUpdatedSection() -> StackPanel {
        let section = StackPanel()
        section.spacing = 16
        
        let header = TextBlock()
        header.text = "Recently added or updated"
        header.fontSize = 20
        section.children.append(header)
        
        let gridView = createSamplesGridView()
        section.children.append(gridView)
        
        return section
    }
    
    private func createSamplesGridView() -> GridView {
        let gridView = GridView()
        gridView.isItemClickEnabled = true
        gridView.selectionMode = .none
        
        gridView.itemClick.addHandler { [weak self] sender, args in
            guard let args = args else { return }
            self?.onItemClick(sender, args)
        }
        
        return gridView
    }
    
    // MARK: - 轮播滚动辅助
    private func scrollCards(by delta: Double) {
        guard let scrollViewer = cardsScrollViewer else { return }
        let current = scrollViewer.horizontalOffset
        let maxOffset = scrollViewer.scrollableWidth
        let target = max(0, min(maxOffset, current + delta))
        try? scrollViewer.scrollToHorizontalOffset(target)
    }
    
    // MARK: - Events
    private func showRecentContent() {
        print("Show recent content")
        // TODO: 实现切换到 Recent 内容的逻辑
    }
    
    private func showFavoritesContent() {
        print("Show favorites content")
        // TODO: 实现切换到 Favorites 内容的逻辑
    }
    
    private func onItemClick(_ sender: Any?, _ args: ItemClickEventArgs) {
        print("Item clicked")
        // TODO: 处理项点击事件
    }
}