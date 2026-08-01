workspace "OpenTelemetry Astronomy Shop" "C4 model of the OpenTelemetry Demo — a microservice-based e-commerce app instrumented end-to-end with OpenTelemetry." {

    model {
        # Roll granular container->external / person->container edges up to the
        # system boundary automatically, so the System Context view stays clean.
        !impliedRelationships true

        # ---- People / traffic sources -------------------------------------
        customer = person "Customer" "Browses the product catalog, places orders, and chats with the shopping assistant."

        # ---- The system in scope ------------------------------------------
        astronomyShop = softwareSystem "Astronomy Shop" "Microservice-based e-commerce store selling astronomy gear; the reference app for the OpenTelemetry Demo." {

            group "Edge & Web" {
                proxy         = container "Frontend Proxy" "Single public entrypoint; routes browser traffic to the web app, images, chat, and observability UIs." "Envoy"
                frontend      = container "Frontend" "Server-rendered web store and backend-for-frontend that aggregates the shop services." "TypeScript / Next.js"
                imageProvider = container "Image Provider" "Serves static product images." "nginx"
            }

            group "Chat / AI Assistant" {
                chatbot = container "Chatbot" "Chat UI for the shopping assistant." "Python / FastAPI"
                agent   = container "Agent" "LLM agent that answers shopping questions by calling shop tools and an external model." "Python / LangChain + LangGraph"
                mcp     = container "MCP Server" "Exposes the shop's REST API to the agent as MCP tools." "Python / FastMCP"
            }

            group "Shop Services" {
                ad             = container "Ad" "Returns contextual ads for a product category." "Java"
                cart           = container "Cart" "Holds each user's shopping cart." "C# / .NET"
                checkout       = container "Checkout" "Orchestrates order placement across cart, payment, shipping, and email." "Go"
                currency       = container "Currency" "Converts money between currencies." "C++"
                productCatalog = container "Product Catalog" "Lists and looks up products." "Go"
                recommendation = container "Recommendation" "Suggests related products." "Python"
                payment        = container "Payment" "Charges the order to a credit card (mock)." "Node.js"
                shipping       = container "Shipping" "Calculates shipping cost and ships the order." "Rust"
                quote          = container "Quote" "Computes shipping-cost quotes." "PHP"
                email          = container "Email" "Sends the order-confirmation email (mock)." "Ruby / Sinatra"
            }

            group "Order Processing (async)" {
                accounting     = container "Accounting" "Records placed orders for bookkeeping." "C# / .NET"
                fraudDetection = container "Fraud Detection" "Flags potentially fraudulent orders." "Kotlin / JVM"
            }

            group "Platform" {
                flagd = container "flagd" "Feature-flag service; evaluates the flags that drive the demo's failure scenarios. Queried by the shop services." "Go / OpenFeature" {
                    tags "Infrastructure"
                }
            }

            group "Data Stores" {
                valkey   = container "Cart Store" "Stores cart contents keyed by user." "Valkey (Redis-compatible)" {
                    tags "Database"
                }
                postgres = container "Astronomy DB" "Product catalog data and order records." "PostgreSQL" {
                    tags "Database"
                }
                kafka    = container "Order Bus" "Streams placed-order events to async consumers." "Apache Kafka" {
                    tags "Queue"
                }
            }
        }

        # ---- External systems ---------------------------------------------
        loadgen = softwareSystem "Load Generator" "Simulates real users by driving synthetic browsing and checkout traffic." "k6" {
            tags "External"
        }
        observability = softwareSystem "Observability Backend" "OpenTelemetry Collector plus Jaeger, Prometheus, Grafana, and OpenSearch; receives all traces, metrics, and logs." {
            tags "External"
        }
        llm = softwareSystem "LLM API" "External OpenAI-compatible large-language-model endpoint used by the shopping assistant." {
            tags "External"
        }

        # ---- Entry / routing ----------------------------------------------
        customer -> proxy "Browses, buys, and chats via" "HTTPS" "Business"
        loadgen  -> proxy "Drives synthetic traffic through" "HTTPS / k6" "Business"
        proxy -> frontend      "Routes web & API requests to" "HTTP" "Business"
        proxy -> imageProvider "Routes product-image requests to" "HTTP" "Business"
        proxy -> chatbot       "Routes chat requests to" "HTTP" "Business"

        # ---- Frontend fan-out ---------------------------------------------
        frontend -> ad             "Requests contextual ads from" "gRPC" "Business"
        frontend -> cart           "Reads and updates the cart via" "gRPC" "Business"
        frontend -> checkout       "Places orders through" "gRPC" "Business"
        frontend -> currency       "Converts prices via" "gRPC" "Business"
        frontend -> productCatalog "Looks up products via" "gRPC" "Business"
        frontend -> recommendation "Requests recommendations from" "gRPC" "Business"
        frontend -> shipping       "Requests shipping quotes from" "HTTP" "Business"

        # ---- Chat / AI path -----------------------------------------------
        chatbot -> agent    "Forwards user prompts to" "HTTP" "Business"
        agent   -> mcp      "Invokes shop tools via" "HTTP (MCP)" "Business"
        agent   -> llm      "Sends prompts to" "HTTPS" "Business"
        mcp     -> frontend "Calls the shop REST API on" "HTTP" "Business"

        # ---- Checkout fan-out ---------------------------------------------
        checkout -> cart           "Reads and clears the cart via" "gRPC" "Business"
        checkout -> currency       "Converts order totals via" "gRPC" "Business"
        checkout -> productCatalog "Looks up product details via" "gRPC" "Business"
        checkout -> payment        "Charges the order via" "gRPC" "Business"
        checkout -> shipping       "Ships the order via" "HTTP" "Business"
        checkout -> email          "Sends the confirmation email via" "HTTP" "Business"
        checkout -> kafka          "Publishes 'orders' events to" "Kafka" "Business"

        # ---- Other backend edges ------------------------------------------
        recommendation -> productCatalog "Looks up product details via" "gRPC" "Business"
        shipping       -> quote          "Requests shipping cost from" "HTTP" "Business"

        # ---- Data stores --------------------------------------------------
        cart           -> valkey   "Reads and writes cart state in" "RESP / TCP" "Business"
        productCatalog -> postgres "Reads product data from" "SQL" "Business"
        accounting     -> postgres "Writes order records to" "SQL" "Business"
        accounting     -> kafka    "Consumes 'orders' events from" "Kafka" "Business"
        fraudDetection -> kafka    "Consumes 'orders' events from" "Kafka" "Business"

        # ---- Cross-cutting: feature flags (shown in its own view) ----------
        frontend       -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        ad             -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        cart           -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        checkout       -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        currency       -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        productCatalog -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        recommendation -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        payment        -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        shipping       -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        quote          -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        email          -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"

        # ---- Cross-cutting: telemetry export (shown in its own view) -------
        proxy          -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        frontend       -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        imageProvider  -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        chatbot        -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        agent          -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        mcp            -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        ad             -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        cart           -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        checkout       -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        currency       -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        productCatalog -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        recommendation -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        payment        -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        shipping       -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        quote          -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        email          -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        accounting     -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        fraudDetection -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        flagd          -> observability "Exports traces, metrics & logs via" "OTLP" "Telemetry"
    }

    views {
        systemContext astronomyShop "Context" "The Astronomy Shop, its users, and the systems around it." {
            include *
            autolayout lr
        }

        container astronomyShop "Containers" "The services and data stores inside the Astronomy Shop, and how they call each other. Cross-cutting feature-flag and telemetry wiring is shown in separate views." {
            include *
            exclude flagd
            exclude observability
            autolayout lr
        }

        container astronomyShop "FeatureFlags" "Cross-cutting view: every shop service evaluates feature flags via flagd." {
            include flagd
            include "->flagd"
            exclude "relationship.tag==Business"
            autolayout lr
        }

        container astronomyShop "Telemetry" "Cross-cutting view: every container exports OpenTelemetry data to the observability backend." {
            include observability
            include "->observability"
            exclude "relationship.tag==Business"
            exclude "relationship.tag==FeatureFlag"
            autolayout lr
        }

        styles {
            element "External" {
                background #8a8a8a
                color #ffffff
            }
            element "Infrastructure" {
                background #6b4fbb
                color #ffffff
            }
            element "Database" {
                shape cylinder
            }
            element "Queue" {
                shape pipe
            }
            relationship "Telemetry" {
                dashed true
                color #7a7a7a
            }
            relationship "FeatureFlag" {
                dashed true
                color #7a7a7a
            }
        }

        theme default
    }
}
