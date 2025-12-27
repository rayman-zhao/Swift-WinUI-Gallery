import WinUI
import Foundation
import WindowsFoundation
import UWP

final class EasingFunctionsPage: Grid {

    private let pageGrid = Grid()
    private let headerGrid = Grid()
    private let bodyScroll = ScrollViewer()
    private let bodyStack = StackPanel()

    override init() {
        super.init()
        buildRoot()
        buildHeader()
        buildBody()
        self.children.append(pageGrid)
    }

    // MARK: - Root

    private func buildRoot() {
        let rowHeader = RowDefinition()
        rowHeader.height = GridLength(value: 1, gridUnitType: .auto)
        let rowBody = RowDefinition()
        rowBody.height = GridLength(value: 1, gridUnitType: .star)

        pageGrid.rowDefinitions.append(rowHeader)
        pageGrid.rowDefinitions.append(rowBody)

        pageGrid.children.append(headerGrid)

        try? Grid.setRow(bodyScroll, 1)
        bodyScroll.padding = Thickness(left: 36, top: 0, right: 36, bottom: 24)
        bodyScroll.verticalScrollBarVisibility = .auto
        bodyScroll.horizontalScrollBarVisibility = .disabled

        bodyStack.orientation = .vertical
        bodyStack.spacing = 12
        bodyStack.margin = Thickness(left: 0, top: 24, right: 0, bottom: 36)

        bodyScroll.content = bodyStack
        pageGrid.children.append(bodyScroll)
    }

    private func buildHeader() {
        let controlInfo = ControlInfo(
            title: "Easing Functions",
            apiNamespace: "Microsoft.UI.Xaml.Media.Animation",
            baseClasses: ["Object", "DependencyObject"],
            docs: [
                ControlInfoDocLink(
                    title: "EasingFunctionBase - API",
                    uri: "https://learn.microsoft.com/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.media.animation.easingfunctionbase"
                )
            ]
        )

        let pageHeader = PageHeader(item: controlInfo)
        pageHeader.themeButtonVisibility = .visible
        pageHeader.margin = Thickness(left: 36, top: 36, right: 36, bottom: 0)
        headerGrid.children.append(pageHeader)
    }

    private func buildBody() {
        let desc = TextBlock()
        desc.textWrapping = .wrap
        desc.text =
            "- Use the Standard easing function for animating general property changes.\n" +
            "- Use the Accelerate easing function to animate objects that are exiting the scene.\n" +
            "- Use the Decelerate easing function to animate objects that are entering the scene."
        bodyStack.children.append(desc)

        do {
            let view = StandardEasingSampleView()
            let ex = ControlExample()
            ex.headerText = "Standard Easing Function"
            ex.example = view
            bodyStack.children.append(ex.view)
        }

        do {
            let view = AccelerateEasingSampleView()
            let ex = ControlExample()
            ex.headerText = "Accelerate Easing Function"
            ex.example = view
            ex.options = view.optionsPanel
            bodyStack.children.append(ex.view)
        }

        do {
            let view = DecelerateEasingSampleView()
            let ex = ControlExample()
            ex.headerText = "Decelerate Easing Function"
            ex.example = view
            ex.options = view.optionsPanel
            bodyStack.children.append(ex.view)
        }

        do {
            let view = OtherEasingSampleView()
            let ex = ControlExample()
            ex.headerText = "Other XAML Easing Functions"
            ex.example = view
            ex.options = view.optionsPanel
            bodyStack.children.append(ex.view)
        }
    }
}

private func seconds(_ s: Double) -> Duration {
    let ticksPerSecond: Int64 = 10_000_000
    let ticks = Int64(Double(ticksPerSecond) * s)
    return Duration(timeSpan: TimeSpan(duration: ticks), type: DurationType(1))
}

private func accentBrush() -> SolidColorBrush {
    let c = Color(a: 0xFF, r: 0x00, g: 0x78, b: 0xD4)
    return SolidColorBrush(c)
}

private func safeBegin(_ storyboard: Storyboard, tag: String) {
    do {
        try storyboard.stop()
    } catch {
    }
    do {
        try storyboard.begin()
    } catch {
        print("[Easing] storyboard begin failed (\(tag)): \(error)")
    }
}

// ============================================================
// Example 1: CircleEase(EaseInOut)
// ============================================================

private final class StandardEasingSampleView: Grid {

    private let root = Grid()
    private let button = Button()
    private let rect = Rectangle()
    private let translate = TranslateTransform()

    private let storyboard = Storyboard()
    private let anim = DoubleAnimation()

    override init() {
        super.init()
        build()
    }

    private func build() {
        self.children.append(root)

        let col0 = ColumnDefinition()
        col0.width = GridLength(value: 1, gridUnitType: .auto)
        let col1 = ColumnDefinition()
        col1.width = GridLength(value: 1, gridUnitType: .star)
        col1.minWidth = 300

        root.columnDefinitions.append(col0)
        root.columnDefinitions.append(col1)

        button.content = "Animate"
        button.click.addHandler { [weak self] _, _ in
            self?.run()
        }
        root.children.append(button)

        try? Grid.setColumn(rect, 1)
        rect.width = 50
        rect.height = 50
        rect.fill = accentBrush()
        rect.renderTransform = translate
        root.children.append(rect)

        anim.duration = seconds(0.5)
        anim.easingFunction = {
            let e = CircleEase()
            e.easingMode = .easeInOut
            return e
        }()

        _ = try? Storyboard.setTarget(anim, translate)
        _ = try? Storyboard.setTargetProperty(anim, "X")
        storyboard.children.append(anim)
    }

    private func run() {
        let fromV = translate.x
        let toV: Double = (fromV > 0) ? 0 : 200
        anim.from = fromV
        anim.to = toV
        safeBegin(storyboard, tag: "Example1")
    }
}

// ============================================================
// Example 2: ExponentialEase(EaseIn) + Exponent(NumberBox)
// ============================================================

private final class AccelerateEasingSampleView: Grid {

    let optionsPanel: UIElement

    private let root = Grid()
    private let button = Button()
    private let rect = Rectangle()
    private let translate = TranslateTransform()

    private let storyboard = Storyboard()
    private let anim = DoubleAnimation()
    private let ease = ExponentialEase()

    private let exponentBox = NumberBox()

    override init() {
        exponentBox.header = "Exponent"
        exponentBox.value = 4.5
        optionsPanel = exponentBox

        super.init()
        build()
    }

    private func build() {
        self.children.append(root)

        let col0 = ColumnDefinition()
        col0.width = GridLength(value: 1, gridUnitType: .auto)
        let col1 = ColumnDefinition()
        col1.width = GridLength(value: 1, gridUnitType: .star)
        col1.minWidth = 300

        root.columnDefinitions.append(col0)
        root.columnDefinitions.append(col1)

        button.content = "Animate"
        button.click.addHandler { [weak self] _, _ in
            self?.run()
        }
        root.children.append(button)

        try? Grid.setColumn(rect, 1)
        rect.width = 50
        rect.height = 50
        rect.fill = accentBrush()
        rect.renderTransform = translate
        root.children.append(rect)

        // storyboard
        anim.duration = seconds(0.15)
        ease.easingMode = .easeIn
        anim.easingFunction = ease

        _ = try? Storyboard.setTarget(anim, translate)
        _ = try? Storyboard.setTargetProperty(anim, "X")
        storyboard.children.append(anim)
    }

    private func run() {
        ease.exponent = exponentBox.value

        let fromV = translate.x
        let toV: Double = (fromV > 0) ? 0 : 200
        anim.from = fromV
        anim.to = toV
        safeBegin(storyboard, tag: "Example2")
    }
}

// ============================================================
// Example 3: ExponentialEase(EaseOut) + Exponent(NumberBox)
// ============================================================

private final class DecelerateEasingSampleView: Grid {

    let optionsPanel: UIElement

    private let root = Grid()
    private let button = Button()
    private let rect = Rectangle()
    private let translate = TranslateTransform()

    private let storyboard = Storyboard()
    private let anim = DoubleAnimation()
    private let ease = ExponentialEase()

    private let exponentBox = NumberBox()

    override init() {
        exponentBox.header = "Exponent"
        exponentBox.value = 7.0
        optionsPanel = exponentBox

        super.init()
        build()
    }

    private func build() {
        self.children.append(root)

        let col0 = ColumnDefinition()
        col0.width = GridLength(value: 1, gridUnitType: .auto)
        let col1 = ColumnDefinition()
        col1.width = GridLength(value: 1, gridUnitType: .star)
        col1.minWidth = 300

        root.columnDefinitions.append(col0)
        root.columnDefinitions.append(col1)

        button.content = "Animate"
        button.click.addHandler { [weak self] _, _ in
            self?.run()
        }
        root.children.append(button)

        try? Grid.setColumn(rect, 1)
        rect.width = 50
        rect.height = 50
        rect.fill = accentBrush()
        rect.renderTransform = translate
        root.children.append(rect)

        anim.duration = seconds(0.3)
        ease.easingMode = .easeOut
        anim.easingFunction = ease

        _ = try? Storyboard.setTarget(anim, translate)
        _ = try? Storyboard.setTargetProperty(anim, "X")
        storyboard.children.append(anim)
    }

    private func run() {
        ease.exponent = exponentBox.value

        let fromV = translate.x
        let toV: Double = (fromV > 0) ? 0 : 200
        anim.from = fromV
        anim.to = toV
        safeBegin(storyboard, tag: "Example3")
    }
}

// ============================================================
// Example 4: ComboBox 选择 easing + RadioButtons 选择 easingMode
// ============================================================

private final class OtherEasingSampleView: Grid {

    let optionsPanel: UIElement

    private let root = Grid()
    private let button = Button()
    private let rect = Rectangle()
    private let translate = TranslateTransform()

    private let storyboard = Storyboard()
    private let anim = DoubleAnimation()

    private let easingCombo = ComboBox()
    private let rbOut = RadioButton()
    private let rbIn = RadioButton()
    private let rbInOut = RadioButton()

    private let optionsStack = StackPanel()

    override init() {
        // options panel
        optionsStack.orientation = .vertical
        optionsStack.spacing = 8

        easingCombo.selectedIndex = 0
        easingCombo.items.append("BackEase")
        easingCombo.items.append("BounceEase")
        easingCombo.items.append("CircleEase")
        easingCombo.items.append("CubicEase")
        easingCombo.items.append("ElasticEase")
        easingCombo.items.append("ExponentialEase")
        easingCombo.items.append("PowerEase")
        easingCombo.items.append("QuadraticEase")
        easingCombo.items.append("QuarticEase")
        easingCombo.items.append("QuinticEase")
        easingCombo.items.append("SineEase")
        optionsStack.children.append(easingCombo)

        let radios = RadioButtons()
        rbOut.content = "EaseOut"
        rbOut.isChecked = true
        rbIn.content = "EaseIn"
        rbInOut.content = "EaseInOut"
        radios.items.append(rbOut)
        radios.items.append(rbIn)
        radios.items.append(rbInOut)
        optionsStack.children.append(radios)

        optionsPanel = optionsStack

        super.init()
        build()
    }

    private func build() {
        self.children.append(root)

        let col0 = ColumnDefinition()
        col0.width = GridLength(value: 1, gridUnitType: .auto)
        let col1 = ColumnDefinition()
        col1.width = GridLength(value: 1, gridUnitType: .star)
        col1.minWidth = 300

        root.columnDefinitions.append(col0)
        root.columnDefinitions.append(col1)

        button.content = "Animate"
        button.click.addHandler { [weak self] _, _ in
            self?.run()
        }
        root.children.append(button)

        try? Grid.setColumn(rect, 1)
        rect.width = 50
        rect.height = 50
        rect.fill = accentBrush()
        rect.renderTransform = translate
        root.children.append(rect)

        anim.duration = seconds(0.5)

        _ = try? Storyboard.setTarget(anim, translate)
        _ = try? Storyboard.setTargetProperty(anim, "X")
        storyboard.children.append(anim)
    }

    private func currentMode() -> EasingMode {
        if rbIn.isChecked == true { return .easeIn }
        if rbInOut.isChecked == true { return .easeInOut }
        return .easeOut
    }

    private func buildSelectedEase() -> EasingFunctionBase {
        let idx = Int(easingCombo.selectedIndex)
        let name = (idx >= 0 && idx < easingCombo.items.count) ? (easingCombo.items[idx] as? String ?? "BackEase") : "BackEase"
        let mode = currentMode()

        switch name {
        case "BounceEase":
            let e = BounceEase()
            e.easingMode = mode
            return e
        case "CircleEase":
            let e = CircleEase()
            e.easingMode = mode
            return e
        case "CubicEase":
            let e = CubicEase()
            e.easingMode = mode
            return e
        case "ElasticEase":
            let e = ElasticEase()
            e.easingMode = mode
            return e
        case "ExponentialEase":
            let e = ExponentialEase()
            e.easingMode = mode
            e.exponent = 6
            return e
        case "PowerEase":
            let e = PowerEase()
            e.easingMode = mode
            e.power = 6
            return e
        case "QuadraticEase":
            let e = QuadraticEase()
            e.easingMode = mode
            return e
        case "QuarticEase":
            let e = QuarticEase()
            e.easingMode = mode
            return e
        case "QuinticEase":
            let e = QuinticEase()
            e.easingMode = mode
            return e
        case "SineEase":
            let e = SineEase()
            e.easingMode = mode
            return e
        default:
            let e = BackEase()
            e.easingMode = mode
            return e
        }
    }

    private func run() {
        anim.easingFunction = buildSelectedEase()

        let fromV = translate.x
        let toV: Double = (fromV > 0) ? 0 : 200
        anim.from = fromV
        anim.to = toV
        safeBegin(storyboard, tag: "Example4")
    }
}
