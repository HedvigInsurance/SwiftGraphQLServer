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

enum GraphQLServerError: Error, CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .noData:
            return "Could not parse incoming request"
        case .queryFailed:
            return "Could not perform GraphQL query"
        }
    }
    
    case queryFailed, noData
}

public struct GraphQLServer<RootValue: FieldKeyProvider, Context, R: Router> {
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
    
    public func run(_ r: Routes) throws -> Void {
        r.post("graphql") { req -> EventLoopFuture<String> in
            let httpBody = try req.content.decode(GraphQLHTTPBody.self)
            
            let promise = req.eventLoop.makePromise(of: String.self)
            
            let graphQLFuture = self.schema.execute(
                request: httpBody.query,
                root: self.getRootValue(req),
                context: self.getContext(req),
                eventLoopGroup: req.eventLoop,
                variables: httpBody.variables,
                operationName: httpBody.operationName
            )
            
            graphQLFuture.whenFailure({ error in
                promise.fail(error)
            })
            
            graphQLFuture.whenSuccess({ map in
                promise.succeed(map.description)
            })
            
            return promise.futureResult
        }
    }
}
