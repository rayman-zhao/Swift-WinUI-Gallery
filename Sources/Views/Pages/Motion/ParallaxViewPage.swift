import WinUI
import WinAppSDK

class ParallaxViewPage: Grid {
    // MARK: - Initialization
    override init() {
        super.init()
        setupView()
    }

    private func setupView() {
        let textBlock = TextBlock()
        textBlock.text = "Welcome to the ParallaxViewPage"
        textBlock.fontSize = 24
        textBlock.horizontalAlignment = .center
        textBlock.verticalAlignment = .center

        self.children.append(textBlock)
    }
}