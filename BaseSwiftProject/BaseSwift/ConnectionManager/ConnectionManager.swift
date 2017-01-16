//
//  ConnectionManager.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 07.01.2017.
//
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

class ConnectionManager {
    
    enum PareseError: Error {
        case invalid
    }
    
    static let lock = NSLock()
    
    static let sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 2
        configuration.timeoutIntervalForResource = 2
        
        let session = SessionManager(configuration: configuration)
        let requestAccessToken = RequestAccessToken()
        session.adapter = requestAccessToken
        session.retrier = requestAccessToken
        
        return session
    }()
    
    static func request<T: BaseMappable> (
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        withPreloader: Bool = true,
        completionHandler: @escaping (DataResponse<T>) -> Void
        ) {
        
        let request = sessionManager.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
        if withPreloader {
            showPreloader((request.request?.description ?? "") + (request.request?.allHTTPHeaderFields?.description ?? ""), type: .small)
        }

        request.responseObject { (response: DataResponse<T>) in
            
            if withPreloader {
                hidePreloader((request.request?.description ?? "") + (request.request?.allHTTPHeaderFields?.description ?? ""), type: .small)
            }
            completionHandler(response)
            
            }.validate { request, response, data in
                
                if
                    let data = data
                {
                    do {
                        try JSONSerialization.jsonObject(with: data, options: [])
                        return DataRequest.ValidationResult.success
                    } catch {
                    }
                }
                return DataRequest.ValidationResult.failure(PareseError.invalid)
        }
    }
}
