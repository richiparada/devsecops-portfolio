"""
DevSecOps Portfolio - API Main Application
FastAPI application with security best practices
"""
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
import os
import logging
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'api_requests_total', 
    'Total API requests', 
    ['method', 'endpoint', 'status']
)
REQUEST_DURATION = Histogram(
    'api_request_duration_seconds', 
    'API request duration'
)

# Create FastAPI app
app = FastAPI(
    title="DevSecOps Portfolio API",
    description="Secure API demonstrating DevSecOps best practices",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

# CORS configuration (restrictive for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Models
class HealthResponse(BaseModel):
    status: str
    timestamp: datetime
    version: str

class Item(BaseModel):
    id: Optional[int] = None
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    created_at: Optional[datetime] = None

class ItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)

# In-memory storage (replace with database in production)
items_db: List[Item] = []
item_id_counter = 1

# Health check endpoint
@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """
    Health check endpoint for Kubernetes liveness/readiness probes
    """
    logger.info("Health check requested")
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow(),
        version="1.0.0"
    )

# Readiness check
@app.get("/ready", response_model=HealthResponse, tags=["Health"])
async def readiness_check():
    """
    Readiness check endpoint
    """
    # Add checks for dependencies (database, cache, etc.)
    return HealthResponse(
        status="ready",
        timestamp=datetime.utcnow(),
        version="1.0.0"
    )

# Metrics endpoint for Prometheus
@app.get("/metrics", tags=["Monitoring"])
async def metrics():
    """
    Prometheus metrics endpoint
    """
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

# CRUD endpoints
@app.get("/api/items", response_model=List[Item], tags=["Items"])
async def get_items():
    """
    Get all items
    """
    logger.info(f"Fetching all items. Count: {len(items_db)}")
    REQUEST_COUNT.labels(method="GET", endpoint="/api/items", status="200").inc()
    return items_db

@app.get("/api/items/{item_id}", response_model=Item, tags=["Items"])
async def get_item(item_id: int):
    """
    Get a specific item by ID
    """
    logger.info(f"Fetching item with ID: {item_id}")
    for item in items_db:
        if item.id == item_id:
            REQUEST_COUNT.labels(method="GET", endpoint="/api/items/{id}", status="200").inc()
            return item
    
    logger.warning(f"Item not found: {item_id}")
    REQUEST_COUNT.labels(method="GET", endpoint="/api/items/{id}", status="404").inc()
    raise HTTPException(status_code=404, detail="Item not found")

@app.post("/api/items", response_model=Item, status_code=status.HTTP_201_CREATED, tags=["Items"])
async def create_item(item: ItemCreate):
    """
    Create a new item
    """
    global item_id_counter
    
    logger.info(f"Creating new item: {item.name}")
    
    new_item = Item(
        id=item_id_counter,
        name=item.name,
        description=item.description,
        created_at=datetime.utcnow()
    )
    
    items_db.append(new_item)
    item_id_counter += 1
    
    REQUEST_COUNT.labels(method="POST", endpoint="/api/items", status="201").inc()
    logger.info(f"Item created successfully with ID: {new_item.id}")
    
    return new_item

@app.put("/api/items/{item_id}", response_model=Item, tags=["Items"])
async def update_item(item_id: int, item_update: ItemCreate):
    """
    Update an existing item
    """
    logger.info(f"Updating item with ID: {item_id}")
    
    for idx, item in enumerate(items_db):
        if item.id == item_id:
            updated_item = Item(
                id=item_id,
                name=item_update.name,
                description=item_update.description,
                created_at=item.created_at
            )
            items_db[idx] = updated_item
            
            REQUEST_COUNT.labels(method="PUT", endpoint="/api/items/{id}", status="200").inc()
            logger.info(f"Item updated successfully: {item_id}")
            return updated_item
    
    logger.warning(f"Item not found for update: {item_id}")
    REQUEST_COUNT.labels(method="PUT", endpoint="/api/items/{id}", status="404").inc()
    raise HTTPException(status_code=404, detail="Item not found")

@app.delete("/api/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Items"])
async def delete_item(item_id: int):
    """
    Delete an item
    """
    logger.info(f"Deleting item with ID: {item_id}")
    
    for idx, item in enumerate(items_db):
        if item.id == item_id:
            items_db.pop(idx)
            REQUEST_COUNT.labels(method="DELETE", endpoint="/api/items/{id}", status="204").inc()
            logger.info(f"Item deleted successfully: {item_id}")
            return
    
    logger.warning(f"Item not found for deletion: {item_id}")
    REQUEST_COUNT.labels(method="DELETE", endpoint="/api/items/{id}", status="404").inc()
    raise HTTPException(status_code=404, detail="Item not found")

from fastapi.responses import HTMLResponse

# Root endpoint with HTML
@app.get("/", response_class=HTMLResponse, tags=["Root"])
async def root():
    """
    Root endpoint serving a beautiful welcome page
    """
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>DevSecOps Portfolio</title>
        <style>
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
                color: white;
                height: 100vh;
                margin: 0;
                display: flex;
                align-items: center;
                justify-content: center;
                text-align: center;
            }
            .container {
                background: rgba(255, 255, 255, 0.1);
                padding: 3rem;
                border-radius: 20px;
                backdrop-filter: blur(10px);
                box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
                border: 1px solid rgba(255, 255, 255, 0.18);
            }
            h1 { font-size: 3.5rem; margin-bottom: 1rem; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
            p { font-size: 1.5rem; color: #e0e0e0; }
            .badge {
                background: #4caf50;
                padding: 0.5rem 1rem;
                border-radius: 50px;
                font-weight: bold;
                display: inline-block;
                margin-top: 1rem;
                animation: pulse 2s infinite;
            }
            @keyframes pulse {
                0% { transform: scale(1); }
                50% { transform: scale(1.05); }
                100% { transform: scale(1); }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>✨ PROYECTO DEVSECOPS CONSEGUIDO ✨</h1>
            <p>Infraestructura Azure + AKS + Seguridad + CI/CD (Simulado)</p>
            <div class="badge" style="background: #4caf50;">Versión 1.1 (Éxito Total)</div>
        </div>
    </body>
    </html>
    """

if __name__ == "__main__":
    import uvicorn
    
    # Get configuration from environment
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", "8000"))
    
    logger.info(f"Starting API server on {host}:{port}")
    
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=os.getenv("ENV", "production") == "development"
    )
