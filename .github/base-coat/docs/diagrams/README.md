# Architecture Diagrams

Visual reference for BaseCoat's architecture, memory model, and process flows.
Open `.excalidraw` files at [https://aka.ms/excalidraw](https://aka.ms/excalidraw).

## Architecture

| Diagram | Description |
|---|---|
| [execution-hierarchy.excalidraw](execution-hierarchy.excalidraw) | 5-layer execution stack from user intent to output |
| [multi-agent-orchestration.excalidraw](multi-agent-orchestration.excalidraw) | LangGraph StateGraph fan-out/fan-in pattern |
| [asset-taxonomy.excalidraw](asset-taxonomy.excalidraw) | Four primitive asset types: agents, skills, instructions, prompts |

## Memory Model

| Diagram | Description |
|---|---|
| [memory-lookup-hierarchy.excalidraw](memory-lookup-hierarchy.excalidraw) | L0–L4 memory layer lookup and retrieval cost |
| [two-tier-memory-model.excalidraw](two-tier-memory-model.excalidraw) | Personal vs shared memory tiers |
| [memory-promotion-flow.excalidraw](memory-promotion-flow.excalidraw) | Pattern promotion and demotion ladder |

## Process Flows

| Diagram | Description |
|---|---|
| [intent-routing.excalidraw](intent-routing.excalidraw) | Fast-path vs deep-reasoning routing decision |
| [turn-budget-protocol.excalidraw](turn-budget-protocol.excalidraw) | Token budget enforcement and graceful degradation |
| [agentic-workflow-lifecycle.excalidraw](agentic-workflow-lifecycle.excalidraw) | PR trigger → filter → agent → buffer → safe output |
| [bootstrap-flow.excalidraw](bootstrap-flow.excalidraw) | 4-phase bootstrap script: repo, memory, secrets, validation |
