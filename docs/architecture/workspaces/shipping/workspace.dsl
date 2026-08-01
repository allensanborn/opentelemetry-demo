workspace extends ../system-catalog/workspace.dsl {

    model {
        !element shipping {
            shippingSvc = container "Shipping Service" "Calculates shipping cost and ships the order." "Rust"
            quote       = container "Quote Service" "Computes shipping-cost quotes." "PHP"
        }

        shippingSvc -> quote "Requests shipping cost from" "HTTP"

        # platform (consumed as-a-service)
        shippingSvc -> flagSystem  "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        shippingSvc -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
        quote       -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }

    views {
        systemContext shipping "Context" "Shipping and the platform services it consumes." {
            include *
            autolayout lr
        }
        container shipping "Containers" "Inside Shipping — shipping service plus the quote service." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
