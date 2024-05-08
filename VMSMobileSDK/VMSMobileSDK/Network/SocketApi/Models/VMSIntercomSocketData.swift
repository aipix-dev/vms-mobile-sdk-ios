
import Foundation

public enum VMSIntercomPushTypes: String, Decodable {
    
    case rename = "intercom.rename"
    case update = "intercom.update"
    case delete = "intercom.delete"
    case store = "intercom.store"
    case keyConfirmed = "intercom.key_confirmed"
    case keyError = "intercom.key_error"
    case addError = "intercom.add_error"
    case codeStore = "intercom.code.store"
    case codeDelete = "intercom.code.delete"
    case eventStore = "analytic_case_face_event_created"
    case callStore = "intercom.call.store"
    case callDelete = "intercom.call.delete"
    case cancelCall = "intercom_cancel"
}

public enum VMSIntercomSocketData {
    
    case intercomCodeStored(VMSIntercomCode?)
    case intercomCallStored(VMSIntercomCall?)
    case intercomStored(VMSIntercom?)
    case intercomEventStored(VMSEvent?)
    case intercomKeyConfirmed(VMSIntercom?)
    case intercomRenamed(VMSIntercom?)
    case intercomUpdated(VMSIntercom?)
    case intercomsDeleted(VMSIntercomDeleteSocket?)
    case intercomCodesDeleted(VMSIntercomDeleteSocket?)
    case intercomCallsDeleted(VMSIntercomDeleteSocket?)
    case intercomKeyError(VMSIntercomErrorSocket?)
    case intercomAddError(VMSIntercomErrorSocket?)
    case intercomCallCanceled(VMSCanceledCall?)
}

final class VMSIntercomPushData: Decodable {
    
    var type: VMSIntercomPushTypes!
    var error: String?
    var intercom: VMSIntercom?
    var intercomCode: VMSIntercomCode?
    var intercomCall: VMSIntercomCall?
    var deletedIds: [Int]?
    var data: VMSCanceledCall?
    var event: VMSEvent?
}

public struct VMSIntercomDeleteSocket: Decodable {
    public let deletedIds: [Int]?
}

public struct VMSIntercomErrorSocket: Decodable {
    public let error: String?
}

public final class VMSCanceledCall: Decodable {
    
    public let id: Int
    public var title: String?
    public var address: String?
    public var callId: Int!

}
