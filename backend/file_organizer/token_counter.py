#!/usr/bin/env python3
"""
Token Counter Service
Provides token counting functionality for AI prompts
"""

import logging
from typing import Optional

logger = logging.getLogger('TokenCounter')


class TokenCounter:
    """
    Service for counting tokens in text before sending to AI.
    Supports multiple AI providers with fallback estimation.
    """
    
    def __init__(self, shared_services=None):
        """
        Initialize token counter with AI model access.
        
        Args:
            shared_services: Shared services instance with AI model
        """
        self.shared_services = shared_services
    
    def count_tokens(self, text: str) -> dict:
        """
        Count tokens in text using the AI model's tokenizer.
        
        Args:
            text: Text to count tokens for
            
        Returns:
            Dictionary with:
                - tokens: Number of tokens
                - method: How tokens were counted ('exact', 'estimated')
                - characters: Number of characters
                - provider: AI provider name
        """
        char_count = len(text)
        
        try:
            if not self.shared_services or not self.shared_services.ai_model:
                # No AI available, use estimation
                return self._estimate_tokens(text, char_count)
            
            provider = self.shared_services.ai_model.provider
            
            # Try provider-specific token counting
            if provider == 'gemini':
                # Gemini models have count_tokens method
                if hasattr(self.shared_services.ai_model, 'model'):
                    model = self.shared_services.ai_model.model
                    if hasattr(model, 'count_tokens'):
                        try:
                            result = model.count_tokens(text)
                            return {
                                'tokens': result.total_tokens,
                                'method': 'exact',
                                'characters': char_count,
                                'provider': provider
                            }
                        except Exception as e:
                            logger.debug(f"Gemini token counting failed: {e}")
            
            elif provider == 'kimi':
                # Kimi uses OpenAI-compatible API
                # Try to use tiktoken for OpenAI-compatible models
                try:
                    import tiktoken
                    # Use cl100k_base encoding (GPT-4, GPT-3.5-turbo)
                    encoding = tiktoken.get_encoding("cl100k_base")
                    tokens = encoding.encode(text)
                    return {
                        'tokens': len(tokens),
                        'method': 'exact',
                        'characters': char_count,
                        'provider': provider
                    }
                except ImportError:
                    logger.debug("tiktoken not available, using estimation")
                except Exception as e:
                    logger.debug(f"tiktoken counting failed: {e}")
            
            # Fallback to estimation for unknown providers or if counting failed
            return self._estimate_tokens(text, char_count, provider)
            
        except Exception as e:
            logger.warning(f"Token counting error: {e}")
            return self._estimate_tokens(text, char_count)
    
    def _estimate_tokens(self, text: str, char_count: int, provider: str = 'unknown') -> dict:
        """
        Estimate token count using character-based heuristic.
        
        Args:
            text: Text to estimate tokens for
            char_count: Number of characters
            provider: AI provider name
            
        Returns:
            Dictionary with estimated token count
        """
        # Rough estimation: 1 token ≈ 4 characters for English text
        # This is a conservative estimate that works reasonably well
        estimated_tokens = char_count // 4
        
        return {
            'tokens': estimated_tokens,
            'method': 'estimated',
            'characters': char_count,
            'provider': provider
        }
    
    def estimate_cost(self, input_tokens: int, output_tokens: int = 0, provider: str = None) -> dict:
        """
        Estimate cost based on token counts.
        
        Args:
            input_tokens: Number of input tokens
            output_tokens: Number of output tokens (optional)
            provider: AI provider name (auto-detected if None)
            
        Returns:
            Dictionary with cost information
        """
        # Auto-detect provider from shared services if not specified
        if provider is None and self.shared_services and self.shared_services.ai_model:
            provider = self.shared_services.ai_model.provider
        
        # Default to gemini if still unknown
        if provider is None:
            provider = 'gemini'
        
        # Pricing per 1M tokens (as of 2024)
        pricing = {
            'gemini': {
                'input': 0.075,   # $0.075 per 1M input tokens
                'output': 0.30,   # $0.30 per 1M output tokens
                'name': 'Google Gemini'
            },
            'kimi': {
                'input': 0.10,    # Kimi pricing (adjust if you know exact pricing)
                'output': 0.40,   # Kimi pricing (adjust if you know exact pricing)
                'name': 'Kimi AI'
            },
            'openai': {
                'input': 0.50,    # GPT-4 pricing
                'output': 1.50,
                'name': 'OpenAI GPT-4'
            }
        }
        
        provider_pricing = pricing.get(provider.lower(), pricing['gemini'])
        
        input_cost = (input_tokens / 1_000_000) * provider_pricing['input']
        output_cost = (output_tokens / 1_000_000) * provider_pricing['output']
        total_cost = input_cost + output_cost
        
        return {
            'input_tokens': input_tokens,
            'output_tokens': output_tokens,
            'total_tokens': input_tokens + output_tokens,
            'input_cost_usd': round(input_cost, 6),
            'output_cost_usd': round(output_cost, 6),
            'total_cost_usd': round(total_cost, 6),
            'provider': provider,
            'provider_name': provider_pricing.get('name', provider)
        }
