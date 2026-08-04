workspace extends ../system-catalog/workspace.dsl {

    model {
        !impliedRelationships true
        !element catalog {
            productCatalog = container "Product Catalog Service" "Lists and looks up products." "Go"
            catalogDb      = container "Catalog DB" "Product data — the catalog schema/database this team owns." "PostgreSQL" "Database"
        }

        productCatalog -> catalogDb "Reads product data from" "SQL"

        # platform (consumed as-a-service)
        productCatalog -> flagSystem  "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        productCatalog -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }

    views {
        systemContext catalog "Context" "Product Catalog and the platform services it consumes." {
            include *
            autolayout lr
        }
        container catalog "Containers" "Inside Product Catalog — service plus its own database." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
