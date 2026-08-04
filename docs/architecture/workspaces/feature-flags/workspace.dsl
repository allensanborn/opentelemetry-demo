workspace extends ../system-catalog/workspace.dsl {

    model {
        !impliedRelationships true
        !element flagSystem {
            flagd   = container "flagd" "Evaluates feature flags over OpenFeature." "Go / OpenFeature"
            flagdUi = container "flagd UI" "Edits flag definitions." "Elixir / Phoenix"
        }

        flagdUi -> flagd "Edits flag definitions in" "HTTP"

        # the platform is itself instrumented
        flagd -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }

    views {
        systemContext flagSystem "Context" "The Feature Flags platform capability." {
            include *
            autolayout lr
        }
        container flagSystem "Containers" "Inside the Feature Flags platform." {
            include *
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
