---
name: api-security
title: OWASP API Security Top 10 Patterns
description: API authentication, authorization, input validation, rate limiting, and protection patterns
compatibility: ["agent:api-security"]
metadata:
  domain: security
  maturity: production
  audience: [api-developer, security-engineer, architect]
allowed-tools: [python, javascript, bash, docker]
---

# API Security Skill

Production patterns for securing REST and GraphQL APIs against OWASP API Security Top 10 vulnerabilities.

## 1. API Authentication & JWT

```python
from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthCredentials
import jwt
from datetime import datetime, timedelta

security = HTTPBearer()
SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"

def create_access_token(data: dict, expires_in: int = 3600):
    """Create JWT token with expiration."""
    payload = data.copy()
    payload['exp'] = datetime.utcnow() + timedelta(seconds=expires_in)
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(credentials: HTTPAuthCredentials = Depends(security)):
    """Verify JWT token from Authorization header."""
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

@app.get("/protected")
async def protected_route(token: dict = Depends(verify_token)):
    return {"user_id": token.get("sub")}
```

## 2. Authorization (RBAC)

```python
from enum import Enum

class Role(str, Enum):
    ADMIN = "admin"
    USER = "user"
    GUEST = "guest"

def require_role(*roles):
    """Decorator to enforce role-based access control."""
    async def role_checker(token: dict = Depends(verify_token)):
        user_role = token.get("role")
        if user_role not in roles:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return token
    return role_checker

@app.delete("/admin/users/{user_id}")
async def delete_user(
    user_id: str,
    token: dict = Depends(require_role(Role.ADMIN))
):
    # Only admins can delete users
    return {"deleted": user_id}
```

## 3. Input Validation & XSS Prevention

```python
from pydantic import BaseModel, Field, validator
from html import escape

class CreatePostRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1, max_length=10000)
    tags: list[str] = Field(default=[], max_items=10)
    
    @validator('title', 'content', pre=True)
    def sanitize_html(cls, v):
        """Escape HTML to prevent XSS."""
        return escape(v) if isinstance(v, str) else v
    
    @validator('tags', pre=True)
    def validate_tags(cls, v):
        """Validate tag format."""
        if not all(isinstance(tag, str) and 1 <= len(tag) <= 50 for tag in v):
            raise ValueError("Invalid tag format")
        return v

@app.post("/posts")
async def create_post(
    post: CreatePostRequest,
    token: dict = Depends(verify_token)
):
    # Input is automatically validated and sanitized
    return {"id": "123", **post.dict()}
```

## 4. SQL Injection Prevention (Parameterized Queries)

```python
import psycopg2
from psycopg2.extras import RealDictCursor

def get_user_by_id(user_id: int):
    """Fetch user using parameterized query (safe from SQLi)."""
    conn = psycopg2.connect(dbname="mydb")
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # CORRECT: Parameterized query
    cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    
    # INCORRECT: String concatenation (vulnerable)
    # cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
    
    return cursor.fetchone()
```

## 5. Rate Limiting

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/auth/login")
@limiter.limit("5/minute")  # Max 5 login attempts per minute
async def login(request: Request, credentials: LoginRequest):
    # Attempt login
    return {"token": "..."}

@app.get("/api/search")
@limiter.limit("100/hour")  # Max 100 requests per hour
async def search(q: str):
    return {"results": [...]}
```

## 6. API Key Security

```python
from fastapi.security import APIKeyHeader
from starlette.status import HTTP_403_FORBIDDEN

api_key_header = APIKeyHeader(name="X-API-Key")
VALID_KEYS = {"key-abc123", "key-def456"}

async def verify_api_key(api_key: str = Depends(api_key_header)):
    """Verify API key from header."""
    if api_key not in VALID_KEYS:
        raise HTTPException(status_code=HTTP_403_FORBIDDEN, detail="Invalid API key")
    return api_key

@app.get("/data")
async def get_data(api_key: str = Depends(verify_api_key)):
    return {"data": "sensitive"}
```

## 7. CORS Configuration

```python
from fastapi.middleware.cors import CORSMiddleware

# CORRECT: Restrict to trusted origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://trusted-domain.com", "https://app.example.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)

# INCORRECT: Allow all origins (unsafe)
# allow_origins=["*"]
```

## 8. HTTPS & Security Headers

```python
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'"
    
    return response
```

## 9. GraphQL Security

```python
from ariadne import QueryType, graphql_sync
from graphql import GraphQLError

query = QueryType()

@query.field("user")
def resolve_user(_, info, id):
    """Resolve user with rate limiting and authorization."""
    # Verify authentication
    if not info.context.get("user"):
        raise GraphQLError("Unauthorized")
    
    # Check authorization
    if info.context["user"].get("role") != "admin" and info.context["user"]["id"] != id:
        raise GraphQLError("Forbidden")
    
    # Prevent N+1 queries with DataLoader
    return info.context["user_loader"].load(id)
```

## 10. Logging & Monitoring

```python
import logging

logger = logging.getLogger(__name__)

@app.post("/login")
async def login(credentials: LoginRequest):
    try:
        user = authenticate(credentials.username, credentials.password)
        logger.info(f"User {credentials.username} logged in successfully")
        return {"token": create_token(user)}
    except AuthenticationError:
        logger.warning(f"Failed login attempt for user {credentials.username}")
        raise HTTPException(status_code=401, detail="Invalid credentials")
    except Exception as e:
        logger.error(f"Login error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")
```

---

## References

- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [REST API Security Best Practices](https://restfulapi.net/security-essentials/)
