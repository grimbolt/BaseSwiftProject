//
//  RequestAccessToken.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 09.01.2017.
//
//

import Foundation
import Alamofire
import BaseSwiftProject

class RequestAccessToken: RequestAdapter, RequestRetrier {
    private typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?) -> Void
    
    private var retryLimit: Int = 3
    
    private let lock = NSLock()
    private var accessToken: String?
    
    private var retryCount: Int = 0
    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []
    
    private let sessionManager: SessionManager = SessionManager.default
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        if let url = urlRequest.url, url.absoluteString.hasPrefix(ConnectionManager.BASE_URL) {
            var urlRequest = urlRequest
            if let accessToken = accessToken {
                if
                    let httpBody = urlRequest.httpBody,
                    let bodyString = String(data: httpBody, encoding: .utf8)
                {
                    var bodyString = bodyString
                    bodyString.append("&api_user_key=\(accessToken)")
                    urlRequest.httpBody = bodyString.data(using: .utf8)
                }
            }
            return urlRequest
        }
        
        return urlRequest
    }
    
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        lock.lock() ; defer { lock.unlock() }
        
        if let task = request.task, let response = task.response as? HTTPURLResponse {
            requestsToRetry.append(completion)
            
            if !isRefreshing {
                refreshTokens { [weak self] succeeded, accessToken in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                    
                    if let accessToken = accessToken {
                        strongSelf.accessToken = accessToken
                    }
                    
                    if strongSelf.retryCount >= strongSelf.retryLimit - 1 {
                        strongSelf.retryCount = 0
                        strongSelf.requestsToRetry.forEach { $0(false, 0.0) }
                    } else {
                        strongSelf.retryCount += 1
                        strongSelf.requestsToRetry.forEach { $0(succeeded, 0.0) }
                    }
                    
                    strongSelf.requestsToRetry.removeAll()
                }
            }
        } else {
            completion(false, 0.0)
        }
    }
    
    private func refreshTokens(completion: @escaping RefreshCompletion) {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        ConnectionManager.login() { [weak self] response in
            guard let strongSelf = self else { return }
            
            if let accessToken = response.result.value {
                completion(true, accessToken)
            } else {
                completion(false, nil)
            }
            
            strongSelf.isRefreshing = false
        }
    }
}
