import Foundation
import WinUI
import WinSDK
import UWP
import WindowsFoundation
import CppWinRT

class AutoSuggestBoxPage: Page {
    private var pageRootGrid: Grid = Grid()
    private var exampleStackPanel: StackPanel = StackPanel()
    private var headerGrid: Grid = Grid()
    private var bodyScrollViewer: ScrollViewer = ScrollViewer()

    private var cats: [String] = [
        "Abyssinian",
        "Aegean",
        "American Bobtail",
        "American Curl",
        "American Ringtail",
        "American Shorthair",
        "American Wirehair",
        "Aphrodite Giant",
        "Arabian Mau",
        "Asian cat",
        "Asian Semi-longhair",
        "Australian Mist",
        "Balinese",
        "Bambino",
        "Bengal",
        "Birman",
        "Brazilian Shorthair",
        "British Longhair",
        "British Shorthair",
        "Burmese",
        "Burmilla",
        "California Spangled",
        "Chantilly-Tiffany",
        "Chartreux",
        "Chausie",
        "Colorpoint Shorthair",
        "Cornish Rex",
        "Cymric",
        "Cyprus",
        "Devon Rex",
        "Donskoy",
        "Dragon Li",
        "Dwelf",
        "Egyptian Mau",
        "European Shorthair",
        "Exotic Shorthair",
        "Foldex",
        "German Rex",
        "Havana Brown",
        "Highlander",
        "Himalayan",
        "Japanese Bobtail",
        "Javanese",
        "Kanaani",
        "Khao Manee",
        "Kinkalow",
        "Korat",
        "Korean Bobtail",
        "Korn Ja",
        "Kurilian Bobtail",
        "Lambkin",
        "LaPerm",
        "Lykoi",
        "Maine Coon",
        "Manx",
        "Mekong Bobtail",
        "Minskin",
        "Napoleon",
        "Munchkin",
        "Nebelung",
        "Norwegian Forest Cat",
        "Ocicat",
        "Ojos Azules",
        "Oregon Rex",
        "Persian (modern)",
        "Persian (traditional)",
        "Peterbald",
        "Pixie-bob",
        "Ragamuffin",
        "Ragdoll",
        "Raas",
        "Russian Blue",
        "Russian White",
        "Sam Sawet",
        "Savannah",
        "Scottish Fold",
        "Selkirk Rex",
        "Serengeti",
        "Serrade Petit",
        "Siamese",
        "Siberian or´Siberian Forest Cat",
        "Singapura",
        "Snowshoe",
        "Sokoke",
        "Somali",
        "Sphynx",
        "Suphalak",
        "Thai",
        "Thai Lilac",
        "Tonkinese",
        "Toyger",
        "Turkish Angora",
        "Turkish Van",
        "Turkish Vankedisi",
        "Ukrainian Levkoy",
        "Wila Krungthep",
        "York Chocolate"
    ]

    override init() {
        super.init()
        setupPageUI()
        setupHeader()
        setupBody()
    }

    private func setupPageUI() {
        self.padding = Thickness(left: 36, top: 36, right: 36, bottom: 0)

        let row1: RowDefinition = RowDefinition()
        row1.height = GridLength(value: 1, gridUnitType: GridUnitType.auto)
        pageRootGrid.rowDefinitions.append(row1)
        let row2: RowDefinition = RowDefinition()
        row2.height = GridLength(value: 1, gridUnitType: GridUnitType.star)
        pageRootGrid.rowDefinitions.append(row2)

        try! Grid.setRow(headerGrid, 0)
        pageRootGrid.children.append(headerGrid)

        try! Grid.setRow(bodyScrollViewer, 1)
        pageRootGrid.children.append(bodyScrollViewer)

        self.content = pageRootGrid
    }

    private func setupHeader() {
        let controlInfo = ControlInfo(
            title: "AutoSuggestbox",
            apiNamespace: "Microsoft.UI.Xaml.Controls",
            baseClasses: [
                "Object",
                "DependencyObject",
                "UIElement",
                "FrameworkElement",
                "Control"
            ],
            docs: [
                ControlInfoDocLink(
                    title: "AutoSuggestbox-API",
                    uri: "https://learn.microsoft.com/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.controls.autosuggestbox"
                ),
                ControlInfoDocLink(
                    title: "Guidelines",
                    uri: "https://learn.microsoft.com/zh-cn/windows/apps/develop/ui/controls/auto-suggest-box"
                )
            ]
        )
        let pageHeader: PageHeader = PageHeader(item: controlInfo)
        pageHeader.themeButtonVisibility = .visible
        pageHeader.margin = Thickness(left: 36, top: 36, right: 36, bottom: 0)
        self.headerGrid.children.append(pageHeader)
    }

    private func setupBody() {
        self.bodyScrollViewer.margin = Thickness(left: 36, top: 0, right: 36, bottom: 0)
        // self.bodyScrollViewer.row = 1
        let bodyStackPanel = StackPanel()
        bodyStackPanel.spacing = 8
        bodyStackPanel.orientation = .vertical
        let descText = TextBlock()
        descText.text = """
        A text control that makes suggestions to users as they type. The app is notified when text has been changed by the user ans is responsible for providing relevant suggestions for this control to display.
        """
        bodyStackPanel.children.append(descText)

        let basicControlExample = ControlExample()
        let tb = TextBlock()
        basicControlExample.output = tb
        basicControlExample.headerText = "A basic autosuggest box"
        let basicAutoSuggestbox = AutoSuggestBox()
        basicAutoSuggestbox.height = 50
        basicAutoSuggestbox.width = 300
        basicAutoSuggestbox.horizontalAlignment = .left

        basicAutoSuggestbox.textChanged.addHandler { [weak self] sender, args in
            guard args?.reason == .userInput,
                  let cats = self?.cats,
                  let sender = sender else { return }
            debugPrint("[AutoSuggestBoxPage--setupBody]: textChanged func has been called")
            let query = sender.text.lowercased()
            let tokens = query
                .split(separator: " ", omittingEmptySubsequences: true)
                .map(String.init)
            if tokens.isEmpty {
                sender.isSuggestionListOpen = false
                return
            }
            let filtered = cats.filter { cat in
                let lowerCat = cat.lowercased()
                return tokens.allSatisfy { key in lowerCat.contains(key) }
            }
            let suggestions = filtered.isEmpty ? ["No results found"] : filtered
            debugPrint("[AutoSuggestBoxPage--setupBody]: suggestions: \(suggestions)")
            sender.itemsSource = single_threaded_vector_inspectable(suggestions)
        }

        basicAutoSuggestbox.suggestionChosen.addHandler { _, args in
            tb.text = (args?.selectedItem as? String) ?? ""
        }

        basicControlExample.example = basicAutoSuggestbox
        bodyStackPanel.children.append(basicControlExample.view)

        self.bodyScrollViewer.content = bodyStackPanel
    }
}
