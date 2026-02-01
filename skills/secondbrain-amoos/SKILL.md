---
name: secondbrain-amoos
description: Deep integration with amoOS SecondBrain knowledge base for RAG search, content creation, and quick capture
metadata:
  openclaw:
    emoji: "🧠"
    requires:
      env:
        - SECONDBRAIN_API_KEY
        - SECONDBRAIN_BASE_URL
---

# amoOS SecondBrain Integration

You have full access to the user's personal knowledge base and content engine via the amoOS SecondBrain API.

## Authentication

All requests require:
- Header: `Authorization: Bearer ${SECONDBRAIN_API_KEY}`
- Base URL: `${SECONDBRAIN_BASE_URL}`

## Available Operations

### Knowledge Base

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/knowledge/brain/search?q=<query>` | GET | Search knowledge base |
| `/api/v1/chat` | POST | RAG chat with knowledge context |
| `/api/v1/ingest/note` | POST | Quick capture note |
| `/api/v1/files` | GET | List documents |

### Content Engine

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/content-engine/topics` | GET | Get topic suggestions |
| `/api/v1/content-engine/topics/{id}/draft` | POST | Generate draft |
| `/api/v1/content-engine/discover` | POST | Discover new topics |

---

## Detailed API Reference

### 1. Search Knowledge Base

Search for relevant documents, notes, and concepts.

**Endpoint**: `GET /api/v1/knowledge/brain/search`

**Query Parameters**:
- `query` (required): Search query text
- `limit` (optional): Max results (default: 10, max: 50)
- `include_concepts` (optional): Include extracted concepts (default: true)

**Example**:
```bash
curl -X GET "${SECONDBRAIN_BASE_URL}/api/v1/knowledge/brain/search?query=machine+learning&limit=5" \
  -H "Authorization: Bearer ${SECONDBRAIN_API_KEY}"
```

**Response**: List of relevant documents with content snippets, sources, and relevance scores.

**When to use**: Before answering knowledge-related questions. Search first, then synthesize.

---

### 2. RAG Chat

Ask questions with RAG context from the knowledge base.

**Endpoint**: `POST /api/v1/chat`

**Request Body**:
```json
{
  "message": "What do I know about distributed systems?",
  "use_rag": true,
  "stream": false
}
```

**Response**: AI-generated answer with citations to source documents.

**When to use**: For complex questions requiring synthesis from multiple sources.

---

### 3. Quick Capture (Add Note)

Capture notes, thoughts, or information to the knowledge base.

**Endpoint**: `POST /api/v1/ingest/note`

**Request Body**:
```json
{
  "content": "Remember: quarterly review meeting moved to Friday 3pm",
  "title": "Meeting reminder",
  "tags": ["meetings", "reminders"],
  "source": "openclaw"
}
```

**Response**: Created note with ID and confirmation.

**When to use**: When the user mentions actionable items, wants to remember something, or explicitly asks to save a note.

---

### 4. Get Content Topics

Retrieve AI-generated content topic suggestions.

**Endpoint**: `GET /api/v1/content-engine/topics`

**Query Parameters**:
- `status` (optional): Filter by status (pending, snoozed, shipped)
- `limit` (optional): Max topics to return

**Response**: List of topic suggestions with titles, angles, and supporting evidence.

**When to use**: When the user asks about content ideas or what to write about.

---

### 5. Generate Content Draft

Generate a content draft for a specific topic.

**Endpoint**: `POST /api/v1/content-engine/topics/{topic_id}/draft`

**Request Body**:
```json
{
  "tone": "professional",
  "format": "linkedin_post",
  "max_words": 300
}
```

**Response**: Generated draft content with the specified tone and format.

**When to use**: When creating content from a topic suggestion.

---

### 6. Discover New Topics

Trigger topic discovery from recent work signals.

**Endpoint**: `POST /api/v1/content-engine/discover`

**Request Body**:
```json
{
  "lookback_days": 7
}
```

**Response**: Newly discovered topics added to the queue.

**When to use**: When the user wants fresh content ideas based on recent activity.

---

### 7. List Documents

Get a list of documents in the knowledge base.

**Endpoint**: `GET /api/v1/files`

**Query Parameters**:
- `search` (optional): Filter by title/content
- `limit` (optional): Max results
- `offset` (optional): Pagination offset

**Response**: List of documents with metadata.

---

### 8. Health Check

Verify SecondBrain is accessible.

**Endpoint**: `GET /api/v1/health`

**Response**: Service status and version.

---

## Usage Guidelines

1. **Search before answering**: When the user asks about their knowledge or documents, always search first rather than relying on your general knowledge.

2. **Cite sources**: When referencing information from the knowledge base, mention which document or note it came from.

3. **Capture proactively**: When the user mentions actionable items, deadlines, or important information, offer to save it as a note.

4. **Respect privacy**: The knowledge base contains personal information. Never share specifics with third parties or in public contexts.

5. **Handle errors gracefully**: If SecondBrain is unavailable, inform the user and offer to try again later.

## Example Interactions

### User: "What do I know about Kubernetes?"
1. Search: `GET /api/v1/knowledge/brain/search?query=kubernetes`
2. Synthesize results into a coherent answer
3. Cite the source documents

### User: "Remember that I need to call John about the project"
1. Capture: `POST /api/v1/ingest/note` with appropriate content
2. Confirm the note was saved

### User: "What should I write about this week?"
1. Get topics: `GET /api/v1/content-engine/topics?status=pending`
2. Present the top suggestions with brief explanations

### User: "Search for my notes on Python async"
1. Search: `GET /api/v1/knowledge/brain/search?query=python+async`
2. Present the relevant documents with snippets

### User: "Generate a draft for that topic about RAG architectures"
1. Generate: `POST /api/v1/content-engine/topics/{topic_id}/draft`
2. Return the generated content

## Error Handling

| Status Code | Meaning | Action |
|-------------|---------|--------|
| 401 | Invalid API key | Check SECONDBRAIN_API_KEY configuration |
| 404 | Resource not found | The requested item doesn't exist |
| 503 | Service unavailable | SecondBrain may be down, try again later |
| 429 | Rate limited | Wait before retrying |

## Rate Limits

- Search: 60 requests/minute
- Chat: 20 requests/minute
- Write operations: 30 requests/minute

Respect these limits to avoid service disruption.
