

import Foundation

public struct VMSOpenPlayerOptions {
    
    public enum VMSOpenPlayerType {
        case live
        case archive
        case none
    }
    
    let event: VMSEvent?
    var archiveDate: Date?
    var isEventArchive = false
    var showEventEdit = false
    var popNavigationAfterEventEdit = false
    var pushEventsListAfterEventEdit = false
    var openPlayerType: VMSOpenPlayerType = .none
    var markOptions: VMSOpenPlayerMarkOptions
    let isLiveRestricted: Bool
    
    /// Initialize additional parameters for opening player
    /// - parameter event: Event you want to show / edit in player
    ///     Parameter isEventArchive will be set to yes automatically
    ///
    /// - parameter archiveDate:Set date if you need to open archive at specific date
    ///
    /// - parameter showEventEdit: Set this parameter to `true` if you want to open event editing sceen. Event should be set as well
    ///
    /// - parameter popNavigationAfterEventEdit: Set this parameter to `true` if you want player controller to be poped after saving or canceling event editing
    ///
    /// - parameter pushEventsListAfterEventEdit: Set this parameter to `true` if you want to show events list screen after saving or canceling event editing
    ///
    /// - parameter openPlayerType: Set this parameter to true if you want to change allready opened player to archive or live in player controller. Default is `none`
    ///
    /// - parameter markOptions: mark filterind settings. Marks in player will be filtered. "Show all" by default
    ///
    /// - parameter isLiveRestricted: hide possibility to show live in player, default is `false`

    
    public init(
        event: VMSEvent?,
        archiveDate: Date?,
        showEventEdit: Bool,
        popNavigationAfterEventEdit: Bool,
        pushEventsListAfterEventEdit: Bool,
        openPlayerType: VMSOpenPlayerType = .none,
        markOptions: VMSOpenPlayerMarkOptions? = nil,
        isLiveRestricted: Bool = false
    ) {
        self.event = event
        if event != nil || archiveDate != nil {
            self.isEventArchive = true
        }
        self.archiveDate = archiveDate
        self.openPlayerType = openPlayerType
        self.showEventEdit = showEventEdit
        self.popNavigationAfterEventEdit = popNavigationAfterEventEdit
        self.pushEventsListAfterEventEdit = pushEventsListAfterEventEdit
        self.markOptions = markOptions ?? VMSOpenPlayerMarkOptions(chosenMarksFilter: [], disableOption: false)
        self.isLiveRestricted = isLiveRestricted
    }
    
    init() {
        event = nil
        archiveDate = nil
        markOptions = VMSOpenPlayerMarkOptions(chosenMarksFilter: [], disableOption: false)
        isLiveRestricted = false
    }
}

public struct VMSOpenPlayerMarkOptions {
    
    var chosenMarksFilter: [VMSEventType]
    var disableOption: Bool
    
    public init(chosenMarksFilter: [VMSEventType], disableOption: Bool = false) {
        self.chosenMarksFilter = chosenMarksFilter
        self.disableOption = disableOption
    }
}
