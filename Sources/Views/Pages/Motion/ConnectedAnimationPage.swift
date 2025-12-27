import WinUI
import Foundation
import WindowsFoundation
import UWP

final class ConnectedAnimationPage: Grid {

    private let pageGrid = Grid()
    private let headerGrid = Grid()
    private let exampleStackPanel = StackPanel()

    private var sample3Host: SimpleConnectedAnimationHost?
    private var configurationPanel: RadioButtons?

    override init() {
        super.init()

        setupRootLayout()
        setupHeader()

        setupExample1_ListToDetail()
        setupExample2_CardToDetail()
        setupExample3_SimpleConnectedAnimation()

        self.children.append(pageGrid)
    }

    private func setupRootLayout() {
        let rowHeader = RowDefinition()
        rowHeader.height = GridLength(value: 1, gridUnitType: .auto)
        let rowBody = RowDefinition()
        rowBody.height = GridLength(value: 1, gridUnitType: .star)

        pageGrid.rowDefinitions.append(rowHeader)
        pageGrid.rowDefinitions.append(rowBody)

        pageGrid.children.append(headerGrid)

        let scroll = ScrollViewer()
        try? Grid.setRow(scroll, 1)
        scroll.padding = Thickness(left: 36, top: 0, right: 36, bottom: 24)
        scroll.verticalScrollBarVisibility = .auto
        scroll.horizontalScrollBarVisibility = .disabled

        exampleStackPanel.orientation = .vertical
        exampleStackPanel.spacing = 12
        exampleStackPanel.margin = Thickness(left: 0, top: 24, right: 0, bottom: 36)

        scroll.content = exampleStackPanel
        pageGrid.children.append(scroll)
    }

    private func setupHeader() {
        let controlInfo = ControlInfo(
            title: "Connected animations",
            apiNamespace: "Microsoft.UI.Xaml.Media.Animation",
            baseClasses: [
                "Object",
                "DependencyObject",
                "UIElement",
                "FrameworkElement"
            ],
            docs: [
                ControlInfoDocLink(
                    title: "ConnectedAnimationService - API",
                    uri: "https://learn.microsoft.com/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.media.animation.connectedanimationservice"
                )
            ]
        )

        let pageHeader = PageHeader(item: controlInfo)
        pageHeader.themeButtonVisibility = .visible
        pageHeader.margin = Thickness(left: 36, top: 36, right: 36, bottom: 0)
        headerGrid.children.append(pageHeader)
    }

    private func setupExample1_ListToDetail() {
        let host = ListToDetailConnectedAnimationHost()

        let example = ControlExample()
        example.headerText = "A connected animation between a list page and a detail page"
        example.example = host

        exampleStackPanel.children.append(example.view)
    }

    private func setupExample2_CardToDetail() {
        let host = CardToDetailConnectedAnimationHost()

        let example = ControlExample()
        example.headerText = "A connected animation between a card and a detail view"
        example.example = host

        exampleStackPanel.children.append(example.view)
    }

    private func setupExample3_SimpleConnectedAnimation() {
        let host = SimpleConnectedAnimationHost()
        self.sample3Host = host

        let optionsPanel = StackPanel()
        optionsPanel.orientation = .vertical
        optionsPanel.spacing = 8
        optionsPanel.width = 220

        let navigateBtn = Button()
        navigateBtn.content = "Navigate"
        optionsPanel.children.append(navigateBtn)

        let label = TextBlock()
        label.margin = Thickness(left: 0, top: 6, right: 0, bottom: 0)
        label.text = "Configurations"
        optionsPanel.children.append(label)

        let radios = RadioButtons()
        radios.items.append("Default")
        radios.items.append("Gravity")
        radios.items.append("Direct")
        radios.items.append("Basic")
        radios.selectedIndex = 0
        optionsPanel.children.append(radios)
        self.configurationPanel = radios

        navigateBtn.click.addHandler { [weak self] _, _ in
            guard let self else { return }
            let idx = Int(self.configurationPanel?.selectedIndex ?? 0)
            let name: String
            switch idx {
            case 1: name = "Gravity"
            case 2: name = "Direct"
            case 3: name = "Basic"
            default: name = "Default"
            }
            self.sample3Host?.toggle(configurationName: name)
        }

        let example = ControlExample()
        example.headerText = "A simple connected animation"
        example.example = host
        example.options = optionsPanel

        exampleStackPanel.children.append(example.view)
    }
}

private enum MediaLoader {

    static func makeLandscapeImage(index: Int) -> BitmapImage? {
        let name = "LandscapeImage\(index)"
        return makeBitmapImage(resourceName: name, ofType: "jpg", inDirectory: "Assets/SampleMedia")
    }

    static func makeBitmapImage(resourceName: String, ofType: String, inDirectory: String) -> BitmapImage? {
        guard let path = Bundle.module.path(forResource: resourceName, ofType: ofType, inDirectory: inDirectory) else {
            print("Bundle.module.path failed: \(inDirectory)/\(resourceName).\(ofType)")
            return nil
        }
        let fileUrl = URL(fileURLWithPath: path)
        let uri = Uri(fileUrl.absoluteString)
        let bitmap = BitmapImage(uri)
        return bitmap
    }

    static func makeImageControl(landscapeIndex: Int, width: Double, height: Double) -> Image {
        let image = Image()
        image.width = width
        image.height = height
        image.stretch = .uniformToFill
        image.horizontalAlignment = .left

        if let bitmap = makeLandscapeImage(index: landscapeIndex) {
            image.source = bitmap
        }
        return image
    }
}

// ============================================================
// Sample data
// ============================================================

private struct CustomDataObject {
    let title: String
    let imageIndex: Int
    let views: String
    let likes: String
    let description: String

    static func makeObjects(count: Int = 7) -> [CustomDataObject] {
        let dummyTexts: [String] = [
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque eget enim sodales sapien vestibulum consequat.",
            "Nullam eget mattis metus. Donec pharetra, magna ipsum gravida nibh, vitae lobortis ante odio vel quam.",
            "Quisque accumsan pretium ligula in faucibus. Fusce condimentum luctus nisi, in elementum ante tincidunt nec.",
            "Aenean in nisl at elit venenatis blandit ut vitae sem. Ut cursus tortor at metus lacinia dapibus.",
            "Ut consequat magna luctus justo egestas vehicula. Integer pharetra risus libero, et posuere justo mattis et.",
            "Proin malesuada, libero vitae aliquam venenatis, efficitur erat nunc non mauris. Suspendisse at sodales erat.",
            "Duis facilisis, quam ut laoreet commodo, elit ex aliquet massa, non varius tellus lectus et nunc."
        ]

        var out: [CustomDataObject] = []
        out.reserveCapacity(count)
        for i in 0..<count {
            out.append(
                CustomDataObject(
                    title: "Item \(i + 1)",
                    imageIndex: (i % 7) + 1,
                    views: String(Int.random(in: 100...999)),
                    likes: String(Int.random(in: 10...99)),
                    description: dummyTexts[i % dummyTexts.count]
                )
            )
        }
        return out
    }
}

// ============================================================
// Sample 1: List -> Detail（纵向列表滚动 + 左图右文 + 对齐修正）
// ============================================================

private final class ListToDetailConnectedAnimationHost: Grid {

    private let objects = CustomDataObject.makeObjects(count: 7)

    private let listRoot = Grid()
    private let detailRoot = Grid()

    private var thumbs: [Int: Image] = [:]
    private var currentIndex: Int = 0

    private let detailImage = Image()
    private let titleText = TextBlock()
    private let metaText = TextBlock()
    private let descText = TextBlock()
    private let backButton = Button()

    override init() {
        super.init()

        self.minWidth = 520
        self.height = 520

        self.children.append(listRoot)
        self.children.append(detailRoot)

        buildList()
        buildDetail()
        showList()
    }

    private func showList() {
        listRoot.visibility = .visible
        detailRoot.visibility = .collapsed
    }

    private func showDetail() {
        listRoot.visibility = .collapsed
        detailRoot.visibility = .visible
    }

    private func clearChildren(_ g: Grid) {
        while g.children.count > 0 {
            _ = g.children.removeAt(0)
        }
    }


    private func buildList() {
        clearChildren(listRoot)
        thumbs.removeAll()

        let rootGrid = Grid()
        rootGrid.margin = Thickness(left: 0, top: 6, right: 0, bottom: 0)

        let r0 = RowDefinition()
        r0.height = GridLength(value: 1, gridUnitType: .auto)
        let r1 = RowDefinition()
        r1.height = GridLength(value: 1, gridUnitType: .star)

        rootGrid.rowDefinitions.append(r0)
        rootGrid.rowDefinitions.append(r1)

        let tip = TextBlock()
        tip.text = "Click an item to animate to details."
        _ = try? Grid.setRow(tip, 0)
        rootGrid.children.append(tip)

        let scroll = ScrollViewer()
        scroll.verticalScrollBarVisibility = .auto
        scroll.horizontalScrollBarVisibility = .disabled
        scroll.margin = Thickness(left: 0, top: 10, right: 0, bottom: 0)
        _ = try? Grid.setRow(scroll, 1)
        rootGrid.children.append(scroll)

        let listStack = StackPanel()
        listStack.orientation = .vertical
        listStack.spacing = 14

        for (idx, obj) in objects.enumerated() {

            let btn = Button()
            btn.horizontalAlignment = .stretch

            btn.horizontalContentAlignment = .stretch
            btn.verticalContentAlignment = .stretch

            let itemGrid = Grid()
            itemGrid.columnSpacing = 16

            let colImg = ColumnDefinition()
            colImg.width = GridLength(value: 1, gridUnitType: .auto)
            let colText = ColumnDefinition()
            colText.width = GridLength(value: 1, gridUnitType: .star)
            itemGrid.columnDefinitions.append(colImg)
            itemGrid.columnDefinitions.append(colText)

            let img = MediaLoader.makeImageControl(landscapeIndex: obj.imageIndex, width: 200, height: 120)
            img.horizontalAlignment = .left
            img.verticalAlignment = .top
            thumbs[idx] = img
            _ = try? Grid.setColumn(img, 0)
            itemGrid.children.append(img)

            let textStack = StackPanel()
            textStack.orientation = .vertical
            textStack.spacing = 6
            textStack.verticalAlignment = .top

            let title = TextBlock()
            title.text = obj.title
            title.fontSize = 22
            textStack.children.append(title)

            let meta = TextBlock()
            meta.text = "Views: \(obj.views)   Likes: \(obj.likes)"
            meta.opacity = 0.9
            textStack.children.append(meta)

            let desc = TextBlock()
            desc.text = obj.description
            desc.textWrapping = .wrap
            desc.opacity = 0.8
            textStack.children.append(desc)

            _ = try? Grid.setColumn(textStack, 1)
            itemGrid.children.append(textStack)

            btn.content = itemGrid
            btn.click.addHandler { [weak self] _, _ in
                self?.navigateToDetail(index: idx)
            }

            listStack.children.append(btn)
        }

        scroll.content = listStack
        listRoot.children.append(rootGrid)
    }


    private func buildDetail() {
        clearChildren(detailRoot)
        detailRoot.visibility = .collapsed

        let root = StackPanel()
        root.orientation = .vertical
        root.spacing = 10
        root.margin = Thickness(left: 0, top: 6, right: 0, bottom: 0)

        backButton.content = "Back"
        backButton.horizontalAlignment = .left
        backButton.click.addHandler { [weak self] _, _ in
            self?.navigateBack()
        }
        root.children.append(backButton)

        detailImage.width = 520
        detailImage.height = 280
        detailImage.stretch = .uniformToFill
        detailImage.horizontalAlignment = .left
        root.children.append(detailImage)

        titleText.fontSize = 22
        root.children.append(titleText)

        metaText.opacity = 0.85
        root.children.append(metaText)

        descText.textWrapping = .wrap
        root.children.append(descText)

        detailRoot.children.append(root)
    }


    private func navigateToDetail(index: Int) {
        currentIndex = index
        let obj = objects[index]

        if let bitmap = MediaLoader.makeLandscapeImage(index: obj.imageIndex) {
            detailImage.source = bitmap
        }
        titleText.text = obj.title
        metaText.text = "Views: \(obj.views)    Likes: \(obj.likes)"
        descText.text = obj.description

        if let thumb = thumbs[index],
           let service = try? ConnectedAnimationService.getForCurrentView() {
            _ = try? service.prepareToAnimate("Sample1_Image", thumb)
        }

        showDetail()

        if let service = try? ConnectedAnimationService.getForCurrentView(),
           let anim = try? service.getAnimation("Sample1_Image") {
            _ = try? anim.tryStart(detailImage)
        }
    }

    private func navigateBack() {
        if let service = try? ConnectedAnimationService.getForCurrentView() {
            _ = try? service.prepareToAnimate("Sample1_Back", detailImage)
        }

        showList()

        if let thumb = thumbs[currentIndex],
           let service = try? ConnectedAnimationService.getForCurrentView(),
           let anim = try? service.getAnimation("Sample1_Back") {
            _ = try? anim.tryStart(thumb)
        }
    }
}

// ============================================================
// Sample 2: Card -> Popup (不再切换整个区域，而是弹小窗 overlay)
// ============================================================

private final class CardToDetailConnectedAnimationHost: Grid {

    private let objects = CustomDataObject.makeObjects(count: 7)

    private let cardsRoot = Grid()

    // overlay popup
    private let overlay = Grid()
    private let popupBorder = Border()
    private let popupImage = Image()
    private let popupTitle = TextBlock()
    private let backButton = Button()

    private var cardImages: [Int: Image] = [:]
    private var currentIndex: Int = 0

    override init() {
        super.init()
        self.minWidth = 520
        self.height = 440

        self.children.append(cardsRoot)
        self.children.append(overlay)

        buildCards()
        buildPopup()

        hidePopup()
    }

    // MARK: - Cards UI

    private func buildCards() {
        let root = StackPanel()
        root.orientation = .vertical
        root.spacing = 12
        root.margin = Thickness(left: 0, top: 6, right: 0, bottom: 0)

        let tip = TextBlock()
        tip.text = "Click a card to animate to a larger preview."
        root.children.append(tip)

        let scroll = ScrollViewer()
        scroll.horizontalScrollBarVisibility = .auto
        scroll.verticalScrollBarVisibility = .disabled
        root.children.append(scroll)

        let row = StackPanel()
        row.orientation = .horizontal
        row.spacing = 12

        for (idx, obj) in objects.enumerated() {
            let btn = Button()

            let stack = StackPanel()
            stack.orientation = .vertical
            stack.spacing = 6

            let img = MediaLoader.makeImageControl(landscapeIndex: obj.imageIndex, width: 200, height: 120)
            cardImages[idx] = img
            stack.children.append(img)

            let t = TextBlock()
            t.text = obj.title
            stack.children.append(t)

            btn.content = stack
            btn.click.addHandler { [weak self] _, _ in
                self?.openPopup(index: idx)
            }

            row.children.append(btn)
        }

        scroll.content = row
        cardsRoot.children.append(root)
    }

    // MARK: - Popup UI

    private func buildPopup() {
        // 半透明遮罩：需要 UWP.Color
        overlay.background = SolidColorBrush(UWP.Color(a: 0x33, r: 0x00, g: 0x00, b: 0x00))
        overlay.horizontalAlignment = .stretch
        overlay.verticalAlignment = .stretch

        // 小窗
        popupBorder.width = 680
        popupBorder.height = 380
        popupBorder.horizontalAlignment = .center
        popupBorder.verticalAlignment = .center
        popupBorder.background = SolidColorBrush(UWP.Color(a: 0xFF, r: 0x1F, g: 0x1F, b: 0x1F))
        popupBorder.borderBrush = SolidColorBrush(UWP.Color(a: 0xFF, r: 0x3A, g: 0x3A, b: 0x3A))
        popupBorder.borderThickness = Thickness(left: 1, top: 1, right: 1, bottom: 1)
        popupBorder.cornerRadius = CornerRadius(topLeft: 8, topRight: 8, bottomRight: 8, bottomLeft: 8)

        let g = Grid()
        g.rowSpacing = 10
        g.padding = Thickness(left: 16, top: 16, right: 16, bottom: 16)

        let r0 = RowDefinition()
        r0.height = GridLength(value: 1, gridUnitType: .auto)
        let r1 = RowDefinition()
        r1.height = GridLength(value: 1, gridUnitType: .auto)
        let r2 = RowDefinition()
        r2.height = GridLength(value: 1, gridUnitType: .star)

        g.rowDefinitions.append(r0)
        g.rowDefinitions.append(r1)
        g.rowDefinitions.append(r2)

        backButton.content = "Back"
        backButton.horizontalAlignment = .left
        backButton.click.addHandler { [weak self] _, _ in
            self?.closePopup()
        }
        try? Grid.setRow(backButton, 0)
        g.children.append(backButton)

        popupTitle.fontSize = 16
        popupTitle.text = ""
        popupTitle.opacity = 0.9
        try? Grid.setRow(popupTitle, 1)
        g.children.append(popupTitle)

        popupImage.width = 640
        popupImage.height = 280
        popupImage.stretch = .uniformToFill
        popupImage.horizontalAlignment = .left
        try? Grid.setRow(popupImage, 2)
        g.children.append(popupImage)

        popupBorder.child = g
        overlay.children.append(popupBorder)
    }

    private func showPopup() {
        overlay.visibility = .visible
        overlay.isHitTestVisible = true
    }

    private func hidePopup() {
        overlay.visibility = .collapsed
        overlay.isHitTestVisible = false
    }

    // MARK: - Open / Close with Connected Animation

    private func openPopup(index: Int) {
        currentIndex = index
        let obj = objects[index]

        popupTitle.text = obj.title
        if let bitmap = MediaLoader.makeLandscapeImage(index: obj.imageIndex) {
            popupImage.source = bitmap
        }

        if let src = cardImages[index],
           let service = try? ConnectedAnimationService.getForCurrentView() {
            _ = try? service.prepareToAnimate("Sample2_Popup", src)
        }

        // 目标必须在可视树里
        showPopup()

        if let service = try? ConnectedAnimationService.getForCurrentView(),
           let anim = try? service.getAnimation("Sample2_Popup") {
            _ = try? anim.tryStart(popupImage)
        }
    }

    private func closePopup() {
        // 弹窗图 -> 卡片图（这里把 service??. 全改成正确的写法）
        if let service = try? ConnectedAnimationService.getForCurrentView() {
            _ = try? service.prepareToAnimate("Sample2_PopupBack", popupImage)

            if let src = cardImages[currentIndex],
               let anim = try? service.getAnimation("Sample2_PopupBack") {
                _ = try? anim.tryStart(src)
            }
        }

        // 先简单隐藏（如果你想“回去也要看见动画”，我可以再给你加一个延迟关闭）
        hidePopup()
    }
}


// ============================================================
// Sample 3: Simple connected animation + configuration switch
// ============================================================

private final class SimpleConnectedAnimationHost: Grid {

    private let viewA = Grid()
    private let viewB = Grid()
    private var showingA = true

    private var imageA: Image?
    private var imageB: Image?

    override init() {
        super.init()
        self.minWidth = 520
        self.height = 420

        buildViewA()
        buildViewB()

        self.children.append(viewA)
        self.children.append(viewB)
        viewB.visibility = .collapsed
    }

    func toggle(configurationName: String) {
        let service = try? ConnectedAnimationService.getForCurrentView()

        if showingA {
            if let src = imageA {
                let anim = try? service?.prepareToAnimate("Sample3_Image", src)
                applyConfiguration(anim: anim, name: configurationName)
            }

            viewA.visibility = .collapsed
            viewB.visibility = .visible

            if let anim = try? service?.getAnimation("Sample3_Image"),
               let target = imageB {
                _ = try? anim.tryStart(target)
            }
        } else {
            if let src = imageB {
                let anim = try? service?.prepareToAnimate("Sample3_Image", src)
                applyConfiguration(anim: anim, name: configurationName)
            }

            viewB.visibility = .collapsed
            viewA.visibility = .visible

            if let anim = try? service?.getAnimation("Sample3_Image"),
               let target = imageA {
                _ = try? anim.tryStart(target)
            }
        }

        showingA.toggle()
    }

    private func applyConfiguration(anim: ConnectedAnimation?, name: String) {
        guard let anim else { return }
        switch name {
        case "Gravity":
            anim.configuration = GravityConnectedAnimationConfiguration()
        case "Direct":
            anim.configuration = DirectConnectedAnimationConfiguration()
        case "Basic":
            anim.configuration = BasicConnectedAnimationConfiguration()
        default:
            anim.configuration = GravityConnectedAnimationConfiguration()
        }
    }

    private func buildViewA() {
        let root = StackPanel()
        root.orientation = .vertical
        root.spacing = 10

        let title = TextBlock()
        title.text = "View A"
        title.fontSize = 18
        root.children.append(title)

        let img = MediaLoader.makeImageControl(landscapeIndex: 1, width: 520, height: 260)
        imageA = img
        root.children.append(img)

        let hint = TextBlock()
        hint.opacity = 0.7
        hint.text = "Use Navigate and configuration options to animate to View B."
        hint.textWrapping = .wrap
        root.children.append(hint)

        viewA.children.append(root)
    }

    private func buildViewB() {
        let root = StackPanel()
        root.orientation = .vertical
        root.spacing = 10

        let title = TextBlock()
        title.text = "View B"
        title.fontSize = 18
        root.children.append(title)

        let img = MediaLoader.makeImageControl(landscapeIndex: 2, width: 520, height: 260)
        imageB = img
        root.children.append(img)

        let hint = TextBlock()
        hint.opacity = 0.7
        hint.text = "This view is the connected animation destination."
        hint.textWrapping = .wrap
        root.children.append(hint)

        viewB.children.append(root)
    }
}
