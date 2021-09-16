//
//  RenVM+RPCClient.swift
//  Alamofire
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxAlamofire
import RxSwift

extension RenVM {
    public struct RpcClient: RenVMRpcClientType {
        public init(network: RenVM.Network) {
            self.network = network
        }
        
        public let network: RenVM.Network
        
        public func call<T>(endpoint: String, method: String, params: Encodable) -> Single<T> where T : Decodable {
            do {
                // prepare params
                let params = EncodableWrapper.init(wrapped:params)
                
                // Log
                Logger.log(message: "\(method) \(params.jsonString ?? "")", event: .request, apiMethod: method)
                
                // prepare urlRequest
                let body = Body(method: method, params: params)
                
                var urlRequest = try URLRequest(
                    url: endpoint,
                    method: .post,
                    headers: [.contentType("application/json")]
                )
                urlRequest.httpBody = try JSONEncoder().encode(body)
                
                // request
                return request(urlRequest)
                    .responseData()
                    .map {(response, data) -> T in
                        // Print
//                        Logger.log(message: String(data: data, encoding: .utf8) ?? "", event: .response, apiMethod: method)
                        
                        let statusCode = response.statusCode
                        let isValidStatusCode = (200..<300).contains(statusCode)
                        
                        let res = try JSONDecoder().decode(Response<T>.self, from: data)
                        
                        if isValidStatusCode, let result = res.result {
                            return result
                        }
                        
                        throw res.error ?? .unknown
                    }
                    .take(1)
                    .asSingle()
            } catch {
                return .error(error)
            }
        }
        
        struct Body: Encodable {
            let id = 1
            let jsonrpc = "2.0"
            let method: String
            let params: EncodableWrapper
        }
        
        struct EncodableWrapper: Encodable {
            let wrapped: Encodable
            
            public func encode(to encoder: Encoder) throws {
                try self.wrapped.encode(to: encoder)
            }
        }
        
        struct Response<T: Decodable>: Decodable {
            public let jsonrpc: String
            public let id: Int?
            public let result: T?
            public let error: Error?
            public let method: String?
            
            struct Error: Swift.Error, Decodable {
                public let code: Int?
                public let message: String?
                
                public static var unknown: Self {
                    .init(code: -1, message: "Unknown error")
                }
            }
        }
    }
}