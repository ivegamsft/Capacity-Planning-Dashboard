"""BaseCoat Artifact Schemas using Pydantic v2."""

from enum import Enum
from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List


class CompatibilityEnum(str, Enum):
    """Supported IDE/editor platforms."""
    VSCODE = "VS Code"
    CURSOR = "Cursor"
    WINDSURF = "Windsurf"
    CLAUDE_CODE = "Claude Code"


class MaturityEnum(str, Enum):
    """Artifact maturity levels."""
    ALPHA = "alpha"
    BETA = "beta"
    PRODUCTION = "production"


class Metadata(BaseModel):
    """Shared metadata for agents and skills."""
    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

    category: str = Field(..., min_length=1, max_length=64)
    tags: List[str] = Field(default_factory=list)
    maturity: MaturityEnum = Field(default=MaturityEnum.ALPHA)
    audience: List[str] = Field(default_factory=list)


class Agent(BaseModel):
    """Agent artifact schema for .agent.md files."""
    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

    name: str = Field(..., min_length=1, max_length=64, pattern="^[a-z0-9\\-]+$")
    description: str = Field(..., min_length=1, max_length=1024)
    compatibility: List[CompatibilityEnum] = Field(default_factory=list)
    metadata: Optional[Metadata] = None
    allowed_tools: List[str] = Field(default_factory=list, alias="allowed-tools")
    model: Optional[str] = None


class Skill(BaseModel):
    """Skill artifact schema for SKILL.md files."""
    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

    name: str = Field(..., min_length=1, max_length=64, pattern="^[a-z0-9\\-]+$")
    description: str = Field(..., min_length=1, max_length=1024)
    compatibility: List[CompatibilityEnum] = Field(default_factory=list)
    metadata: Optional[Metadata] = None
    allowed_tools: List[str] = Field(default_factory=list, alias="allowed-tools")
    integrations: List[str] = Field(default_factory=list)


class Instruction(BaseModel):
    """Instruction artifact schema for .instructions.md files."""
    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

    description: str = Field(..., min_length=1, max_length=1024)
    applyTo: str = Field(..., min_length=1, max_length=256, alias="applyTo")
    priority: int = Field(default=1, ge=0, le=10)
    tags: List[str] = Field(default_factory=list)


class Prompt(BaseModel):
    """Prompt artifact schema for .prompt.md files."""
    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

    description: str = Field(..., min_length=1, max_length=1024)
    model: Optional[str] = None
    tools: List[str] = Field(default_factory=list)
    temperature: Optional[float] = Field(default=None, ge=0.0, le=2.0)


class CustomInstruction(BaseModel):
    """Custom instruction artifact schema."""
    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)

    description: str = Field(..., min_length=1, max_length=1024)
    applyTo: str = Field(..., min_length=1, max_length=256, alias="applyTo")
    priority: int = Field(default=1, ge=0, le=10)
