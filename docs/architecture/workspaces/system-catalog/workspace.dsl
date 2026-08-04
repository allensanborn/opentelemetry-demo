workspace "OpenTelemetry Astronomy Shop — System Catalog" "Software-system definitions only (no containers, no relationships). Each team's workspace `extends` this catalog to add its own containers and declare cross-system relationships. This is the shared source of truth for what systems exist and who owns them." {

    model {
        # --- Product (stream-aligned) systems ---
        storefront      = softwareSystem "Storefront" "Public web store and API gateway. (Team: Web)"
        assistant       = softwareSystem "Shopping Assistant" "Conversational shopping help backed by an LLM. (Team: AI)"
        catalog         = softwareSystem "Product Catalog" "Owns product data and lookup. (Team: Catalog)"
        recommendations = softwareSystem "Recommendations" "Suggests related products. (Team: Growth)"
        ads             = softwareSystem "Ads" "Contextual advertising. (Team: Growth)"
        cart            = softwareSystem "Cart" "Owns the shopping cart. (Team: Cart)"
        orders          = softwareSystem "Checkout & Orders" "Order placement and the async order lifecycle. (Team: Orders)"
        payments        = softwareSystem "Payments" "Card charging. (Team: Payments)"
        shipping        = softwareSystem "Shipping" "Shipping cost and fulfilment. (Team: Fulfilment)"
        notifications   = softwareSystem "Notifications" "Customer messaging. (Team: Comms)"
        currency        = softwareSystem "Currency" "Shared currency conversion. (Team: Shared Services)"

        # --- Platform systems (another team; consumed as-a-service) ---
        flagSystem  = softwareSystem "Feature Flags" "Feature-flag evaluation over OpenFeature/OFREP. (Team: Platform)" "Platform"
        obsPlatform = softwareSystem "Observability Platform" "Telemetry ingest, storage, and dashboards over OTLP. (Team: Platform)" "Platform"

        # --- External (outside the org) ---
        llm     = softwareSystem "LLM API" "Third-party OpenAI-compatible model endpoint." "External"
        loadgen = softwareSystem "Load Generator" "Simulates real users with synthetic traffic (k6)." "External"
    }
}
