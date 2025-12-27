import WinUI
import WinAppSDK

class ThemeTransitionsPage: Grid {
    // MARK: - Initialization
    override init() {
        super.init()
        setupView()
    }

    private func setupView() {
        let textBlock = TextBlock()
        textBlock.text = "Welcome to the ThemeTransitionsPage"
        textBlock.fontSize = 24
        textBlock.horizontalAlignment = .center
        textBlock.verticalAlignment = .center

        self.children.append(textBlock)
    }
}