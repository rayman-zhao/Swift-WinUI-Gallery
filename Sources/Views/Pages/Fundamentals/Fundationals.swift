import WinUI
import WinAppSDK

class FundamentalsPage: StackPanel {
    // MARK: - Initialization
    override init() {
        super.init()
        setupView()
    }
    
    private func setupView() {
        // 设置面板属性
        self.horizontalAlignment = .center
        self.verticalAlignment = .center
        
        // 创建文本
        let text = TextBlock()
        text.text = "Fundamentals"
        text.fontSize = 48
        text.horizontalAlignment = .center
        
        self.children.append(text)
    }
}