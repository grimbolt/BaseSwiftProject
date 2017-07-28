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

public class ConnectionManager {
    
    enum PareseError: Error {
        case invalid
    }
    
    static let lock = NSLock()
    
    static var _sessionManager: SessionManager?
    public static var sessionManager: SessionManager {
        get {
            if let sessionManager = ConnectionManager._sessionManager {
                return sessionManager;
            } else {
                let configuration = URLSessionConfiguration.default
                configuration.timeoutIntervalForRequest = 20
                configuration.timeoutIntervalForResource = 20
                
                configuration.urlCache = nil
                
                ConnectionManager._sessionManager = SessionManager(configuration: configuration)
                return ConnectionManager._sessionManager!
            }
        }
        set {
            ConnectionManager._sessionManager = newValue
        }
    }
    
    public static func request<T: BaseMappable> (
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        withPreloader: Bool = true,
        withSaveContext: Bool = true,
        completionHandler: @escaping (DataResponse<T>) -> Void
        ) {
        
        let request = sessionManager.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
        if withPreloader {
            showPreloader((request.request?.description ?? ""), type: .small)
        }
        
        request.responseObject { (response: DataResponse<T>) in
            
            if withPreloader {
                hidePreloader((request.request?.description ?? ""), type: .small)
            }
            completionHandler(response)
            
            if withSaveContext {
                switch response.result {
                case .success:
                    DatabaseHelper.sharedInstance.saveContext()
                case .failure: break
                }
            }
            
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
    
    public static func requestArray<T: BaseMappable> (
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        withPreloader: Bool = true,
        withSaveContext: Bool = true,
        completionHandler: @escaping (DataResponse<[T]>) -> Void
        ) {
        
        let request = sessionManager.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
        if withPreloader {
            showPreloader((request.request?.description ?? "") + (request.request?.allHTTPHeaderFields?.description ?? ""), type: .small)
        }
        
        request.responseArray { (response: DataResponse<[T]>) in
            
            if withPreloader {
                hidePreloader((request.request?.description ?? "") + (request.request?.allHTTPHeaderFields?.description ?? ""), type: .small)
            }
            completionHandler(response)
            
            if withSaveContext {
                switch response.result {
                case .success:
                    DatabaseHelper.sharedInstance.saveContext()
                case .failure: break
                }
            }
            
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
    
    public static func simpleRequestWithHttpBody<T: BaseMappable> (url:URL,
                                                 httpBody:Data?,
                                                 method: HTTPMethod = .get,
                                                 headers: HTTPHeaders? = nil,
                                                 completionHandler: @escaping (DataResponse<[T]>) -> Void) {
        
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        urlRequest.httpBody = httpBody
        urlRequest.httpMethod = method.rawValue
        
        if let _ = headers {
            for header in headers! {
                urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let request = sessionManager.request(urlRequest)
        
        request.responseArray { (response: DataResponse<[T]>) in
            completionHandler(response)
            }.validate { (requst, response, data) -> Request.ValidationResult in
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
    
    public static func cancelAllTasks() {
        sessionManager.session.getTasksWithCompletionHandler { (sessionDataTask, sessionUploadTask, sessionDownloadTask) in
            sessionDataTask.forEach({ $0.cancel() })
            sessionUploadTask.forEach({ $0.cancel() })
            sessionDownloadTask.forEach({ $0.cancel() })
        }
    }
}
