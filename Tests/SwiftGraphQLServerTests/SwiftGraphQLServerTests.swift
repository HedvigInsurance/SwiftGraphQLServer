import XCTest
import Graphiti
import Vapor

@testable import SwiftGraphQLServer

final class SwiftGraphQLServerTests: XCTestCase {
    override func setUp() {
        try? startServer()
    }
    
    func startServer() throws {
        let schema = try Schema<Void, Void, MultiThreadedEventLoopGroup> { schema in
            try schema.query { query in
                try query.field(
                    name: "test",
                    type: String.self
                ) { (_, _, _, eventLoop, _) in
                    return eventLoop.next().newSucceededFuture(result: "test")
                }
            }
        }
        
        let app = try Application()
        let router = try app.make(Router.self)
        
        try GraphQLServer(schema: schema).run(router: router)
        
        try app.run()
    }
    
    func testRunningServer() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let client = HTTPClient.connect(
            scheme: HTTPScheme.http,
            hostname: "localhost",
            port: 8080,
            connectTimeout: TimeAmount.seconds(10),
            on: eventLoopGroup
        ) { error in
            print(error)
        }
        
        let expectation = XCTestExpectation(description: "Connect to GraphQL server")
        
        client.whenSuccess({ client in
            let httpReq = HTTPRequest(method: .POST, url: "/graphql")
            
            client.send(httpReq).whenSuccess({ response in
                XCTAssertTrue(response.description.contains(GraphQLServerError.noData.reason))
                expectation.fulfill()
            })
        })
        
        wait(for: [expectation], timeout: 10.0)
    }

    static var allTests = [
        ("testRunningServer", testRunningServer),
    ]
}
