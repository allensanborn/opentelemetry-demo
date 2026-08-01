workspace extends ../system-catalog/workspace.dsl {

    # The landscape workspace maps how the systems in the catalog fit together.
    #
    # In a real Structurizr setup this workspace is GENERATED, not hand-authored:
    # `structurizr pull` every team workspace, `structurizr generate system-landscape`
    # (which derives these system-to-system edges from each team's container-level
    # relationships), then `structurizr push`. We have no server here, so the
    # system-level edges below are hand-declared — which is exactly the duplication
    # the generator removes. Treat this file as a stand-in for the generated output.

    model {
        customer = person "Customer" "Browses the catalog, places orders, and chats with the shopping assistant."
        customer -> storefront "Browses, buys, and chats via" "HTTPS"
        loadgen  -> storefront "Drives synthetic traffic through" "HTTPS / k6"

        # Aggregated system-to-system business relationships.
        storefront -> assistant       "Routes chat requests to" "HTTP"
        storefront -> ads             "Requests contextual ads from" "gRPC"
        storefront -> cart            "Reads and updates the cart via" "gRPC"
        storefront -> orders          "Places orders through" "gRPC"
        storefront -> currency        "Converts prices via" "gRPC"
        storefront -> catalog         "Looks up products via" "gRPC"
        storefront -> recommendations "Requests recommendations from" "gRPC"
        storefront -> shipping        "Requests shipping quotes from" "HTTP"

        assistant -> storefront "Calls the shop REST API on" "HTTP"
        assistant -> llm        "Sends prompts to" "HTTPS"

        orders -> cart          "Reads and clears the cart via" "gRPC"
        orders -> currency      "Converts order totals via" "gRPC"
        orders -> catalog       "Looks up product details via" "gRPC"
        orders -> payments      "Charges the order via" "gRPC"
        orders -> shipping      "Ships the order via" "HTTP"
        orders -> notifications "Sends the confirmation email via" "HTTP"

        recommendations -> catalog "Looks up product details via" "gRPC"
    }

    views {
        systemLandscape "Landscape" "Team-aligned system landscape (business systems). Platform excluded for legibility; each team's dependency on the platform is shown in that team's own workspace." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
