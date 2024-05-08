
import Foundation
import Alamofire

public protocol FavoritesApi {
    
    func createFavorite(with cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
    func deleteFavorite(with cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
    func getFavoritesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>)
    
}

extension VMS: FavoritesApi {
    
    public func createFavorite(with cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>) {
        self.request(
            path: ApiPaths.Cameras.crudFavorites(id: cameraId),
            method: HTTPMethod.post
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func deleteFavorite(with cameraId: Int, completion: @escaping VMSResultBlock<VMSNoReply>) {
        self.request(
            path: ApiPaths.Cameras.crudFavorites(id: cameraId),
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
    
    public func getFavoritesList(page: Int, completion: @escaping VMSResultBlock<PaginatedResponse<VMSCamera>>) {
        self.request(
            path: ApiPaths.Cameras.Favorites,
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
}
