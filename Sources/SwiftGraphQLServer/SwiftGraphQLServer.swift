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

public struct GraphQLServer<RootValue: FieldKeyProvider, Context> {
    let schema: Schema<RootValue, Context>
    let getRootValue: (_ req: Request) -> RootValue
    let getContext: (_ req: Request) -> Context
    
    public init(
        schema: Schema<RootValue, Context>,
        getContext: @escaping (_ req: Request) -> Context,
        getRootValue: @escaping (_ req: Request) -> RootValue
    ) {
        self.schema = schema
        self.getContext = getContext
        self.getRootValue = getRootValue
    }
    
    public func run(router: Router) throws -> Void {
        router.post("graphql") { req -> Future<String> in
            guard let httpBodyData = req.http.body.data else {
                return req.eventLoop.newFailedFuture(error: GraphQLServerError.noData)
            }
            
            let httpBody = try JSONDecoder().decode(GraphQLHTTPBody.self, from: httpBodyData)
            
            let promise: Promise<String> = req.eventLoop.newPromise()
            
            let graphQLFuture = self.schema.execute(
                request: httpBody.query,
                root: self.getRootValue(req),
                context: self.getContext(req),
                eventLoopGroup: req.eventLoop,
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
        }
    }
}
