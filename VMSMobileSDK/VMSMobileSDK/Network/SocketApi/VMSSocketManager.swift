
import Foundation

public protocol VMSSocketManager {
    
    func isConnected() -> Bool
    func connect()
    func disconnect()
    func getSocketId() -> String?
}

public protocol VMSSocketManagerDelegate: AnyObject {
    
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState)
    func receivedError(error: PusherError)
    func receivedAppSocket(socket: VMSAppSocketData)
    func receivedIntercomSocket(socket: VMSIntercomSocketData)
    func receivedInfo(message: String)
}

public extension VMSSocketManagerDelegate {
    
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        // Optional method
    }
    func receivedError(error: PusherError) {
        // Optional method
    }
    
    func receivedInfo(message: String) {
        // Optional method
    }
}
