
import Foundation

enum VideoOptionType: Equatable {
    
    case separation([VideoOptionSeparationData])
    case singleSelection(VideoOptionSingleSelectionData)
    case multiSelection(VideoOptionMultiSelectionData)
    
    static func == (lhs: VideoOptionType, rhs: VideoOptionType) -> Bool {
        switch (lhs, rhs) {
        case (.separation, .separation):
            return true
        case (.singleSelection, .singleSelection):
            return true
        case (.multiSelection, .multiSelection):
            return true
        default:
            return false
        }
    }
}

class VideoOptionSeparationData {
    
    var title: String
    var imageName: String?
    var details: String?
    var isDisabled: Bool = false
    
    init(title: String, imageName: String? = nil, details: String? = nil, isDisabled: Bool = false) {
        self.title = title
        self.imageName = imageName
        self.details = details
        self.isDisabled = isDisabled
    }
}

class VideoOptionSingleSelectionData {
    var title: String?
    var imageName: String?
    var options: [String]
    var chosenOption: String
    
    init(title: String?, imageName: String? = nil, options: [String], chosenOption: String) {
        self.title = title
        self.imageName = imageName
        self.options = options
        self.chosenOption = chosenOption
    }
}

class VideoOptionMultiSelectionData {
    var title: String?
    var imageName: String?
    var options: [String]
    var chosenOptions: [String]
    
    //  When selecting default option remove other selections
    var defaultOptions: [String]
    
    init(title: String?, imageName: String? = nil, options: [String], chosenOptions: [String], defaultOptions: [String]) {
        self.title = title
        self.imageName = imageName
        self.options = options
        self.chosenOptions = chosenOptions
        self.defaultOptions = defaultOptions
    }
}
