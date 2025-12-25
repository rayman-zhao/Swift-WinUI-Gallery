import WinUI
import WinAppSDK
import Foundation
import UWP
import WindowsFoundation

class ListViewPage: Grid {
    let nameAndCompany = [
        "Kendall Collins",
        "Adatum Corporation",
        "Henry Ross",
        "Adventure Works Cycles",
        "Vance DeLeon",
        "Alpine Ski House", 
        "Victoria Burke",
        "Bellows College",
        "Amber Rodriguez",
        "BestForYou Organics Company",
        "Amari Rivera",
        "Contoso, Ltd",
        "Jessie Irwin",
        "Contoso Pharmaceuticals",
        "Quinn Campbell",
        "Contoso Suites"
    ]
    private var page: Page = Page()
    private var dragDropListView: ListView = ListView()
    private var dragDropListView2: ListView = ListView()
    private var exampleStackPanel: StackPanel = StackPanel()
    override init() {
        do {
            let filePath = Bundle.module.path(forResource: "ListViewPage", ofType: "xaml", inDirectory: "Assets/xaml")
            let root: Any? = try WinUI.XamlReader.load(FileReader.readFileFromPath(filePath!) ?? "")
            if let page = root as? WinUI.Page {
                self.page = page
                self.dragDropListView = try! page.findName("DragDropListView") as! ListView
                self.dragDropListView2 = try! page.findName("DragDropListView2") as! ListView
                self.exampleStackPanel = try! page.findName("exampleStackPanel") as! StackPanel
            } else {
                print("XAML根元素类型转换失败, 实际类型: \(type(of: root))")
            }
        } catch {
            print("XAML 加载失败: \(error)")
        }
        super.init()
        let headerGrid = try! page.findName("headerGrid") as! Grid
        setupPageHeader(headerGrid: headerGrid)
        self.children.append(page)
        setupExample1()
        setupExample2()
        setupExample3()
        setupExample6()
        setupExample7()
        setupExample8()
        bindingEvents()
    }
    private func setupPageHeader(headerGrid: Grid) {
        let pageHeader: PageHeader
        let controlInfo = ControlInfo(
            title: "ListView",
            apiNamespace: "Microsoft.UI.Xaml.Controls",
            baseClasses: [
                "Object",
                "DependencyObject",
                "UIElement",
                "FrameworkElement",
                "Control",
                "ItemsControl",
                "Selector",
                "ListViewBase"
            ],
            docs: [
                ControlInfoDocLink(
                    title: "ListView-API",
                    uri: "https://learn.microsoft.com/zh-cn/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.controls.listview?view=windows-app-sdk-1.8"
                ),
                ControlInfoDocLink(
                    title: "Guidelines",
                    uri: "https://learn.microsoft.com/zh-cn/windows/apps/design/controls/listview-and-gridview"
                )
            ]
        )
        pageHeader = PageHeader(item: controlInfo)
        pageHeader.themeButtonVisibility = .visible
        pageHeader.margin = Thickness(left: 36, top: 36, right: 36, bottom: 0)
        headerGrid.children.append(pageHeader)
    }

    private func setupExample1() {
        let listView = try! page.findName("BaseExample") as! ListView
        let names = [
            "Kendall Collins",
            "Henry Ross",
            "Vance DeLeon",
            "Victoria Burke",
            "Amber Rodriguez",
            "Amari Rivera",
            "Jessie Irwin",
            "Quinn Campbell",
            "Olivia Wilson",
            "Ana Bowman",
            "Shawn Hughes",
            "Oscar Ward",
            "Madison Butler",
            "Graham Barnes",
            "Anthony Ivanov",
            "Michael Peltier",
            "Morgan Connors",
            "Andre Lawson",
            "Preston Morales",
            "Briana Hernandez",
            "Nicole Wagner",
            "Mario Rogers",
            "Eugenia Lopez",
            "Nathan Rigby",
            "Ellis Turner",
            "Miguel Reyes",
            "Hayden Cook"
        ]
        for i in names {
            listView.items.append(i)
        }
    }

    private func setupExample2() {
        let listView2 = try! page.findName("Control2") as! ListView
        for item in nameAndCompany {
            let components = item.split(separator: " ")
            if components.count >= 2 {
                let firstName = String(components[0])
                let lastName = String(components[1])
                listView2.items.append(createContactListView(name: firstName, company: lastName))
            }
        }
    }

    private func setupExample3() {
        let dragDropListView = try! page.findName("DragDropListView") as! ListView
        let dragDropListView2 = try! page.findName("DragDropListView2") as! ListView
        for (index, item) in nameAndCompany.enumerated() {
            let components = item.split(separator: " ")
            if components.count >= 2 {
                let firstName = String(components[0])
                let lastName = String(components[1])
                if (index % 2 == 0) {
                    dragDropListView.items.append(createContactListView(name: firstName, company: lastName))
                } else {
                    dragDropListView2.items.append(createContactListView(name: firstName, company: lastName))
                }
            }
        }
        self.dragDropListView = dragDropListView
        self.dragDropListView2 = dragDropListView2
    }

    private func createItemForExample6(
            alignment: HorizontalAlignment,
            msgText: String,
            msgDateTime: String,
            ) -> Grid {
        let grid = Grid()
        grid.margin = Thickness(left: 4, top: 4, right: 4, bottom: 4)
        grid.horizontalAlignment = alignment

        let stackPanel = StackPanel()
        stackPanel.width = 350
        stackPanel.minHeight = 75
        stackPanel.padding = Thickness(left: 10, top: 0, right: 0, bottom: 10)

        let textBlock1 = TextBlock()
        textBlock1.padding = Thickness(left: 0, top: 10, right: 0, bottom: 0)
        textBlock1.fontSize = 20
        textBlock1.text = msgText

        let textBlock2 = TextBlock()
        textBlock2.padding = Thickness(left: 0, top: 0, right: 0, bottom: 10)
        textBlock2.fontSize = 15
        textBlock2.text = msgDateTime

        stackPanel.children.append(textBlock1)
        stackPanel.children.append(textBlock2)
        grid.children.append(stackPanel)
        grid.background = SolidColorBrush(Colors.blue)
        return grid
    }
    private func setupExample6() {
        let example6 = try! page.findName("Example6") as! Grid
        let invertedListView = try! page.findName("InvertedListView") as! ListView
        invertedListView.borderThickness = Thickness(left: 2, top: 2, right: 2, bottom: 2)
        let btn1 = Button()
        btn1.margin = Thickness(left: 0, top: 0, right: 0, bottom: 10)
        btn1.content = "Send Message"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var idx = 0 
        btn1.click.addHandler { (_: Any?, _: RoutedEventArgs?) in
            invertedListView.items.append(self.createItemForExample6(
                alignment: HorizontalAlignment.left, 
                msgText: "Hello" + String(idx), 
                msgDateTime: formatter.string(from: Date())))
            idx += 1
        }
        let btn2 = Button()
        btn2.content = "Receive Message"
        btn2.click.addHandler { (_: Any?, _: RoutedEventArgs?) in
            invertedListView.items.append(self.createItemForExample6(
                alignment: HorizontalAlignment.right, 
                msgText: "Hello" + String(idx), 
                msgDateTime: formatter.string(from: Date())))
            idx += 1
        }
        let stackPanel = StackPanel()
        stackPanel.horizontalAlignment = .right
        stackPanel.children.append(btn1)
        stackPanel.children.append(btn2)
        let _ = exampleStackPanel.children.remove(at: exampleStackPanel.children.index(of: example6)!)
        let controlExample = ControlExample()
        controlExample.headerText = "ListView for Messaging or Data Logging"
        controlExample.example = example6
        controlExample.options = stackPanel
        self.exampleStackPanel.children.append(controlExample.view)
        // self.exampleStackPanel.children.append(ControlExample(
        //     headerText: "ListView for Messaging or Data Logging",
        //     isOutputDisplay: false,
        //     isOptionsDisplay: true,
        //     contentPresenter: example6,
        //     optionsPresenter: stackPanel
        // ).controlExample)
    }

    private class ListViewItemData
    {
        public var imageSource: String
        public var title: String
        public var description: String
        public var views: Int
        public var likes: Int
        init(imageSource: String = "", title: String = "Item Title", 
                description: String = "Item Description", views: Int = 0, likes: Int = 0) {
            self.imageSource = imageSource
            self.title = title
            self.description = description
            self.views = views
            self.likes = likes
        }
    }

    private let example7List = [
        ListViewItemData(
            imageSource: Bundle.module.path(forResource: "LandscapeImage1", ofType: "jpg", inDirectory: "Assets/SampleMedia")!, 
            title: "Item 1", 
            description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer id facilisis lectus. Cras nec convallis ante, quis pulvinar tellus. Integer dictum accumsan pulvinar. Pellentesque eget enim sodales sapien vestibulum consequat.",
            views: 1, likes: 2),
        ListViewItemData(
            imageSource: Bundle.module.path(forResource: "LandscapeImage2", ofType: "jpg", inDirectory: "Assets/SampleMedia")!, 
            title: "Item 2", 
            description: "Nullam eget mattis metus. Donec pharetra, tellus in mattis tincidunt, magna ipsum gravida nibh, vitae lobortis ante odio vel quam.",
            views: 2, likes: 4),
        ListViewItemData(
            imageSource: Bundle.module.path(forResource: "LandscapeImage3", ofType: "jpg", inDirectory: "Assets/SampleMedia")!, 
            title: "Item 3", 
            description: "Quisque accumsan pretium ligula in faucibus. Mauris sollicitudin augue vitae lorem cursus condimentum quis ac mauris. Pellentesque quis turpis non nunc pretium sagittis. Nulla facilisi. Maecenas eu lectus ante. Proin eleifend vel lectus non tincidunt. Fusce condimentum luctus nisi, in elementum ante tincidunt nec.",
            views: 3, likes: 6),
        ListViewItemData(
            imageSource: Bundle.module.path(forResource: "LandscapeImage4", ofType: "jpg", inDirectory: "Assets/SampleMedia")!, 
            title: "Item 4", 
            description: "Aenean in nisl at elit venenatis blandit ut vitae lectus. Praesent in sollicitudin nunc. Pellentesque justo augue, pretium at sem lacinia, scelerisque semper erat. Ut cursus tortor at metus lacinia dapibus.",
            views: 4, likes: 8),
        ListViewItemData(
            imageSource: Bundle.module.path(forResource: "LandscapeImage5", ofType: "jpg", inDirectory: "Assets/SampleMedia")!, 
            title: "Item 5", 
            description: "Ut consequat magna luctus justo egestas vehicula. Integer pharetra risus libero, et posuere justo mattis et.",
            views: 5, likes: 10),
    ]
    private func setupExample7() {
        let example7: Grid = try! page.findName("Example7") as! Grid
        let control4: ListView = try! example7.findName("Control4") as! ListView
        for item in example7List {
            // 创建外部Grid容器
            let itemGrid = Grid()
            itemGrid.margin = Thickness(left: 0, top: 12, right: 0, bottom: 12)
            
            // 创建列定义
            let colDef1 = ColumnDefinition()
            colDef1.width = GridLength(value: 1, gridUnitType: .auto) // Auto
            colDef1.minWidth = 150
            itemGrid.columnDefinitions.append(colDef1)
            
            let colDef2 = ColumnDefinition()
            colDef2.width = GridLength(value: 1, gridUnitType: .star) // *
            itemGrid.columnDefinitions.append(colDef2)
            
            // 创建图片
            let image = Image()
            image.maxHeight = 100
            image.stretch = .fill
            image.source = BitmapImage(Uri(item.imageSource))
            itemGrid.children.append(image)
            
            // 创建右侧内容StackPanel
            let contentStack = StackPanel()
            contentStack.margin = Thickness(left: 12, top: 0, right: 0, bottom: 0)
            try! Grid.setColumn(contentStack, 1)
            
            // 标题
            let titleText = TextBlock()
            titleText.margin = Thickness(left: 0, top: 0, right: 0, bottom: 6)
            titleText.horizontalAlignment = .left
            titleText.fontSize = 14
            titleText.fontWeight = FontWeight()
            titleText.lineHeight = 20
            titleText.text = item.title
            contentStack.children.append(titleText)
            
            // 描述
            let descText = TextBlock()
            descText.width = 350
            descText.maxHeight = 60
            descText.margin = Thickness(left: 0, top: 0, right: 0, bottom: 10)
            descText.fontWeight = FontWeight()
            descText.text = item.description
            descText.textTrimming = .characterEllipsis
            descText.textWrapping = .wrap
            contentStack.children.append(descText)
            
            // Views和Likes信息
            let statsStack = StackPanel()
            statsStack.orientation = .horizontal
            
            let viewsText = TextBlock()
            viewsText.margin = Thickness()
            viewsText.text = "\(item.views)"
            statsStack.children.append(viewsText)
            
            let viewsLabel = TextBlock()
            viewsLabel.text = " Views "
            statsStack.children.append(viewsLabel)
            
            let separator = TextBlock()
            separator.text = " \u{22C5} " // 中点符号
            statsStack.children.append(separator)
            
            let likesText = TextBlock()
            likesText.margin = Thickness(left: 5, top: 0, right: 0, bottom: 0)
            likesText.text = "\(item.likes)"
            statsStack.children.append(likesText)
            
            let likesLabel = TextBlock()
            likesLabel.text = " Likes"
            statsStack.children.append(likesLabel)
            
            contentStack.children.append(statsStack)
            
            // 将内容添加到Grid
            itemGrid.children.append(contentStack)
            
            // 将Grid添加到ListView
            control4.items.append(itemGrid)
        }
        let _ = exampleStackPanel.children.remove(at: exampleStackPanel.children.index(of: example7)!)
        let controlExample = ControlExample()
        controlExample.headerText = "ListView with Images"
        controlExample.example = example7
        self.exampleStackPanel.children.append(controlExample.view)
        // self.exampleStackPanel.children.append(ControlExample(
        //     headerText: "ListView with Images",
        //     isOutputDisplay: false,
        //     isOptionsDisplay: false,
        //     contentPresenter: example7
        // ).controlExample)
    }

    private func setupExample8() {
        let example8: Grid = try! page.findName("Example8") as! Grid
        let contextMenuList = try! example8.findName("ContextMenuList") as! ListView
        for item in nameAndCompany {
            let components = item.split(separator: " ")
            if components.count >= 2 {
                let firstName = String(components[0])
                let lastName = String(components[1])
                let grid = createContactListView(name: firstName, company: lastName)
                let contextFlyout = MenuFlyout()
                let menuFlyoutItem = MenuFlyoutItem()
                contextFlyout.items.append(menuFlyoutItem)
                menuFlyoutItem.text = "Delete"
                grid.contextFlyout = contextFlyout
                contextMenuList.items.append(grid)
            }
        }
        let _ = exampleStackPanel.children.remove(at: exampleStackPanel.children.index(of: example8)!)
        let controlExample = ControlExample()
        controlExample.headerText = "ListView with context menus"
        controlExample.example = example8
        self.exampleStackPanel.children.append(controlExample.view)
        // self.exampleStackPanel.children.append(ControlExample(
        //     headerText: "ListView with context menus",
        //     isOutputDisplay: false,
        //     isOptionsDisplay: false,
        //     contentPresenter: example8
        // ).controlExample)
    }

    private func createContactListView(name: String, company: String) -> Grid {
        let grid = Grid()
        // 定义行
        let rowDef1 = RowDefinition()
        rowDef1.height = GridLength(value: 1, gridUnitType: .star)
        grid.rowDefinitions.append(rowDef1)
        
        let rowDef2 = RowDefinition()
        rowDef2.height = GridLength(value: 1, gridUnitType: .star)
        grid.rowDefinitions.append(rowDef2)
        
        // 定义列
        let colDef1 = ColumnDefinition()
        colDef1.width = GridLength(value: 1, gridUnitType: .auto)
        grid.columnDefinitions.append(colDef1)
        
        let colDef2 = ColumnDefinition()
        colDef2.width = GridLength(value: 1, gridUnitType: .star)
        grid.columnDefinitions.append(colDef2)
        
        // 创建椭圆（头像）
        let ellipse = Ellipse()
        ellipse.width = 32
        ellipse.height = 32
        ellipse.margin = Thickness(left: 6, top: 6, right: 6, bottom: 6)
        ellipse.horizontalAlignment = .center
        ellipse.verticalAlignment = .center
        ellipse.fill = SolidColorBrush(UWP.Color(a: 255, r: 128, g: 128, b: 128))

        try! Grid.setRowSpan(ellipse, 2)
        
        // 创建姓名 TextBlock
        let nameTextBlock = TextBlock()
        nameTextBlock.margin = Thickness(left: 12, top: 6, right: 0, bottom: 0)
        // 设置样式（需要从 Application.current.resources 获取）
        if let baseStyle = Application.current?.resources["BaseTextBlockStyle"] as? Style {
            nameTextBlock.style = baseStyle
        }
        nameTextBlock.text = name
        try! Grid.setColumn(nameTextBlock, 1)
        
        // 创建公司 TextBlock
        let companyTextBlock = TextBlock()
        companyTextBlock.margin = Thickness(left: 12, top: 0, right: 0, bottom: 6)
        // 设置样式
        if let bodyStyle = Application.current?.resources["BodyTextBlockStyle"] as? Style {
            companyTextBlock.style = bodyStyle
        }
        companyTextBlock.text = company
        try! Grid.setRow(companyTextBlock, 1)
        try! Grid.setColumn(companyTextBlock, 1)
        
        // 添加到网格
        grid.children.append(ellipse)
        grid.children.append(nameTextBlock)
        grid.children.append(companyTextBlock)
        return grid
    }

    private func bindingEvents() {
        dragDropListView.dragItemsStarting.addHandler { sender, args in
            print("DragItemsStarting event triggered")
        }
        
        dragDropListView.drop.addHandler { sender, args in
            print("Drop event triggered")
        }
        
        dragDropListView2.dragItemsStarting.addHandler { sender, args in
            print("DragItemsStarting event triggered on ListView 2")
        }
        
        dragDropListView2.drop.addHandler { sender, args in
            print("Drop event triggered on ListView 2")
        }
    }
}