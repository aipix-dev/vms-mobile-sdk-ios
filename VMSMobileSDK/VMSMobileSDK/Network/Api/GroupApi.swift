
import Foundation
import Alamofire

public protocol GroupApi {
    
    func getGroupsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCameraGroup>>)
    
    func createGroup(with name: String, completion: @escaping VMSResultBlock<VMSCameraGroup>)
    
    func renameGroup(with id: Int, newName: String, completion: @escaping VMSResultBlock<VMSCameraGroup>)
    
    func updateGroup(info: VMSUpdateGroupRequest, completion: @escaping VMSResultBlock<VMSCameraGroup>)
    
    func deleteGroup(with id: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
    
    func syncGroups(for cameraId: Int, groupIds: [Int], completion: @escaping VMSResultBlock<VMSTypeGroupResponse>)
}

extension VMS: GroupApi {
    
    public func getGroupsList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCameraGroup>>) {
        
        self.request(
            path: ApiPaths.Cameras.Groups,
            method: HTTPMethod.get,
            parameters: ["page" : page]
        ) { [weak self] (response: VMSApiResult<Any>) in
            
            switch response {
            case .success(let object):
                guard let self else { return }
                completion(self.decode(data: object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func createGroup(with name: String, completion: @escaping VMSResultBlock<VMSCameraGroup>) {
        
        let params: Parameters = ["name" : name]
        
        self.request(
            path: ApiPaths.Cameras.Groups,
            method: .post,
            parameters: params
        ) { [weak self] (response: VMSApiResult<Any>) in
            switch response {
            case .success(let object):
                guard let self else { return }
                completion(self.decode(data: object))
            case .failure(let error):
                completion(.failure(error))
            }
            
        }
    }
    
    public func renameGroup(with id: Int, newName: String, completion: @escaping VMSResultBlock<VMSCameraGroup>) {
        let newName: Parameters = ["name" : newName]
        
        self.request(
            path: ApiPaths.Cameras.accessGroup(groupId: id),
            method: .put,
            parameters: newName
        ) { [weak self] (response: VMSApiResult<Any>) in
            switch response {
            case .success(let object):
                guard let self else { return }
                completion(self.decode(data: object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func deleteGroup(with id: Int, completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        self.request(
            path: ApiPaths.Cameras.accessGroup(groupId: id),
            method: .delete
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func updateGroup(info: VMSUpdateGroupRequest, completion: @escaping VMSResultBlock<VMSCameraGroup>) {
        
        let params: Parameters = [
            "name" : info.groupName,
            "items" : info.cameraIds
        ]
        
        self.request(
            path: ApiPaths.Cameras.accessGroup(groupId: info.groupId),
            method: .put,
            parameters: params
        ) { [weak self] (response: VMSApiResult<Any>) in
            switch response {
            case .success(let object):
                guard let self else { return }
                completion(self.decode(data: object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func syncGroups(for cameraId: Int, groupIds: [Int], completion: @escaping VMSResultBlock<VMSTypeGroupResponse>) {
        
        let params: Parameters = ["groups" : groupIds]
        
        self.request(
            path: ApiPaths.Cameras.groupsSync(id: cameraId),
            method: .post,
            parameters: params
        ) { [weak self] (response: VMSApiResult<Any>) in
            
            switch response {
            case .success(let object):
                guard let self else { return }
                completion(self.decode(data: object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
