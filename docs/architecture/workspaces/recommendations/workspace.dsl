workspace extends ../system-catalog/workspace.dsl {
    model {
        !impliedRelationships true
        !element recommendations {
            recommendation = container "Recommendation Service" "Computes product recommendations." "Python"
        }
        recommendation -> catalog     "Looks up product details via" "gRPC"
        recommendation -> flagSystem  "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        recommendation -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }
    views {
        systemContext recommendations "Context" "Recommendations and its dependencies." {
            include *
            autolayout lr
        }
        container recommendations "Containers" "Inside Recommendations." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
