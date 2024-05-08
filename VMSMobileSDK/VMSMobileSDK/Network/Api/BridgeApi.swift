//
//  BridgeApi.swift
//  VMSMobileSDK
//
//  Created by Olga Podoliakina on 4.01.24.
//

import Foundation
import Alamofire

public protocol BridgeApi {
    
    func getBridgesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSBridge>>)
    
    func createBridge(request: VMSBridgeCreateRequest, completion: @escaping VMSResultBlock<VMSBridge>)
    
    func updateBridge(with id: Int, name: String, completion: @escaping VMSResultBlock<VMSBridge>)
    
    func getBridge(with id: Int, completion: @escaping VMSResultBlock<VMSBridge>)
    
    func getBridgeCameras(bridgeId: Int, page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>)
    
    func deleteBridgeCamera(with bridgeId: Int, cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
    
}

extension VMS: BridgeApi {
    
    public func getBridgesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSBridge>>) {
        
        let params: Parameters = [
            "page" : page
        ]
        
        self.request(
            path: ApiPaths.Bridge.List,
            method: HTTPMethod.get,
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
    
    public func createBridge(request: VMSBridgeCreateRequest, completion: @escaping VMSResultBlock<VMSBridge>) {
        
        var params: Parameters = [
            "name": request.name
        ]
        params["mac"] = request.mac
        params["serial_number"] = request.serialNumber
        self.request(
            path: ApiPaths.Bridge.List,
            method: HTTPMethod.post,
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
    
    public func updateBridge(with id: Int, name: String, completion: @escaping VMSResultBlock<VMSBridge>) {
        let params: Parameters = [
            "name": name
        ]
        self.request(
            path: ApiPaths.Bridge.update(id: id),
            method: HTTPMethod.put,
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
    
    public func getBridge(with id: Int, completion: @escaping VMSResultBlock<VMSBridge>) {
        self.request(
            path: ApiPaths.Bridge.update(id: id),
            method: HTTPMethod.put
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
    
    public func deleteBridge(with id: Int, completion: @escaping VMSResultBlock<VMSNoReply>) {
        self.request(
            path: ApiPaths.Bridge.update(id: id),
            method: HTTPMethod.delete
        ) { (response: VMSApiResult<Any>) in
            
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getBridgeCameras(bridgeId: Int, page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>) {
        let params: Parameters = [
            "page" : page
        ]
        self.request(
            path: ApiPaths.Bridge.cameras(id: bridgeId),
            method: HTTPMethod.get,
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
    
    public func deleteBridgeCamera(with bridgeId: Int, cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>) {
        self.request(
            path: ApiPaths.Bridge.deleteCamera(bridgeId: bridgeId, cameraId: cameraId),
            method: HTTPMethod.delete
        ) { (response: VMSApiResult<Any>) in
            
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
