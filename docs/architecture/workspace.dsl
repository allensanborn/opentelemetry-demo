workspace "OpenTelemetry Astronomy Shop — System Landscape" "Multi-system, team-aligned C4 model: each domain is its own software system, with a shared Platform group for cross-cutting capabilities (feature flags, observability)." {

    model {
        # Container-level edges are the source of truth; implied relationships roll them up
        # to system-to-system edges for the System Landscape view.
        !impliedRelationships true

        customer = person "Customer" "Browses the catalog, places orders, and chats with the shopping assistant."

        # =================== Stream-aligned (business) systems ===================

        storefront = softwareSystem "Storefront" "Public web store and API gateway. (Team: Web)" {
            proxy         = container "Frontend Proxy" "Single public entrypoint; routes browser traffic." "Envoy"
            frontend      = container "Frontend" "Web store + backend-for-frontend aggregating the shop services." "TypeScript / Next.js"
            imageProvider = container "Image Provider" "Serves static product images." "nginx"
        }

        assistant = softwareSystem "Shopping Assistant" "Conversational shopping help backed by an LLM. (Team: AI)" {
            chatbot = container "Chatbot" "Chat UI for the assistant." "Python / FastAPI"
            agent   = container "Agent" "LLM agent; calls shop tools and an external model." "Python / LangChain + LangGraph"
            mcp     = container "MCP Server" "Exposes the shop API to the agent as MCP tools." "Python / FastMCP"
        }

        catalog = softwareSystem "Product Catalog" "Owns product data and lookup. (Team: Catalog)" {
            productCatalog = container "Product Catalog Service" "Lists and looks up products." "Go"
            catalogDb      = container "Catalog DB" "Product data — the catalog schema/database this team owns and deploys independently." "PostgreSQL" {
                tags "Database"
            }
        }

        recommendations = softwareSystem "Recommendations" "Suggests related products. (Team: Growth)" {
            recommendation = container "Recommendation Service" "Computes product recommendations." "Python"
        }

        ads = softwareSystem "Ads" "Contextual advertising. (Team: Growth)" {
            ad = container "Ad Service" "Returns contextual ads for a product category." "Java"
        }

        cart = softwareSystem "Cart" "Owns the shopping cart. (Team: Cart)" {
            cartSvc   = container "Cart Service" "Holds each user's shopping cart." "C# / .NET"
            cartStore = container "Cart Store" "Cart contents keyed by user." "Valkey (Redis-compatible)" {
                tags "Database"
            }
        }

        orders = softwareSystem "Checkout & Orders" "Order placement and the async order lifecycle. (Team: Orders)" {
            checkout       = container "Checkout Service" "Orchestrates order placement across cart, payment, shipping, and email." "Go"
            accounting     = container "Accounting Service" "Records placed orders for bookkeeping." "C# / .NET"
            fraudDetection = container "Fraud Detection Service" "Flags potentially fraudulent orders." "Kotlin / JVM"
            orderBus       = container "Order Bus" "Streams placed-order events to the async consumers (topic: orders)." "Apache Kafka" {
                tags "Queue"
            }
            accountingDb   = container "Accounting DB" "Order records — the accounting schema/database this team owns and deploys independently." "PostgreSQL" {
                tags "Database"
            }
        }

        payments = softwareSystem "Payments" "Card charging. (Team: Payments)" {
            payment = container "Payment Service" "Charges the order to a credit card (mock)." "Node.js"
        }

        shipping = softwareSystem "Shipping" "Shipping cost and fulfilment. (Team: Fulfilment)" {
            shippingSvc = container "Shipping Service" "Calculates shipping cost and ships the order." "Rust"
            quote       = container "Quote Service" "Computes shipping-cost quotes." "PHP"
        }

        notifications = softwareSystem "Notifications" "Customer messaging. (Team: Comms)" {
            email = container "Email Service" "Sends the order-confirmation email (mock)." "Ruby / Sinatra"
        }

        currency = softwareSystem "Currency" "Shared currency conversion. (Team: Platform / Shared Services)" {
            currencySvc = container "Currency Service" "Converts money between currencies." "C++"
        }

        # =========================== Platform group ==============================
        # Org-owned, shared capabilities every stream-aligned system consumes.

        group "Platform" {
            flagSystem = softwareSystem "Feature Flags" "Feature-flag evaluation as-a-service over the OpenFeature/OFREP contract. Product teams consume it; the Platform team owns hosting. (Team: Platform)" {
                tags "Platform"
                flagd   = container "flagd" "Evaluates feature flags over OpenFeature." "Go / OpenFeature"
                flagdUi = container "flagd UI" "Edits flag definitions." "Elixir / Phoenix"
            }

            obsPlatform = softwareSystem "Observability Platform" "Telemetry ingest, storage, and dashboards as-a-service over the OTLP contract. Product teams export to it; the Platform team owns the backends — self-hosted today, swappable for a SaaS (e.g. Honeycomb) without changing consumers. (Team: Platform)" {
                tags "Platform"
                collector  = container "OTel Collector" "Receives OTLP; fans out to the backends." "OpenTelemetry Collector"
                jaeger     = container "Jaeger" "Trace storage & UI." "Jaeger"
                prometheus = container "Prometheus" "Metrics storage." "Prometheus"
                opensearch = container "OpenSearch" "Log & trace storage." "OpenSearch"
                grafana    = container "Grafana" "Dashboards over metrics, traces, and logs." "Grafana"
            }
        }

        # ============================ External systems ===========================

        llm = softwareSystem "LLM API" "Third-party OpenAI-compatible model endpoint." {
            tags "External"
        }
        loadgen = softwareSystem "Load Generator" "Simulates real users with synthetic traffic (k6)." {
            tags "External"
        }

        # ============================ Relationships ==============================
        # Intra- and inter-system calls at the container level; implied relationships
        # aggregate them to the system level for the landscape.

        # -- Entry / edge --
        customer -> proxy "Browses, buys, and chats via" "HTTPS"
        loadgen  -> proxy "Drives synthetic traffic through" "HTTPS / k6"
        proxy -> frontend      "Routes web & API requests to" "HTTP"
        proxy -> imageProvider "Routes product-image requests to" "HTTP"
        proxy -> chatbot       "Routes chat requests to" "HTTP"

        # -- Storefront fan-out --
        frontend -> ad             "Requests contextual ads from" "gRPC"
        frontend -> cartSvc        "Reads and updates the cart via" "gRPC"
        frontend -> checkout       "Places orders through" "gRPC"
        frontend -> currencySvc    "Converts prices via" "gRPC"
        frontend -> productCatalog "Looks up products via" "gRPC"
        frontend -> recommendation "Requests recommendations from" "gRPC"
        frontend -> shippingSvc    "Requests shipping quotes from" "HTTP"

        # -- Shopping Assistant --
        chatbot -> agent    "Forwards user prompts to" "HTTP"
        agent   -> mcp      "Invokes shop tools via" "HTTP (MCP)"
        agent   -> llm      "Sends prompts to" "HTTPS"
        mcp     -> frontend "Calls the shop REST API on" "HTTP"

        # -- Checkout & Orders --
        checkout -> cartSvc        "Reads and clears the cart via" "gRPC"
        checkout -> currencySvc    "Converts order totals via" "gRPC"
        checkout -> productCatalog "Looks up product details via" "gRPC"
        checkout -> payment        "Charges the order via" "gRPC"
        checkout -> shippingSvc    "Ships the order via" "HTTP"
        checkout -> email          "Sends the confirmation email via" "HTTP"
        checkout       -> orderBus "Publishes 'orders' events to" "Kafka"
        accounting     -> orderBus "Consumes 'orders' events from" "Kafka"
        fraudDetection -> orderBus "Consumes 'orders' events from" "Kafka"
        accounting     -> accountingDb "Writes order records to" "SQL"

        # -- Catalog / Recommendations / Cart / Shipping (intra + cross) --
        productCatalog -> catalogDb      "Reads product data from" "SQL"
        recommendation -> productCatalog "Looks up product details via" "gRPC"
        cartSvc        -> cartStore      "Reads and writes cart state in" "RESP / TCP"
        shippingSvc    -> quote          "Requests shipping cost from" "HTTP"

        # -- Observability Platform internals --
        collector  -> jaeger     "Exports traces to" "OTLP"
        collector  -> opensearch "Exports logs to" "OTLP"
        prometheus -> collector  "Scrapes metrics from" "HTTP"
        grafana    -> prometheus "Queries metrics from" "HTTP"
        grafana    -> jaeger     "Queries traces from" "HTTP"
        grafana    -> opensearch "Queries logs from" "HTTP"

        # -- Feature Flags internals --
        flagdUi -> flagd "Edits flag definitions in" "HTTP"

        # -- Cross-cutting: telemetry export (tagged, kept off the clean landscape) --
        proxy          -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        frontend       -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        imageProvider  -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        chatbot        -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        agent          -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        mcp            -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        ad             -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        cartSvc        -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        checkout       -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        accounting     -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        fraudDetection -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        currencySvc    -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        productCatalog -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        recommendation -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        payment        -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        shippingSvc    -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        quote          -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"
        email          -> collector "Exports traces, metrics & logs via" "OTLP" "Telemetry"

        # -- Cross-cutting: feature-flag evaluation (tagged) --
        frontend       -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        ad             -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        cartSvc        -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        checkout       -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        currencySvc    -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        productCatalog -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        recommendation -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        payment        -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        shippingSvc    -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        quote          -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"
        email          -> flagd "Evaluates feature flags via" "gRPC / OFREP" "FeatureFlag"

        # ===================== Deployment (physical topology) ====================
        # The home for facts the static views abstract away: where containers run,
        # and — crucially — that the two logically-separate databases are physically
        # co-located on ONE Postgres instance. Representative slice, not every service.
        deploymentEnvironment "Production" {
            deploymentNode "Kubernetes Cluster" "Managed cluster" "Kubernetes" {

                ingress = infrastructureNode "Ingress / Load Balancer" "Cluster entrypoint; terminates TLS and routes to the storefront." "Cloud LB"

                deploymentNode "Stream-aligned workloads" "One pod group per team" {
                    deploymentNode "Storefront pod" {
                        web = containerInstance frontend
                    }
                    deploymentNode "Checkout & Orders pod" {
                        containerInstance checkout
                        containerInstance accounting
                    }
                    deploymentNode "Product Catalog pod" {
                        containerInstance productCatalog
                    }
                    deploymentNode "Cart pod" {
                        containerInstance cartSvc
                    }
                }

                deploymentNode "Stateful services" {
                    deploymentNode "astronomy-db — one PostgreSQL instance" "Both team databases are separate SCHEMAS in the same physical instance — a deployment fact, invisible on the static container views." "PostgreSQL" {
                        containerInstance catalogDb
                        containerInstance accountingDb
                    }
                    deploymentNode "valkey" "Redis-compatible" "Valkey" {
                        containerInstance cartStore
                    }
                    deploymentNode "kafka" "Broker" "Apache Kafka" {
                        containerInstance orderBus
                    }
                }

                deploymentNode "Platform (Platform team; self-hosted, swappable for a SaaS backend)" {
                    deploymentNode "OTLP gateway" "One central collector all pods send OTLP to (gateway pattern; a per-pod sidecar or per-node agent are the alternative collection topologies)." {
                        containerInstance collector
                    }
                    deploymentNode "Telemetry backends" {
                        containerInstance jaeger
                        containerInstance prometheus
                        containerInstance opensearch
                        containerInstance grafana
                    }
                    deploymentNode "Feature-flag service" {
                        containerInstance flagd
                    }
                }
            }

            ingress -> web "Forwards HTTPS to" "HTTPS"
        }
    }

    views {
        # 1. The hero: clean, team-aligned landscape — Platform group excluded.
        systemLandscape "Landscape" "Team-aligned system landscape (business systems). Platform and telemetry wiring shown separately." {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }

        # 2. Platform in context: the full landscape including the shared Platform group.
        systemLandscape "PlatformLandscape" "Full landscape including the shared Platform group (feature flags + observability) that every system consumes." {
            include *
            autolayout lr
        }

        # 3a. Per-team System Context views — externality is scope-relative: from a
        #     product team's chair the Platform (and other teams' systems) are external
        #     dependencies it consumes but does not own.
        systemContext orders "OrdersContext" "Checkout & Orders from its team's viewpoint: the systems and platform services it depends on but does not control." {
            include *
            autolayout lr
        }
        systemContext cart "CartContext" "Cart from its team's viewpoint: a small system that still depends on the shared Platform as-a-service." {
            include *
            autolayout lr
        }

        # 3b. Per-system container views — each now team-sized.
        container storefront "Storefront" {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        container assistant "ShoppingAssistant" {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        container orders "CheckoutOrders" {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        container catalog "ProductCatalog" {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        container cart "Cart" {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }
        container shipping "Shipping" {
            include *
            exclude flagSystem
            exclude obsPlatform
            autolayout lr
        }

        # 4. Platform internals — how the shared capabilities themselves are built.
        container obsPlatform "ObservabilityPlatform" {
            include collector jaeger prometheus opensearch grafana
            autolayout lr
        }
        container flagSystem "FeatureFlags" {
            include flagd flagdUi
            autolayout lr
        }

        # 5. Deployment view — physical topology (representative slice).
        deployment * "Production" "Deployment" "Where containers actually run. Note the astronomy-db node: Catalog DB and Accounting DB are separate schemas co-located on one Postgres instance — a physical fact the static container views deliberately hide. Cross-cutting telemetry/feature-flag edges are omitted for clarity." {
            include *
            exclude "relationship.tag==Telemetry"
            exclude "relationship.tag==FeatureFlag"
            autolayout lr
        }

        styles {
            # Three ownership classes: (blue, default) = our product systems;
            # (slate, solid) = internal but another team's — the Platform;
            # (grey, dashed) = outside our org entirely — third-party / tooling.
            element "External" {
                background #8a8a8a
                color #ffffff
                border dashed
            }
            element "Platform" {
                background #667085
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
