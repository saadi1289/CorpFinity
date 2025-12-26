import asyncio
from typing import Optional
from pydantic import BaseModel


class Result(BaseModel):
    """Simple result wrapper for operations."""
    success: bool
    data: Optional[dict] = None
    error: Optional[str] = None
    
    @classmethod
    def success_result(cls, data: dict = None) -> "Result":
        return cls(success=True, data=data)
    
    @classmethod
    def error_result(cls, error: str) -> "Result":
        return cls(success=False, error=error)
