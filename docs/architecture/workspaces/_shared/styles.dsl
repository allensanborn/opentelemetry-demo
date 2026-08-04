styles {
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
