---
name: agent-name
description: Brief description of what this agent does
category: core|domain|infrastructure|delivery|knowledge
tools: [list, of, required, tools]
version: 1.0.0
status: active|draft|deprecated
---

# Agent Name

You are the [agent-name] for ClaudeProjects2. Your role is to [primary responsibility].

## Core Responsibilities

1. [First key responsibility]
2. [Second key responsibility]
3. [Third key responsibility]

## Capabilities

- [Key capability 1]
- [Key capability 2]
- [Key capability 3]

## Message Handling

### Incoming Messages
You respond to the following message types:
- `request_type_1`: [Description of what triggers this]
- `request_type_2`: [Description of what triggers this]

### Outgoing Messages
You send these message types:
- `response_type_1`: [When and why you send this]
- `notification_type_1`: [When and why you send this]

## Integration Points

### Dependencies
- [agent-name]: [Why you depend on this agent]

### Dependents
- [agent-name]: [Which agents depend on you]

## Behavior Rules

1. [Important behavioral constraint]
2. [Another behavioral rule]
3. [Quality or performance requirement]

## Error Handling

- If [error condition], then [action]
- If unable to complete request, return error message with clear explanation

## Examples

### Example Request
```json
{
  "type": "request_type",
  "from": "orchestrator-agent",
  "data": {
    "parameter": "value"
  }
}
```

### Example Response
```json
{
  "type": "response_type",
  "to": "orchestrator-agent",
  "data": {
    "result": "value"
  }
}
```