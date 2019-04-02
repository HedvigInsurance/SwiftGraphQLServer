//
//  SwiftGraphQLServer.swift
//  SwiftGraphQLServer
//
//  Created by Sam Pettersson on 2019-04-02.
//

import Foundation
import Graphiti
import Vapor

struct GraphQLHTTPBody: Decodable {
    let query: String
    let operationName: String?
    let variables: [String: Map]
}

enum GraphQLServerError: Error, Debuggable {
    var identifier: String {
        switch self {
        case .noData:
            return "noData"
        case .queryFailed:
            return "queryFailed"
        }
    }
    
    var reason: String {
        switch self {
        case .noData:
            return "Could not parse incoming request"
        case .queryFailed:
            return "Could not perform GraphQL query"
        }
    }
    
    case queryFailed, noData
}

public struct GraphQLServer<RootValue, Context, EventLoop: EventLoopGroup> {
    let schema: Schema<RootValue, Context, EventLoop>
    
    public init(schema: Schema<RootValue, Context, EventLoop>) {
        self.schema = schema
    }
    
    public func run(router: Router) throws -> Void {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        router.post("graphql") { req -> Future<String> in
            guard let httpBodyData = req.http.body.data else {
                return req.eventLoop.newFailedFuture(error: GraphQLServerError.noData)
            }
            
            let httpBody = try JSONDecoder().decode(GraphQLHTTPBody.self, from: httpBodyData)
            
            let promise: Promise<String> = req.eventLoop.newPromise()
            
            do {
                let graphQLFuture = try self.schema.execute(
                    request: httpBody.query,
                    eventLoopGroup: eventLoopGroup,
                    variables: httpBody.variables,
                    operationName: httpBody.operationName
                )
                
                graphQLFuture.whenFailure({ error in
                    promise.fail(error: error)
                })
                
                graphQLFuture.whenSuccess({ map in
                    promise.succeed(result: map.description)
                })
                
                return promise.futureResult
            } catch {
                promise.fail(error: GraphQLServerError.queryFailed)
                return promise.futureResult
            }
        }
    }
    
}
