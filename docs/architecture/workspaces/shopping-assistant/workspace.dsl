workspace extends ../system-catalog/workspace.dsl {

    model {
        !element assistant {
            chatbot = container "Chatbot" "Chat UI for the assistant." "Python / FastAPI"
            agent   = container "Agent" "LLM agent; calls shop tools and an external model." "Python / LangChain + LangGraph"
            mcp     = container "MCP Server" "Exposes the shop API to the agent as MCP tools." "Python / FastMCP"
        }

        # intra-system
        chatbot -> agent "Forwards user prompts to" "HTTP"
        agent   -> mcp   "Invokes shop tools via" "HTTP (MCP)"

        # cross-system
        agent -> llm        "Sends prompts to" "HTTPS"
        mcp   -> storefront "Calls the shop REST API on" "HTTP"

        # platform (consumed as-a-service)
        chatbot -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
        agent   -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
        mcp     -> obsPlatform "Exports telemetry via" "OTLP" "Telemetry"
    }

    views {
        systemContext assistant "Context" "Shopping Assistant: the shop it queries, the external model it calls, and the platform it uses." {
            include *
            autolayout lr
        }
        container assistant "Containers" "Inside the Shopping Assistant." {
            include *
            exclude obsPlatform
            autolayout lr
        }
        !include ../_shared/styles.dsl
        theme default
    }
}
