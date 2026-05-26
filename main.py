#!/usr/bin/env python3
"""
Hermes Agent - Simple Gateway for Groq LLM
Telegram bot + FastAPI server
"""

import os
import json
import asyncio
from typing import Optional
from datetime import datetime

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
from groq import Groq

# Initialize Groq client
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

# FastAPI app
app = FastAPI(title="Hermes Agent")

# In-memory conversation storage
conversations = {}


class MessageRequest(BaseModel):
    """Request model for chat messages"""
    message: str
    user_id: str = "default"
    conversation_id: Optional[str] = None


class MessageResponse(BaseModel):
    """Response model for chat messages"""
    response: str
    conversation_id: str
    timestamp: str


def get_conversation_history(user_id: str, conversation_id: str = None):
    """Get or create conversation history"""
    if conversation_id is None:
        conversation_id = f"{user_id}_{datetime.now().timestamp()}"
    
    key = f"{user_id}_{conversation_id}"
    if key not in conversations:
        conversations[key] = {
            "id": conversation_id,
            "user_id": user_id,
            "messages": [],
            "created_at": datetime.now().isoformat()
        }
    return conversations[key]


def chat_with_groq(user_message: str, history: list) -> str:
    """Send message to Groq and get response"""
    try:
        # Build messages for API
        messages = history + [{"role": "user", "content": user_message}]
        
        # Call Groq API
        response = client.chat.completions.create(
            model="mixtral-8x7b-32768",
            messages=messages,
            max_tokens=1024,
            temperature=0.7,
        )
        
        return response.choices[0].message.content
    except Exception as e:
        return f"Error: {str(e)}"


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "ok", "timestamp": datetime.now().isoformat()}


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "name": "Hermes Agent",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "chat": "/chat",
            "status": "/status",
            "clear": "/clear/{user_id}"
        }
    }


@app.post("/chat")
async def chat(request: MessageRequest) -> MessageResponse:
    """Chat endpoint - send message and get response"""
    if not request.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")
    
    # Get conversation
    conv = get_conversation_history(request.user_id, request.conversation_id)
    
    # Format messages for Groq
    history = [msg for msg in conv["messages"]]
    
    # Get response from Groq
    response_text = chat_with_groq(request.message, history)
    
    # Save to history
    conv["messages"].append({"role": "user", "content": request.message})
    conv["messages"].append({"role": "assistant", "content": response_text})
    
    # Keep only last 20 messages to save memory
    if len(conv["messages"]) > 20:
        conv["messages"] = conv["messages"][-20:]
    
    return MessageResponse(
        response=response_text,
        conversation_id=conv["id"],
        timestamp=datetime.now().isoformat()
    )


@app.get("/status")
async def status():
    """Get status of all conversations"""
    return {
        "total_conversations": len(conversations),
        "conversations": [
            {
                "id": conv["id"],
                "user_id": conv["user_id"],
                "message_count": len(conv["messages"]),
                "created_at": conv["created_at"]
            }
            for conv in conversations.values()
        ]
    }


@app.delete("/clear/{user_id}")
async def clear_history(user_id: str):
    """Clear conversation history for a user"""
    keys_to_delete = [k for k in conversations.keys() if k.startswith(user_id)]
    for key in keys_to_delete:
        del conversations[key]
    
    return {
        "message": f"Cleared {len(keys_to_delete)} conversations",
        "user_id": user_id
    }


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
