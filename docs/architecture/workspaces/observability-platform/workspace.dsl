workspace extends ../system-catalog/workspace.dsl {

    model {
        !element obsPlatform {
            collector  = container "OTel Collector" "Receives OTLP; fans out to the backends." "OpenTelemetry Collector"
            jaeger     = container "Jaeger" "Trace storage & UI." "Jaeger"
            prometheus = container "Prometheus" "Metrics storage." "Prometheus"
            opensearch = container "OpenSearch" "Log & trace storage." "OpenSearch"
            grafana    = container "Grafana" "Dashboards over metrics, traces, and logs." "Grafana"
        }

        collector  -> jaeger     "Exports traces to" "OTLP"
        collector  -> opensearch "Exports logs to" "OTLP"
        prometheus -> collector  "Scrapes metrics from" "HTTP"
        grafana    -> prometheus "Queries metrics from" "HTTP"
        grafana    -> jaeger     "Queries traces from" "HTTP"
        grafana    -> opensearch "Queries logs from" "HTTP"
    }

    views {
        container obsPlatform "Containers" "Inside the Observability Platform — the OTLP ingest gateway and the storage/dashboard backends. Every other system sends OTLP to the collector (those edges are declared in each consumer's workspace)." {
            include *
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
