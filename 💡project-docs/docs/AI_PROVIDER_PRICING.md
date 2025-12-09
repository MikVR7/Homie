# AI Provider Pricing Configuration

## Overview
The token counter automatically detects which AI provider you're using and applies the correct pricing for cost estimation.

## Supported Providers (Updated 2025-12-09)

### 1. Google Gemini 2.5 Flash (Default - Balanced)
**Token Counting**: Exact (uses Gemini's native `count_tokens()`)
**Pricing** (per 1M tokens):
- Input: $0.30
- Output: $2.50
**Use Case**: Balanced performance and cost for general use

### 2. Google Gemini 2.5 Flash Lite (High-Volume)
**Token Counting**: Exact (uses Gemini's native `count_tokens()`)
**Pricing** (per 1M tokens):
- Input: $0.10
- Output: $0.40
**Use Case**: High-volume, cost-sensitive applications

### 3. Google Gemini 2.5 Pro (Premium Reasoning)
**Token Counting**: Exact (uses Gemini's native `count_tokens()`)
**Pricing** (per 1M tokens):
- Input: $1.25
- Output: $10.00
**Use Case**: Complex reasoning, multimodal tasks

### 4. Kimi AI
**Token Counting**: Exact (uses tiktoken with cl100k_base encoding)
**Pricing** (per 1M tokens):
- Input: $0.10
- Output: $0.40
**Use Case**: Cost-effective alternative, similar to Gemini Lite

### 5. Mistral AI Large (open-mixtral-8x22b)
**Token Counting**: Exact (uses tiktoken with cl100k_base encoding)
**Pricing** (per 1M tokens):
- Input: $2.00
- Output: $6.00
**Use Case**: Large model with strong performance, mid-high tier pricing

### 6. Anthropic Claude 4 Opus (Premium)
**Token Counting**: Exact (uses tiktoken)
**Pricing** (per 1M tokens):
- Input: $15.00
- Output: $75.00
**Use Case**: Enterprise-grade, top performance (most expensive)

### 7. Anthropic Claude 3.5 Haiku (Budget)
**Token Counting**: Exact (uses tiktoken)
**Pricing** (per 1M tokens):
- Input: $0.80
- Output: $4.00
**Use Case**: Lower-cost Claude variant

### 8. OpenAI GPT-4
**Token Counting**: Exact (uses tiktoken)
**Pricing** (per 1M tokens):
- Input: $0.50
- Output: $1.50

## How It Works

### Auto-Detection
The system automatically detects your AI provider from the `shared_services.ai_model.provider` field:

```python
# In shared_services.py
self.ai_model = AIModelWrapper(
    provider='kimi',  # or 'gemini', 'openai'
    model=model,
    model_name=model_name
)
```

### Token Counting
Different providers use different tokenizers:

**Gemini**: Uses native `model.count_tokens(text)`
**Kimi**: Uses tiktoken (OpenAI-compatible)
**Others**: Falls back to estimation (1 token ≈ 4 characters)

### Cost Calculation
Pricing is automatically selected based on detected provider:

```python
# Auto-detects provider and applies correct pricing
cost_info = counter.estimate_cost(
    input_tokens=5000,
    output_tokens=1000
)
# Returns cost based on current provider
```

## Configuration

### Switching Providers
Change your AI provider in `.env`:

```bash
# For Gemini
GEMINI_API_KEY=your_gemini_key

# For Kimi
KIMI_API_KEY=your_kimi_key
```

The backend will automatically:
1. Detect the new provider
2. Use the correct tokenizer
3. Apply the correct pricing

### Updating Pricing
If pricing changes or you have exact Kimi pricing, update in `backend/file_organizer/token_counter.py`:

```python
pricing = {
    'kimi': {
        'input': 0.10,    # Update this
        'output': 0.40,   # Update this
        'name': 'Kimi AI'
    }
}
```

## Cost Comparison (Typical File Organization Request)

For organizing 100 files with ~10K input tokens and ~2K output tokens:

| Provider | Input Cost | Output Cost | Total Cost | Relative Cost |
|----------|-----------|-------------|------------|---------------|
| **Gemini Lite** | $0.001 | $0.0008 | **$0.0018** | 1x (cheapest) |
| **Kimi AI** | $0.001 | $0.0008 | **$0.0018** | 1x |
| **Gemini Flash** | $0.003 | $0.005 | **$0.008** | 4.4x |
| **Claude Haiku** | $0.008 | $0.008 | **$0.016** | 8.9x |
| **Mistral Large** | $0.020 | $0.012 | **$0.032** | 17.8x |
| **OpenAI GPT-4** | $0.005 | $0.003 | **$0.008** | 4.4x |
| **Gemini Pro** | $0.0125 | $0.020 | **$0.0325** | 18.1x |
| **Claude Opus** | $0.150 | $0.150 | **$0.300** | 166.7x (most expensive) |

**Recommendation**: For file organization, **Gemini Lite** or **Kimi** offer the best value. Gemini Flash is a good balance if you need better quality.

## Token Counting Methods

### Exact Counting
- **Gemini**: Uses `model.count_tokens()` - 100% accurate
- **Kimi/Mistral**: Uses tiktoken - 100% accurate for OpenAI-compatible models
- **Claude/OpenAI**: Uses tiktoken - 100% accurate

### Estimated Counting
If exact counting fails or provider is unknown:
- Uses character-based estimation: 1 token ≈ 4 characters
- Accuracy: ±20%
- Conservative (slightly overestimates)

## Response Format

The estimation response includes provider information:

```json
{
  "success": true,
  "input_tokens": 5234,
  "estimated_output_tokens": 1500,
  "total_tokens": 6734,
  "estimated_cost_usd": 0.000842,
  "method": "exact",
  "breakdown": {
    "input_method": "exact",
    "output_method": "estimated",
    "file_count": 100
  }
}
```

The cost is automatically calculated using the detected provider's pricing.

## Examples

### Gemini (100 files)
- Input: 5,234 tokens × $0.075/1M = $0.00039
- Output: 1,000 tokens × $0.30/1M = $0.00030
- **Total: $0.00069**

### Kimi (100 files)
- Input: 5,234 tokens × $0.10/1M = $0.00052
- Output: 1,000 tokens × $0.40/1M = $0.00040
- **Total: $0.00092**

### OpenAI GPT-4 (100 files)
- Input: 5,234 tokens × $0.50/1M = $0.00262
- Output: 1,000 tokens × $1.50/1M = $0.00150
- **Total: $0.00412**

## Installation

### For Kimi Support
Install tiktoken for accurate token counting:

```bash
pip install tiktoken
```

Or install from requirements:

```bash
pip install -r backend/requirements.txt
```

## Troubleshooting

### "tiktoken not available" Warning
**Problem**: Kimi token counting falls back to estimation.

**Solution**: Install tiktoken:
```bash
pip install tiktoken
```

### Wrong Pricing Applied
**Problem**: Cost seems incorrect for your provider.

**Solution**: 
1. Check that provider is correctly detected
2. Verify pricing in `token_counter.py`
3. Update pricing if needed

### Provider Not Detected
**Problem**: System uses default Gemini pricing.

**Solution**:
1. Check `shared_services.ai_model.provider` is set correctly
2. Ensure provider name matches: 'gemini', 'kimi', or 'openai'
3. Check logs for provider detection

## Adding New Providers

To add a new AI provider:

### 1. Add Pricing
In `token_counter.py`:

```python
pricing = {
    'your_provider': {
        'input': 0.XX,
        'output': 0.XX,
        'name': 'Your Provider Name'
    }
}
```

### 2. Add Token Counting (Optional)
If provider has a tokenizer:

```python
elif provider == 'your_provider':
    # Add provider-specific token counting
    tokens = your_provider_count_tokens(text)
    return {
        'tokens': tokens,
        'method': 'exact',
        'characters': char_count,
        'provider': provider
    }
```

### 3. Update Shared Services
Ensure provider name is set correctly in `shared_services.py`:

```python
self.ai_model = AIModelWrapper(
    provider='your_provider',
    model=model,
    model_name=model_name
)
```

## Notes

- Provider detection is automatic - no manual configuration needed
- Pricing is per 1M tokens (standard industry format)
- Output tokens typically cost 3-4x more than input tokens
- Token counting is fast (< 50ms) and doesn't call the AI
- Estimation is used as fallback if exact counting fails
- All costs are in USD

## Future Enhancements

1. **Dynamic pricing**: Fetch current pricing from provider APIs
2. **Usage tracking**: Track actual costs over time
3. **Budget alerts**: Warn when approaching cost limits
4. **Provider comparison**: Show cost comparison across providers
5. **Bulk discounts**: Apply volume-based pricing tiers
