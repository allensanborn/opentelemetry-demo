workspace extends ../system-catalog/workspace.dsl {
    model {
        !impliedRelationships true
        !element currency {
            currencySvc = container "Currency Service" "Converts money between currencies." "C++"
        }
        currencySvc -> flagSystem  "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        currencySvc -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }
    views {
        systemContext currency "Context" "Currency Service and the platform services it consumes." {
            include *
            autolayout lr
        }
        container currency "Containers" "Inside Currency Service." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
