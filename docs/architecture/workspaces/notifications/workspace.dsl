workspace extends ../system-catalog/workspace.dsl {
    model {
        !element notifications {
            email = container "Email Service" "Sends the order-confirmation email (mock)." "Ruby / Sinatra"
        }
        email -> flagSystem  "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        email -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }
    views {
        systemContext notifications "Context" "Email Service and the platform services it consumes." {
            include *
            autolayout lr
        }
        container notifications "Containers" "Inside Email Service." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
