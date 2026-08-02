workspace extends ../system-catalog/workspace.dsl {
    model {
        !impliedRelationships true
        !element payments {
            payment = container "Payment Service" "Charges the order to a credit card (mock)." "Node.js"
        }
        payment -> flagSystem  "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        payment -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }
    views {
        systemContext payments "Context" "Payment Service and the platform services it consumes." {
            include *
            autolayout lr
        }
        container payments "Containers" "Inside Payment Service." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
