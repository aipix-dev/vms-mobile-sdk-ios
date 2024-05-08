

import Foundation

// Quality options
public enum VideoQuality: String {
    case high = "camera_hd"                             //"Высокое качество"
    case low = "camera_sd"                              //"Стандартное качество"
}

public enum MarksOptions: String {
    case show = "show_all_marks"                        //"Отображать все"
    case dontShow = "marks_no_show"                     //"Не отображать"
}

public enum OptionsTitle: String {
    case marks = "events_and_marks"                     //"События и Метки"
    case speed = "speeds_title"                         //"Скорость воспроизведения"
    case marksList = "more_live_list"                   //"Список меток"
    case quality = "more_live_quality"                  //"Качество видео"
    case download = "download_archive"                  //Скачать архив
    case playbackProtocol = "video_playback_protocol"   // Протокол проигрывания видео
}

public enum VMSVideoEventOptions: Equatable {
    
    case all
    case types([String])
    case none
    
    public init(value: [String], fromTranslations: VMSPlayerTranslations) {
        switch value.first {
        case fromTranslations.translate(.MarksOptionsShow): self = .all
        case fromTranslations.translate(.MarksOptionsDontShow): self = .none
        default:
            self = .types(value)
        }
    }
    
    public func value(fromTranslations: VMSPlayerTranslations) -> [String] {
        switch self {
        case .all:
            return [fromTranslations.translate(.MarksOptionsShow)]
        case .none:
            return [fromTranslations.translate(.MarksOptionsDontShow)]
        case .types(let types):
            return types
        }
    }
}

public class VideoOptions {
    
    public enum OptionsViewType {
        case live(VMSStream.QualityType, Bool, VMSPlayerOptions.VMSPlayerType)
        case archive(Double, VMSVideoEventOptions, Bool, VMSPlayerOptions.VMSPlayerType)
        case quality(VMSStream.QualityType)
        case speed(Double, VMSStream.VideoCodec)
        case events(VMSVideoEventOptions)
        case playback(VMSPlayerOptions.VMSPlayerType)
    }
    
    public enum OptionsRowDataType {
        case eventsList
        case speed(Double)
        case events(VMSVideoEventOptions)
        case downloadArchive
        case quality(VMSStream.QualityType)
        case playback(VMSPlayerOptions.VMSPlayerType)
        
        public func title(fromTranslations: VMSPlayerTranslations) -> String {
            switch self {
            case .eventsList:
                return fromTranslations.translate(.MarksListTitle)
            case .speed(_):
                return fromTranslations.translate(.SpeedTitle)
            case .events(_):
                return fromTranslations.translate(.EventsAndMarks)
            case .downloadArchive:
                return fromTranslations.translate(.DownloadArchive)
            case .quality(_):
                return fromTranslations.translate(.QualityTitle)
            case .playback(_):
                return fromTranslations.translate(.PlayerProtocolSelection)
            }
        }
        
        public func details(fromTranslations: VMSPlayerTranslations, allMarkTypes: [VMSEventType]) -> String? {
            switch self {
            case .quality(let current):
                if current == .high {
                    return fromTranslations.translate(.VideoHDShort)
                }
                return fromTranslations.translate(.VideoSDShort)
            case .speed(let speed):
                if speed == 1 {
                    return fromTranslations.translate(.NormalSpeed)
                }
                return "\(speed)x"
            case .events(let type):
                switch type {
                case .types(let values):
                    let names = values.map { value in
                        if let markType = allMarkTypes.first(where: { $0.typeName() == value }) {
                            return fromTranslations.displayName(forMark: markType)
                        }
                        return ""
                    }
                    return names.joined(separator: ", ")
                default:
                    return type.value(fromTranslations: fromTranslations).joined(separator: ", ")
                }
            case .eventsList, .downloadArchive:
                return nil
            case .playback(let currentPlayback):
                return currentPlayback.rawValue.uppercased()
            }
        }
        
        public func imageName() -> String {
            switch self {
            case .eventsList:
                return "marks_list"
            case .speed(_):
                return "speed_template_black"
            case .events(_):
                return "mark"
            case .downloadArchive:
                return "download_archive"
            case .quality(let current):
                if current == .high {
                    return "hd_black"
                }
                return "sd_black"
            case .playback(_):
                return "bookmark_placeholder"
            }
        }
    }
    
    public enum OptionSeparationResult {
        case eventsList
        case speed
        case events
        case downloadArchive
        case quality
        case playback
        
        public init?(localizedString: String, fromTranslations: VMSPlayerTranslations) {
            switch localizedString {
            case fromTranslations.translate(.MarksListTitle): self = .eventsList
            case fromTranslations.translate(.SpeedTitle): self = .speed
            case fromTranslations.translate(.EventsAndMarks): self = .events
            case fromTranslations.translate(.DownloadArchive): self = .downloadArchive
            case fromTranslations.translate(.QualityTitle): self = .quality
            case fromTranslations.translate(.PlayerProtocolSelection): self = .playback
            default: return nil
            }
        }
    }
    
    public enum OptionSingleResult {
        case speed(Double)
        case quality(VideoQuality)
        case playback(VMSPlayerOptions.VMSPlayerType)
        
        public init?(value: String, fromTranslations: VMSPlayerTranslations) {
            switch value {
            case fromTranslations.translate(.VideoHDShort): self = .quality(.high)
            case fromTranslations.translate(.VideoSDShort): self = .quality(.low)
            case fromTranslations.translate(.NormalSpeed): self = .speed(1)
            case fromTranslations.translate(.RTSP): self = .playback(.rtspH264)
            case fromTranslations.translate(.HLS): self = .playback(.rtspH265)
            default:
                if value.contains("x") {
                    let speedString = value.replacingOccurrences(of: "x", with: "")
                    if let speed = Double(speedString) {
                        self = .speed(speed)
                    } else {
                        return nil
                    }
                } else {
                    return nil
                }
            }
        }
    }
    
    static func configure(
        type: OptionsViewType,
        viewModel: VMSPlayerViewModel,
        translations: VMSPlayerTranslations,
        allMarkTypes: [VMSEventType],
        allowVibration: Bool,
        videoRates: [Double]?,
        separationHandler: ((OptionSeparationResult) -> Void)? = nil,
        singleSelectionHandler: ((OptionSingleResult?) -> Void)? = nil,
        multiSelectionHandler: ((VMSVideoEventOptions) -> Void)? = nil
    ) -> VideoOptionsController {
        switch type {
        case .live(let quality, let enabled, let playback):
            let marksListRow = OptionsRowDataType.eventsList
            let qualityRow = OptionsRowDataType.quality(quality)
//            let playbackRow = OptionsRowDataType.playback(playback)
            var data: [VideoOptionSeparationData] = [
                VideoOptionSeparationData.init(title: marksListRow.title(fromTranslations: translations), imageName: marksListRow.imageName(), details: marksListRow.details(fromTranslations: translations, allMarkTypes: allMarkTypes)),
                VideoOptionSeparationData.init(title: qualityRow.title(fromTranslations: translations), imageName: qualityRow.imageName(), details: qualityRow.details(fromTranslations: translations, allMarkTypes: allMarkTypes), isDisabled: !enabled),
//                VideoOptionSeparationData.init(title: playbackRow.title(fromTranslations: translations), imageName: playbackRow.imageName(), details: playbackRow.details(fromTranslations: translations, allMarkTypes: allMarkTypes))
            ]
            
            if !viewModel.hasEventsPermissions() {
                data.remove(at: 0)
            }
            
            return VideoOptionsController.initialization(type: .separation(data), translations: translations, allowVibration: allowVibration) { result in
                guard let option = result.first else { return }
                separationHandler?(OptionSeparationResult.init(localizedString: option, fromTranslations: translations) ?? .eventsList)
            }
        case .archive(let speed, let eventTypes, let enableEventTypes, let playback):
            let marksListRow = OptionsRowDataType.eventsList
            let speedRow = OptionsRowDataType.speed(speed)
            let eventsRow = OptionsRowDataType.events(eventTypes)
            let downloadArchiveRow = OptionsRowDataType.downloadArchive
            //DISABLED BEFORE RTSP ARCHIVE IS NEED TO BE ENABLED
//            let playbackRow = OptionsRowDataType.playback(playback)
            
            var data: [VideoOptionSeparationData] = [
                VideoOptionSeparationData.init(title: marksListRow.title(fromTranslations: translations), imageName: marksListRow.imageName(), details: marksListRow.details(fromTranslations: translations, allMarkTypes: allMarkTypes)),
                VideoOptionSeparationData.init(title: speedRow.title(fromTranslations: translations), imageName: speedRow.imageName(), details: speedRow.details(fromTranslations: translations, allMarkTypes: allMarkTypes)),
                VideoOptionSeparationData.init(title: eventsRow.title(fromTranslations: translations), imageName: eventsRow.imageName(), details: eventsRow.details(fromTranslations: translations, allMarkTypes: allMarkTypes), isDisabled: !enableEventTypes),
                VideoOptionSeparationData.init(title: downloadArchiveRow.title(fromTranslations: translations), imageName: downloadArchiveRow.imageName(), details: downloadArchiveRow.details(fromTranslations: translations, allMarkTypes: allMarkTypes)),
                //DISABLED BEFORE RTSP ARCHIVE IS NEED TO BE ENABLED
//                VideoOptionSeparationData.init(title: playbackRow.title(fromTranslations: translations), imageName: playbackRow.imageName(), details: playbackRow.details(fromTranslations: translations, allMarkTypes: allMarkTypes))
            ]
            
            var controller: VideoOptionsController {
                get {
                    return VideoOptionsController.initialization(type: .separation(data), translations: translations, allowVibration: allowVibration) { result in
                        guard let option = result.first else { return }
                        separationHandler?(OptionSeparationResult.init(localizedString: option, fromTranslations: translations) ?? .eventsList)
                    }
                }
            }
            
            if !viewModel.hasEventsPermissions() {
                data.remove(at: [0, 2])
            } else if !viewModel.hasPermission(.MarksIndex) {
                data.remove(at: 2)
            }
            return controller
            
        case  .speed(let speed, let codec):
            var rates: [Double] = []
            if codec == .h265 {
                if let videoRates = videoRates {
                    var filtereRates = videoRates
                    filtereRates.removeAll(where: { $0 == 4.0 || $0 == 8.0 })
                    rates = filtereRates
                } else {
                    rates = [0.5,1,2]
                }
            } else {
                rates = videoRates ?? [0.5,1,2,4,8]
            }
            let newRates = rates.map { value in
                if value == 1 {
                    return translations.translate(.NormalSpeed)
                }
                return "\(value)x"
            }
            
            let chosenOption = {
                if speed == 1 {
                    return translations.translate(.NormalSpeed)
                }
                return "\(speed)x"
            }
            
            let speedRow = OptionsRowDataType.speed(speed)
            let speedData = VideoOptionSingleSelectionData.init(title: speedRow.title(fromTranslations: translations), imageName: speedRow.imageName(), options: newRates, chosenOption: "\(chosenOption())")
            return VideoOptionsController.initialization(type: .singleSelection(speedData), translations: translations, allowVibration: allowVibration) { result in
                guard let option = result.first else { return }
                singleSelectionHandler?(OptionSingleResult.init(value: option, fromTranslations: translations))
            }
        case .quality(let current):
            let choices = [translations.translate(.VideoHDShort), translations.translate(.VideoSDShort)]
            let qualityRow = OptionsRowDataType.quality(current)
            let qualityData = VideoOptionSingleSelectionData.init(title: qualityRow.title(fromTranslations: translations), imageName: qualityRow.imageName(), options: choices, chosenOption: qualityRow.details(fromTranslations: translations, allMarkTypes: allMarkTypes) ?? "")
            return VideoOptionsController.initialization(type: .singleSelection(qualityData), translations: translations, allowVibration: allowVibration) {result in
                guard let option = result.first else { return }
                singleSelectionHandler?(OptionSingleResult.init(value: option, fromTranslations: translations))
            }
        case .events(let type):
            var choices = VMSVideoEventOptions.all.value(fromTranslations: translations)
            for markType in allMarkTypes {
                choices.append(translations.displayName(forMark: markType))
            }
            choices.append(VMSVideoEventOptions.none.value(fromTranslations: translations).first ?? "")
            
            var chosen: [String] = []
            switch type {
            case .types(let values):
                chosen = values.map({ value in
                    if let type = allMarkTypes.first(where: { $0.typeName() == value }) {
                        return translations.displayName(forMark: type)
                    }
                    return ""
                })
            default: chosen = type.value(fromTranslations: translations)
            }
            
            let eventsRow = OptionsRowDataType.events(type)
            let eventsData = VideoOptionMultiSelectionData.init(title: eventsRow.title(fromTranslations: translations), imageName: eventsRow.imageName(), options: choices, chosenOptions: chosen, defaultOptions: [translations.translate(.MarksOptionsShow), translations.translate(.MarksOptionsDontShow)])
            return VideoOptionsController.initialization(type: .multiSelection(eventsData), translations: translations, allowVibration: allowVibration) { result in
                var chosen = VMSVideoEventOptions.all
                if result.first == VMSVideoEventOptions.none.value(fromTranslations: translations).first {
                    chosen = VMSVideoEventOptions.none
                } else if result.first != VMSVideoEventOptions.all.value(fromTranslations: translations).first {
                    let chosenTypes = result.map { displayName in
                        if let type = allMarkTypes.first(where: { markType in
                            return translations.displayName(forMark: markType) == displayName
                        }) {
                            return type.typeName()
                        }
                        return ""
                    }
                    chosen = VMSVideoEventOptions(value: chosenTypes, fromTranslations: translations)
                }
                multiSelectionHandler?(chosen)
            }
        case .playback(let curentPlayback):
            let choices = [translations.translate(.RTSP), translations.translate(.HLS)]
            let playbackRow = OptionsRowDataType.playback(curentPlayback)
            let chosen = curentPlayback == .rtspH264 ? choices[0] : choices[1]
            let playbackData = VideoOptionSingleSelectionData.init(title: playbackRow.title(fromTranslations: translations), imageName: playbackRow.imageName(), options: choices, chosenOption: chosen)
            return VideoOptionsController.initialization(type: .singleSelection(playbackData),  translations: translations, allowVibration: allowVibration) { result in
                guard let option = result.first else { return }
                singleSelectionHandler?(OptionSingleResult.init(value: option, fromTranslations: translations))
            }
        }
    }
}
