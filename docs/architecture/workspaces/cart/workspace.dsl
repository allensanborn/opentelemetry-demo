workspace extends ../system-catalog/workspace.dsl {

    model {
        !impliedRelationships true
        !element cart {
            cartSvc   = container "Cart Service" "Holds each user's shopping cart." "C# / .NET"
            cartStore = container "Cart Store" "Cart contents keyed by user." "Valkey (Redis-compatible)" "Database"
        }

        cartSvc -> cartStore "Reads and writes cart state in" "RESP / TCP"

        # platform (consumed as-a-service)
        cartSvc -> flagSystem  "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        cartSvc -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }

    views {
        systemContext cart "Context" "Cart and the platform services it consumes." {
            include *
            autolayout lr
        }
        container cart "Containers" "Inside Cart — service plus its own data store." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
