import WinUI
import Foundation
import WindowsFoundation
import WinAppSDK
import UWP

class AnimationInteropPage: Grid {

    private let pageGrid = Grid()
    private let headerGrid = Grid()
    private let exampleStackPanel = StackPanel()

    private var compositor: WinAppSDK.Compositor?
    private var springAnimation: WinAppSDK.SpringVector3NaturalMotionAnimation?

    private var sample1Button: Button?
    private var dampingRadios: RadioButtons?
    private var periodSlider: Slider?
    private let dampingValues: [Float] = [0.2, 0.4, 0.6, 0.8]

    private var sample2Rectangle: Rectangle?
    private var sample2Ellipse: Ellipse?
    private var didInitSample2 = false

    private var exprBtn1: Button?
    private var exprBtn2: Button?
    private var exprBtn3: Button?
    private var exprBtn4: Button?
    private var didInitSample3 = false

    private var layoutPanel: Grid?
    private var radiusSlider: Slider?
    private var didInitSample4 = false

    private var fontSizeSlider: Slider?
    private var marginSlider: Slider?
    private var popupTarget: TextBlock?
    private var popup: Popup?
    private var didInitSample5 = false

    override init() {
        super.init()

        do {
            self.compositor = try WinUI.CompositionTarget.getCompositorForCurrentThread()
        } catch {
            self.compositor = nil
            print("getCompositorForCurrentThread failed: \(error)")
        }

        setupRootLayout()
        setupHeader()

        setupSample1_NaturalMotion()
        setupSample2_ExpressionEllipse()
        setupSample3_StackedButtons()
        setupSample4_ActualSizeCircleLayout()
        setupSample5_ActualOffsetPopup()

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

        let scrollViewer = ScrollViewer()
        try? Grid.setRow(scrollViewer, 1)
        scrollViewer.verticalScrollBarVisibility = .auto
        scrollViewer.verticalScrollMode = .auto
        scrollViewer.padding = Thickness(left: 36, top: 0, right: 36, bottom: 24)

        exampleStackPanel.orientation = .vertical
        exampleStackPanel.spacing = 24
        exampleStackPanel.margin = Thickness(left: 0, top: 24, right: 0, bottom: 36)

        scrollViewer.content = exampleStackPanel
        pageGrid.children.append(scrollViewer)
    }

    private func setupHeader() {
        let controlInfo = ControlInfo(
            title: "Animation interop",
            apiNamespace: "Microsoft.UI.Xaml + Microsoft.UI.Composition",
            baseClasses: [
                "Object",
                "DependencyObject",
                "UIElement",
                "FrameworkElement"
            ],
            docs: [
                ControlInfoDocLink(
                    title: "XAML property animations",
                    uri: "https://learn.microsoft.com/windows/apps/design/motion/xaml-property-animations"
                ),
                ControlInfoDocLink(
                    title: "Visual layer (Windows App SDK)",
                    uri: "https://learn.microsoft.com/windows/apps/windows-app-sdk/composition"
                )
            ]
        )

        let pageHeader = PageHeader(item: controlInfo)
        pageHeader.themeButtonVisibility = .visible
        pageHeader.margin = Thickness(left: 36, top: 36, right: 36, bottom: 0)
        headerGrid.children.append(pageHeader)
    }

    private func accentBrush() -> Brush {
        if let app = Application.current,
           let res = app.resources {
            if let b = res["SystemAccentColorBrush"] as? Brush { return b }
            if let c = res["SystemAccentColor"] as? Color { return SolidColorBrush(c) }
        }
        return SolidColorBrush(Color(a: 0xFF, r: 0x00, g: 0x78, b: 0xD4))
    }

    private func themeBrush(_ key: String, fallback: Color) -> Brush {
        if let app = Application.current,
           let res = app.resources,
           let b = res[key] as? Brush {
            return b
        }
        return SolidColorBrush(fallback)
    }

    private func msToTimeSpan(_ ms: Double) -> TimeSpan {
        let ticks = Int64(ms * 10_000.0)
        return TimeSpan(duration: ticks)
    }

    private func currentDampingRatio() -> Float {
        guard let radios = dampingRadios else { return 0.6 }
        let idx = Int(radios.selectedIndex)
        if idx >= 0 && idx < dampingValues.count { return dampingValues[idx] }
        return 0.6
    }

    private func currentPeriod() -> TimeSpan {
        let v = periodSlider?.value ?? 50.0
        return msToTimeSpan(v)
    }

    private func ensureSpringAnimation() {
        guard let compositor = compositor else { return }
        if springAnimation != nil { return }

        do {
            if let anim = try compositor.createSpringVector3Animation() {
                anim.target = "Scale"
                springAnimation = anim
            }
        } catch {
            print("createSpringVector3Animation failed: \(error)")
        }
    }

    private func updateSpringAnimation(finalValue: Float) {
        ensureSpringAnimation()
        guard let anim = springAnimation else { return }
        anim.finalValue = WindowsFoundation.Vector3(x: finalValue, y: finalValue, z: finalValue)
        anim.dampingRatio = currentDampingRatio()
        anim.period = currentPeriod()
    }

    private func startScaleSpring(_ element: UIElement, to finalValue: Float) {
        updateSpringAnimation(finalValue: finalValue)
        guard let anim = springAnimation else { return }
        do {
            try element.startAnimation(anim)
        } catch {
            print("startAnimation failed: \(error)")
        }
    }

    private func attachHoverScale(_ element: UIElement) {
        element.pointerEntered.addHandler { [weak self] sender, _ in
            guard let self = self, let ui = sender as? UIElement else { return }
            self.startScaleSpring(ui, to: 1.5)
        }
        element.pointerExited.addHandler { [weak self] sender, _ in
            guard let self = self, let ui = sender as? UIElement else { return }
            self.startScaleSpring(ui, to: 1.0)
        }
    }

    // =========================================================
    // Sample 1
    // =========================================================
    private func setupSample1_NaturalMotion() {
        let contentPanel = StackPanel()

        let tip = TextBlock()
        tip.text = "Hover over the button to animate its scale."
        tip.margin = Thickness(left: 0, top: 0, right: 0, bottom: 12)
        contentPanel.children.append(tip)

        let btn = Button()
        btn.width = 100
        btn.height = 50
        btn.content = "Item"
        sample1Button = btn

        attachHoverScale(btn)
        contentPanel.children.append(btn)

        let optionsPanel = StackPanel()
        optionsPanel.width = 200

        let radios = RadioButtons()
        radios.header = "Damping Ratio"
        radios.items.append("0.2")
        radios.items.append("0.4")
        radios.items.append("0.6")
        radios.items.append("0.8")
        radios.selectedIndex = 2
        dampingRadios = radios
        optionsPanel.children.append(radios)

        let slider = Slider()
        slider.header = "Period (in ms)"
        slider.minimum = 25
        slider.maximum = 200
        slider.stepFrequency = 25
        slider.tickFrequency = 25
        slider.value = 50
        periodSlider = slider
        optionsPanel.children.append(slider)

        contentPanel.loaded.addHandler { [weak self] _, _ in
            self?.updateSpringAnimation(finalValue: 1.0)
        }

        let example = ControlExample()
        example.headerText = "Use a natural motion composition animation on a UIElement"
        example.example = contentPanel
        example.options = optionsPanel
        exampleStackPanel.children.append(example.view)
    }

    // =========================================================
    // Sample 2
    // =========================================================
    private func setupSample2_ExpressionEllipse() {
        let root = StackPanel()
        root.height = 200

        let t1 = TextBlock()
        t1.text = "Hover over the square to animate its scale. Notice that the ellipse also animates."
        t1.textWrapping = .wrapWholeWords
        root.children.append(t1)

        let t2 = TextBlock()
        t2.text = "The scale of the circle is inversely related to the scale of the square."
        t2.margin = Thickness(left: 0, top: 0, right: 0, bottom: 12)
        t2.textWrapping = .wrapWholeWords
        root.children.append(t2)

        let grid = Grid()
        let c1 = ColumnDefinition()
        c1.width = GridLength(value: 1, gridUnitType: .star)
        let c2 = ColumnDefinition()
        c2.width = GridLength(value: 1, gridUnitType: .star)
        grid.columnDefinitions.append(c1)
        grid.columnDefinitions.append(c2)

        let rect = Rectangle()
        rect.width = 50
        rect.height = 50
        rect.fill = accentBrush()
        sample2Rectangle = rect
        attachHoverScale(rect)
        try? Grid.setColumn(rect, 0)
        grid.children.append(rect)

        let ell = Ellipse()
        ell.width = 50
        ell.height = 50
        ell.margin = Thickness(left: 55, top: 0, right: 0, bottom: 0)
        ell.fill = accentBrush()
        sample2Ellipse = ell
        try? Grid.setColumn(ell, 1)
        grid.children.append(ell)

        root.children.append(grid)

        root.loaded.addHandler { [weak self] _, _ in
            guard let self = self else { return }
            if self.didInitSample2 { return }
            self.didInitSample2 = true
            guard let compositor = self.compositor,
                  let rectangle = self.sample2Rectangle,
                  let ellipse = self.sample2Ellipse else { return }

            do {
                if let anim = try compositor.createExpressionAnimation() {
                    anim.expression = "Vector3(1/scaleElement.Scale.X, 1/scaleElement.Scale.Y, 1)"
                    anim.target = "Scale"
                    try? anim.setExpressionReferenceParameter("scaleElement", rectangle)
                    try? ellipse.startAnimation(anim)
                }
            } catch {
                print("createExpressionAnimation failed: \(error)")
            }
        }

        let example = ControlExample()
        example.headerText = "ExpressionAnimation on an Ellipse element"
        example.example = root
        exampleStackPanel.children.append(example.view)
    }

    // =========================================================
    // Sample 3
    // =========================================================
    private func setupSample3_StackedButtons() {
        let root = StackPanel()
        root.margin = Thickness(left: 0, top: 0, right: 0, bottom: 50)

        let t1 = TextBlock()
        t1.text = "Hover over any button to animate its scale. Notice that the other buttons move out of the way."
        t1.textWrapping = .wrapWholeWords
        root.children.append(t1)

        let t2 = TextBlock()
        t2.text = "Each button animates its translation as a function of the previous button's scale and translation."
        t2.margin = Thickness(left: 0, top: 0, right: 0, bottom: 12)
        t2.textWrapping = .wrapWholeWords
        root.children.append(t2)

        func makeItemButton(_ title: String) -> Button {
            let b = Button()
            b.width = 100
            b.height = 50
            b.margin = Thickness(left: 5, top: 5, right: 5, bottom: 5)
            b.content = title
            attachHoverScale(b)
            return b
        }

        let b1 = makeItemButton("Item 1"); exprBtn1 = b1
        let b2 = makeItemButton("Item 2"); exprBtn2 = b2
        let b3 = makeItemButton("Item 3"); exprBtn3 = b3
        let b4 = makeItemButton("Item 4"); exprBtn4 = b4

        root.children.append(b1)
        root.children.append(b2)
        root.children.append(b3)
        root.children.append(b4)

        root.loaded.addHandler { [weak self] _, _ in
            guard let self = self else { return }
            if self.didInitSample3 { return }
            self.didInitSample3 = true

            guard let compositor = self.compositor,
                  let button1 = self.exprBtn1,
                  let button2 = self.exprBtn2,
                  let button3 = self.exprBtn3,
                  let button4 = self.exprBtn4 else { return }

            do {
                if let anim = try compositor.createExpressionAnimation() {
                    anim.expression = "(above.Scale.Y - 1) * 50 + above.Translation.Y % (50 * index)"
                    anim.target = "Translation.Y"

                    try? anim.setExpressionReferenceParameter("above", button1)
                    try? anim.setScalarParameter("index", 1)
                    try? button2.startAnimation(anim)

                    try? anim.setExpressionReferenceParameter("above", button2)
                    try? anim.setScalarParameter("index", 2)
                    try? button3.startAnimation(anim)

                    try? anim.setExpressionReferenceParameter("above", button3)
                    try? anim.setScalarParameter("index", 3)
                    try? button4.startAnimation(anim)
                }
            } catch {
                print("createExpressionAnimation failed: \(error)")
            }
        }

        let example = ControlExample()
        example.headerText = "Driving several related animations together using ExpressionAnimation"
        example.example = root
        exampleStackPanel.children.append(example.view)
    }

    // =========================================================
    // Sample 4
    // =========================================================
    private func setupSample4_ActualSizeCircleLayout() {
        let optionsPanel = StackPanel()

        let slider = Slider()
        slider.minWidth = 150
        slider.header = "Change radius"
        slider.minimum = 200
        slider.maximum = 400
        slider.value = 200
        radiusSlider = slider
        optionsPanel.children.append(slider)

        let panel = Grid()
        panel.width = 200
        panel.height = 200
        panel.margin = Thickness(left: 12, top: 12, right: 12, bottom: 12)
        layoutPanel = panel

        slider.valueChanged.addHandler { [weak self] _, _ in
            guard let self = self, let lp = self.layoutPanel else { return }
            let v = self.radiusSlider?.value ?? 200
            lp.width = v
            lp.height = v
        }

        panel.loaded.addHandler { [weak self] _, _ in
            guard let self = self else { return }
            if self.didInitSample4 { return }
            self.didInitSample4 = true

            guard let compositor = self.compositor,
                  let lp = self.layoutPanel else { return }

            let radius = "(source.ActualSize.X / 2)"
            let theta = ".02 * " + radius + " + ((2 * Pi)/total)*index"
            let expression = "Vector3(\(radius)*cos(\(theta))+\(radius), \(radius)*sin(\(theta))+0,0)"

            let totalElements = 8
            for i in 0..<totalElements {
                let element = Button()
                element.content = "Button"
                lp.children.append(element)

                do {
                    if let anim = try compositor.createExpressionAnimation() {
                        anim.expression = expression
                        anim.target = "Translation"
                        try? anim.setScalarParameter("index", Float(i + 1))
                        try? anim.setScalarParameter("total", Float(totalElements))
                        try? anim.setExpressionReferenceParameter("source", lp)
                        try? element.startAnimation(anim)
                    }
                } catch {
                    print("createExpressionAnimation failed: \(error)")
                }
            }
        }

        let example = ControlExample()
        example.headerText = "Reference ActualSize in ExpressionAnimations to make novel layouts based on size"
        example.example = panel
        example.options = optionsPanel
        exampleStackPanel.children.append(example.view)
    }

    // =========================================================
    // Sample 5
    // =========================================================
    private func setupSample5_ActualOffsetPopup() {
        let optionsPanel = StackPanel()
        optionsPanel.spacing = 8

        let fs = Slider()
        fs.header = "Change font size"
        fs.minimum = 8
        fs.maximum = 36
        fs.value = 14
        fontSizeSlider = fs
        optionsPanel.children.append(fs)

        let ms = Slider()
        ms.header = "Change text margin"
        ms.minimum = 0
        ms.maximum = 100
        ms.value = 0
        marginSlider = ms
        optionsPanel.children.append(ms)

        let root = StackPanel()

        let tip = TextBlock()
        tip.text = "This sample positions a popup relative to a block of text that has variable layout size based on font size. Use the sliders to move and resize the text."
        tip.textWrapping = .wrapWholeWords
        root.children.append(tip)

        let host = Grid()
        host.margin = Thickness(left: 0, top: 12, right: 0, bottom: 0)
        host.horizontalAlignment = .left

        let target = TextBlock()
        target.width = 300
        target.textWrapping = .wrapWholeWords
        target.text =
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        popupTarget = target
        host.children.append(target)

        let p = Popup()
        p.margin = Thickness(left: 5, top: 5, right: 5, bottom: 5)

        let popGrid = Grid()
        popGrid.minWidth = 50
        popGrid.minHeight = 50
        popGrid.maxWidth = 200
        popGrid.background = themeBrush(
            "FlyoutBackgroundThemeBrush",
            fallback: Color(a: 0xFF, r: 0xF3, g: 0xF3, b: 0xF3)
        )
        popGrid.borderBrush = themeBrush(
            "SystemControlForegroundChromeGrayBrush",
            fallback: Color(a: 0xFF, r: 0x80, g: 0x80, b: 0x80)
        )
        popGrid.borderThickness = Thickness(left: 2, top: 2, right: 2, bottom: 2)

        let popText = TextBlock()
        popText.text = "I am always right aligned center to the target."
        popText.textWrapping = .wrapWholeWords
        popText.margin = Thickness(left: 6, top: 6, right: 6, bottom: 6)
        popText.verticalAlignment = .center
        popGrid.children.append(popText)

        p.child = popGrid
        popup = p
        host.children.append(p)

        root.children.append(host)

        fs.valueChanged.addHandler { [weak self] _, _ in
            guard let self = self, let t = self.popupTarget else { return }
            t.fontSize = self.fontSizeSlider?.value ?? 14
        }
        ms.valueChanged.addHandler { [weak self] _, _ in
            guard let self = self, let t = self.popupTarget else { return }
            let v = self.marginSlider?.value ?? 0
            t.margin = Thickness(left: v, top: v, right: v, bottom: v)
        }

        root.loaded.addHandler { [weak self] _, _ in
            guard let self = self else { return }
            if self.didInitSample5 { return }
            self.didInitSample5 = true

            guard let compositor = self.compositor,
                  let target = self.popupTarget,
                  let popup = self.popup else { return }

            do {
                if let anim = try compositor.createExpressionAnimation() {
                    anim.expression = "Vector3(source.ActualOffset.X + source.ActualSize.X, source.ActualOffset.Y + source.ActualSize.Y / 2 - 25, 0)"
                    anim.target = "Translation"
                    try? anim.setExpressionReferenceParameter("source", target)
                    try? popup.startAnimation(anim)
                    popup.isOpen = true
                }
            } catch {
                print("createExpressionAnimation failed: \(error)")
            }
        }

        let example = ControlExample()
        example.headerText = "Reference ActualOffset and ActualSize in ExpressionAnimations to position elements relative to each other"
        example.example = root
        example.options = optionsPanel
        exampleStackPanel.children.append(example.view)
    }
}