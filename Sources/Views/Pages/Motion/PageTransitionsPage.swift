import WinUI
import WinAppSDK

class PageTransitionsPage: Grid {
    // MARK: - Initialization
    override init() {
        super.init()
        setupView()
    }

    private func setupView() {
        let textBlock = TextBlock()
        textBlock.text = "Welcome to the PageTransitionsPage"
        textBlock.fontSize = 24
        textBlock.horizontalAlignment = .center
        textBlock.verticalAlignment = .center

        self.children.append(textBlock)
    }
}