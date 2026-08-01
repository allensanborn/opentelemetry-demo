workspace extends ../system-catalog/workspace.dsl {

    model {
        !element storefront {
            proxy         = container "Frontend Proxy" "Single public entrypoint; routes browser traffic." "Envoy"
            frontend      = container "Frontend" "Web store + backend-for-frontend aggregating the shop services." "TypeScript / Next.js"
            imageProvider = container "Image Provider" "Serves static product images." "nginx"
        }

        # intra-system
        proxy -> frontend      "Routes web & API requests to" "HTTP"
        proxy -> imageProvider "Routes product-image requests to" "HTTP"

        # cross-system (Storefront is the source; targets are catalog systems)
        proxy    -> assistant       "Routes chat requests to" "HTTP"
        frontend -> ads             "Requests contextual ads from" "gRPC"
        frontend -> cart            "Reads and updates the cart via" "gRPC"
        frontend -> orders          "Places orders through" "gRPC"
        frontend -> currency        "Converts prices via" "gRPC"
        frontend -> catalog         "Looks up products via" "gRPC"
        frontend -> recommendations "Requests recommendations from" "gRPC"
        frontend -> shipping        "Requests shipping quotes from" "HTTP"

        # platform (consumed as-a-service)
        frontend -> flagSystem  "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        proxy         -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
        frontend      -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
        imageProvider -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"

        # who drives the storefront
        customer = person "Customer" "Browses the catalog, places orders, and chats."
        customer -> proxy "Browses, buys, and chats via" "HTTPS"
        loadgen  -> proxy "Drives synthetic traffic through" "HTTPS / k6"
    }

    views {
        systemContext storefront "Context" "Storefront in its landscape: who uses it and the systems it depends on." {
            include *
            autolayout lr
        }
        container storefront "Containers" "Inside Storefront." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
