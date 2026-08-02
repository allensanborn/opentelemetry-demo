workspace extends ../system-catalog/workspace.dsl {

    model {
        !impliedRelationships true
        !element orders {
            checkout       = container "Checkout Service" "Orchestrates order placement across cart, payment, shipping, and email." "Go"
            accounting     = container "Accounting Service" "Records placed orders for bookkeeping." "C# / .NET"
            fraudDetection = container "Fraud Detection Service" "Flags potentially fraudulent orders." "Kotlin / JVM"
            orderBus       = container "Order Bus" "Streams placed-order events to the async consumers (topic: orders)." "Apache Kafka" "Queue"
            accountingDb   = container "Accounting DB" "Order records — the accounting schema/database this team owns." "PostgreSQL" "Database"
        }

        # intra-system (the async order lifecycle lives entirely here)
        checkout       -> orderBus     "Publishes 'orders' events to" "Kafka"
        accounting     -> orderBus     "Consumes 'orders' events from" "Kafka"
        fraudDetection -> orderBus     "Consumes 'orders' events from" "Kafka"
        accounting     -> accountingDb "Writes order records to" "SQL"

        # cross-system (checkout orchestrates other teams' systems)
        checkout -> cart          "Reads and clears the cart via" "gRPC"
        checkout -> currency      "Converts order totals via" "gRPC"
        checkout -> catalog       "Looks up product details via" "gRPC"
        checkout -> payments      "Charges the order via" "gRPC"
        checkout -> shipping      "Ships the order via" "HTTP"
        checkout -> notifications "Sends the confirmation email via" "HTTP"

        # platform (consumed as-a-service)
        checkout -> flagSystem "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        checkout       -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
        accounting     -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
        fraudDetection -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }

    views {
        systemContext orders "Context" "Checkout & Orders and the systems it depends on." {
            include *
            autolayout lr
        }
        container orders "Containers" "Inside Checkout & Orders — including the internal Kafka order bus and the team's own DB." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
