
import Foundation

public class VMSPlayerTranslations {
    
    open var dict: VMSTranslationDict
    
    public init(translations: VMSTranslationDict) {
        dict = [:]
        dict[DictKeys.StreamNotAvailable.rawValue] = translations[DictKeys.StreamNotAvailable.rawValue]
        dict[DictKeys.ErrCameraUnavailalbe.rawValue] = translations[DictKeys.ErrCameraUnavailalbe.rawValue]
        dict[DictKeys.ErrCameraInitLong.rawValue] = translations[DictKeys.ErrCameraInitLong.rawValue]
        dict[DictKeys.ErrCameraStreamsUnavailable.rawValue] = translations[DictKeys.ErrCameraStreamsUnavailable.rawValue]
        dict[DictKeys.ErrCantLoadArchive.rawValue] = translations[DictKeys.ErrCantLoadArchive.rawValue]
        dict[DictKeys.ErrCommonShort.rawValue] = translations[DictKeys.ErrCommonShort.rawValue]
        dict[DictKeys.ErrDevicePerformance.rawValue] = translations[DictKeys.ErrDevicePerformance.rawValue]
        dict[DictKeys.ErrLiveRestrictedShort.rawValue] = translations[DictKeys.ErrLiveRestrictedShort.rawValue]
        dict[DictKeys.ErrArchiveRestricted.rawValue] = translations[DictKeys.ErrArchiveRestricted.rawValue]
        dict[DictKeys.ErrStreamUnavailable.rawValue] = translations[DictKeys.ErrStreamUnavailable.rawValue]
        dict[DictKeys.ErrArchiveUnavailable.rawValue] = translations[DictKeys.ErrArchiveUnavailable.rawValue]
        dict[DictKeys.ErrCameraInit.rawValue] = translations[DictKeys.ErrCameraInit.rawValue]
        dict[DictKeys.CameraBlocked.rawValue] = translations[DictKeys.CameraBlocked.rawValue]
        dict[DictKeys.ErrInThisMoment.rawValue] = translations[DictKeys.ErrInThisMoment.rawValue]
        dict[DictKeys.ItTakesTimeToGenerateArchive.rawValue] = translations[DictKeys.ItTakesTimeToGenerateArchive.rawValue]
        dict[DictKeys.ArchiveFormatError.rawValue] = translations[DictKeys.ArchiveFormatError.rawValue]
        dict[DictKeys.ArchivePeriodError.rawValue] = translations[DictKeys.ArchivePeriodError.rawValue]
        dict[DictKeys.ServerError.rawValue] = translations[DictKeys.ServerError.rawValue]
        dict[DictKeys.ErrNoArchiveDate.rawValue] = translations[DictKeys.ErrNoArchiveDate.rawValue]
        dict[DictKeys.MarkUpdateFailed.rawValue] = translations[DictKeys.MarkUpdateFailed.rawValue]
        dict[DictKeys.MarkCreateFailed.rawValue] = translations[DictKeys.MarkCreateFailed.rawValue]
        dict[DictKeys.TitleNoWifi.rawValue] = translations[DictKeys.TitleNoWifi.rawValue]
        dict[DictKeys.MessageNoWifi.rawValue] = translations[DictKeys.MessageNoWifi.rawValue]
        
        dict[DictKeys.InactiveCameraTitle.rawValue] = translations[DictKeys.InactiveCameraTitle.rawValue]
        dict[DictKeys.InactiveCameraMessage.rawValue] = translations[DictKeys.InactiveCameraMessage.rawValue]
        
        dict[DictKeys.NoNewerMarks.rawValue] = translations[DictKeys.NoNewerMarks.rawValue]
        dict[DictKeys.NoOlderMarks.rawValue] = translations[DictKeys.NoOlderMarks.rawValue]
        dict[DictKeys.OlderMarksNotAvailable.rawValue] = translations[DictKeys.OlderMarksNotAvailable.rawValue]
        
        
        dict[DictKeys.MarkEmptyTitle.rawValue] = translations[DictKeys.MarkEmptyTitle.rawValue]
        dict[DictKeys.MarkNewTitle.rawValue] = translations[DictKeys.MarkNewTitle.rawValue]
        dict[DictKeys.MarkCreateTitle.rawValue] = translations[DictKeys.MarkCreateTitle.rawValue]
        dict[DictKeys.MarkCreateDate.rawValue] = translations[DictKeys.MarkCreateDate.rawValue]
        
        dict[DictKeys.DownloadArchive.rawValue] = translations[DictKeys.DownloadArchive.rawValue]
        dict[DictKeys.ChooseTime.rawValue] = translations[DictKeys.ChooseTime.rawValue]
        dict[DictKeys.ArchiveDownloadStartTime.rawValue] = translations[DictKeys.ArchiveDownloadStartTime.rawValue]
        dict[DictKeys.ArchiveDownloadEndTime.rawValue] = translations[DictKeys.ArchiveDownloadEndTime.rawValue]
        dict[DictKeys.HoursTitle.rawValue] = translations[DictKeys.HoursTitle.rawValue]
        dict[DictKeys.MinutesTitle.rawValue] = translations[DictKeys.MinutesTitle.rawValue]
        dict[DictKeys.SecondsTitle.rawValue] = translations[DictKeys.SecondsTitle.rawValue]
        dict[DictKeys.DownloadArchiveTitle.rawValue] = translations[DictKeys.DownloadArchiveTitle.rawValue]
        dict[DictKeys.DownloadArchiveDescription.rawValue] = translations[DictKeys.DownloadArchiveDescription.rawValue]
        
        dict[DictKeys.Monday.rawValue] = translations[DictKeys.Monday.rawValue]
        dict[DictKeys.Tuesday.rawValue] = translations[DictKeys.Tuesday.rawValue]
        dict[DictKeys.Wednesday.rawValue] = translations[DictKeys.Wednesday.rawValue]
        dict[DictKeys.Thursday.rawValue] = translations[DictKeys.Thursday.rawValue]
        dict[DictKeys.Friday.rawValue] = translations[DictKeys.Friday.rawValue]
        dict[DictKeys.Saturday.rawValue] = translations[DictKeys.Saturday.rawValue]
        dict[DictKeys.Sunday.rawValue] = translations[DictKeys.Sunday.rawValue]
        
        dict[DictKeys.Seconds.rawValue] = translations[DictKeys.Seconds.rawValue]
        dict[DictKeys.Minute.rawValue] = translations[DictKeys.Minute.rawValue]
        dict[DictKeys.Hour.rawValue] = translations[DictKeys.Hour.rawValue]
        dict[DictKeys.Day.rawValue] = translations[DictKeys.Day.rawValue]
        
        dict[DictKeys.CheckDone.rawValue] = translations[DictKeys.CheckDone.rawValue]
        dict[DictKeys.Done.rawValue] = translations[DictKeys.Done.rawValue]
        dict[DictKeys.Cancel.rawValue] = translations[DictKeys.Cancel.rawValue]
        dict[DictKeys.Continue.rawValue] = translations[DictKeys.Continue.rawValue]
        dict[DictKeys.Ok.rawValue] = translations[DictKeys.Ok.rawValue]
        dict[DictKeys.ApplySelected.rawValue] = translations[DictKeys.ApplySelected.rawValue]
        dict[DictKeys.Saved.rawValue] = translations[DictKeys.Saved.rawValue]
        dict[DictKeys.Share.rawValue] = translations[DictKeys.Share.rawValue]
        dict[DictKeys.Live.rawValue] = translations[DictKeys.Live.rawValue]
        dict[DictKeys.Archive.rawValue] = translations[DictKeys.Archive.rawValue]
        dict[DictKeys.PlayerProtocolSelection.rawValue] = translations[DictKeys.PlayerProtocolSelection.rawValue]
        dict[DictKeys.RTSP.rawValue] = translations[DictKeys.RTSP.rawValue]
        dict[DictKeys.HLS.rawValue] = translations[DictKeys.HLS.rawValue]
        
        dict[DictKeys.MarksOptionsShow.rawValue] = translations[DictKeys.MarksOptionsShow.rawValue]
        dict[DictKeys.MarksOptionsDontShow.rawValue] = translations[DictKeys.MarksOptionsDontShow.rawValue]
        dict[DictKeys.MarksListTitle.rawValue] = translations[DictKeys.MarksListTitle.rawValue]
        dict[DictKeys.SpeedTitle.rawValue] = translations[DictKeys.SpeedTitle.rawValue]
        dict[DictKeys.EventsAndMarks.rawValue] = translations[DictKeys.EventsAndMarks.rawValue]
        dict[DictKeys.QualityTitle.rawValue] = translations[DictKeys.QualityTitle.rawValue]
        dict[DictKeys.VideoHDShort.rawValue] = translations[DictKeys.VideoHDShort.rawValue]
        dict[DictKeys.VideoSDShort.rawValue] = translations[DictKeys.VideoSDShort.rawValue]
        dict[DictKeys.NormalSpeed.rawValue] = translations[DictKeys.NormalSpeed.rawValue]
        dict[DictKeys.UsersMarks.rawValue] = translations[DictKeys.UsersMarks.rawValue]
        
        dict[DictKeys.DeleteScreenshot.rawValue] = translations[DictKeys.DeleteScreenshot.rawValue]
    }
    
    public enum DictKeys: String {
        case StreamNotAvailable = "stream_currently_not_available"
        case ErrCameraUnavailalbe = "err_camera_unavailable"
        case ErrCameraInitLong = "err_camera_init_long"
        case ErrCameraStreamsUnavailable = "err_camera_streams_unavailable"
        case ErrCantLoadArchive = "err_cant_load_archive"
        case ErrCommonShort = "err_common_short"
        case ErrDevicePerformance = "err_device_performance"
        case ErrLiveRestrictedShort = "restricted_live_error_short"
        case ErrArchiveRestricted = "restricted_archive_error"
        case ErrStreamUnavailable = "err_stream_video_unavailable"
        case ErrArchiveUnavailable = "err_archive_unavailable"
        case ErrCameraInit = "err_camera_init"
        case CameraBlocked = "camera_locked"
        case ErrInThisMoment = "err_in_this_moment"
        case ItTakesTimeToGenerateArchive = "it_takes_time_to_generate_archive"
        case ArchiveFormatError = "archive_format_error"
        case ArchivePeriodError = "archive_interval_error"
        case ServerError = "server_error"
        case ErrNoArchiveDate = "err_no_archive_date"
        case MarkCreateFailed = "mark_created_fail"
        case MarkUpdateFailed = "mark_updated_fail"
        case TitleNoWifi = "title_no_wifi"
        case MessageNoWifi = "mess_no_wifi"
        
        case InactiveCameraTitle = "inactive_camera_title"
        case InactiveCameraMessage = "inactive_camera_msg"
        
        case NoNewerMarks = "no_newer_marks"
        case NoOlderMarks = "no_older_marks"
        case OlderMarksNotAvailable = "older_marks_not_available"
        
        case MarkEmptyTitle = "mark_empty_title"
        case MarkNewTitle = "mark_new_title"
        case MarkCreateTitle = "mark_create_title"
        case MarkCreateDate = "mark_create_date"
        
        case Monday = "mon"
        case Tuesday = "tue"
        case Wednesday = "wed"
        case Thursday = "thu"
        case Friday = "fri"
        case Saturday = "sat"
        case Sunday = "sun"
        
        case Minute = "minute"
        case Seconds = "seconds"
        case Hour = "hour"
        case Day = "day"
        
        case DownloadArchive = "download_archive"
        case ChooseTime = "choose_time"
        case ArchiveDownloadStartTime = "download_archive_start"
        case ArchiveDownloadEndTime = "download_archive_end"
        case HoursTitle = "hours_big"
        case MinutesTitle = "minutes_big"
        case SecondsTitle = "seconds_big"
        case DownloadArchiveTitle = "download_archive_title"
        case DownloadArchiveDescription = "download_archive_description"
        
        case CheckDone = "check_done"
        case Done = "done"
        case Cancel = "cancel"
        case Continue = "continue_text"
        case Ok = "ok"
        case ApplySelected = "apply_selected"
        case Saved = "saved"
        case Share = "list_screenshot_actions_share"
        case Archive = "archive"
        case Live = "live"
        case PlayerProtocolSelection = "select_video_playback_protocol"
        case RTSP = "player_with_minimal_delay"
        case HLS = "player_with_buffering"
        
        case MarksOptionsShow = "show_all_marks"
        case MarksOptionsDontShow = "marks_no_show"
        case MarksListTitle = "more_live_list"
        case SpeedTitle = "speeds_title"
        case EventsAndMarks = "events_and_marks"
        case QualityTitle = "more_live_quality"
        case VideoHDShort = "camera_hd_short"
        case VideoSDShort = "camera_sd_short"
        case NormalSpeed = "speeds_normal"
        case UsersMarks = "users_marks"
        
        case DeleteScreenshot = "list_screenshot_actions_delete"
    }
    
    public func translate(_ key: DictKeys) -> String {
        return dict[key.rawValue] ?? "No localized text for key \(key.rawValue)"
    }
    
    // Translate marks
    
    public func displayName(forMark mark: VMSEventType) -> String {
        if mark.name == VMSEventType.defaultType {
            return self.translate(.UsersMarks)
        }
        return mark.titleName()
    }
    
    public func markType(forMarkName name: String) -> String {
        if name == self.translate(.UsersMarks) {
            return VMSEventType.defaultType
        }
        return name
    }
    
}
