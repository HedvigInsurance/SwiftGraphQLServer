# SwiftGraphQLServer

## Usage

Example main.swift:

```
import Graphiti
import Vapor
import SwiftGraphQLServer

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
```

Then try a GraphQL request against `http://localhost:8080/graphql`.


