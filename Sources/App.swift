import WinAppSDK
import WinUI

@main
class App: SwiftApplication {
    override required init() {
        super.init()
    }    
    override func onLaunched(_ args: WinUI.LaunchActivatedEventArgs) {
        self.requestedTheme = ApplicationTheme.light

        let window: Window = MainWindow()
        try! window.activate()
    }
}

