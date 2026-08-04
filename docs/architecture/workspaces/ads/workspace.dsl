workspace extends ../system-catalog/workspace.dsl {
    model {
        !impliedRelationships true
        !element ads {
            ad = container "Ad Service" "Returns contextual ads for a product category." "Java"
        }
        ad -> flagSystem  "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        ad -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }
    views {
        systemContext ads "Context" "Ad Service and the platform services it consumes." {
            include *
            autolayout lr
        }
        container ads "Containers" "Inside Ad Service." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
