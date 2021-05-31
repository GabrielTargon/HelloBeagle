//
//  NetworkClientDefault.swift
//  HelloBeagle
//
//  Created by Marcos Jr on 31/05/21.
//

import Beagle
import Foundation

public class NetworkClientDefault: NetworkClient {

    public typealias Dependencies = DependencyLogger

    public var session = URLSession.shared
    let dependencies: Dependencies

    public var httpRequestBuilder = HttpRequestBuilder()
    
    public init(dependencies: DependencyLogger) {
        self.dependencies = dependencies
    }

    enum ClientError: Swift.Error {
        case invalidHttpResponse
        case invalidHttpRequest
    }

    public func executeRequest(
        _ request: Request,
        completion: @escaping RequestCompletion
    ) -> RequestToken? {
        return doRequest(request, completion: completion)
    }

    @discardableResult
    private func doRequest(
        _ request: Request,
        completion: @escaping RequestCompletion
    ) -> RequestToken? {
        
        let build = httpRequestBuilder.build(
            url: request.url,
            requestType: request.type,
            additionalData: request.additionalData as? HttpAdditionalData
        )
        let urlRequest = build.toUrlRequest()

        let task = session.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            self.dependencies.logger.log(Log.network(.httpResponse(response: .init(data: data, response: response))))
            completion(self.handleResponse(data: data, request: urlRequest, response: response, error: error))
        }
        
        dependencies.logger.log(Log.network(.httpRequest(request: .init(url: urlRequest))))
        task.resume()
        return task
    }

    private func handleResponse(
        data: Data?,
        request: URLRequest,
        response: URLResponse?,
        error: Swift.Error?
    ) -> NetworkClient.NetworkResult {
        if let error = error {
            return .failure(NetworkError(error: error, request: request))
        }

        guard
            let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode),
            let responseData = data
        else {
            return .failure(NetworkError(
                error: ClientError.invalidHttpResponse,
                data: data,
                request: request,
                response: response
            ))
        }

        return .success(.init(data: responseData, response: httpResponse))
    }
}
