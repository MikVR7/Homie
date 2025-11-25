# AI Provider Configuration

The backend supports multiple AI providers for file organization. You can easily switch between them using environment variables.

## Supported Providers

### 1. Google Gemini (Default)
- **Provider ID:** `gemini`
- **Models:** `gemini-flash-latest`, `gemini-1.5-flash`, `gemini-1.5-pro`, etc.
- **API Key:** Get from [Google AI Studio](https://makersuite.google.com/app/apikey)

### 2. Kimi K2 (Moonshot AI)
- **Provider ID:** `kimi`
- **Models:** `moonshot-v1-8k`, `moonshot-v1-32k`, `moonshot-v1-128k`
- **API Key:** Get from [Moonshot AI](https://platform.moonshot.cn/)
- **API Base:** `https://api.moonshot.cn/v1`

## Configuration

### Using Google Gemini (Default)

Add to your `.env` file:

```bash
# AI Provider (optional, defaults to 'gemini')
AI_PROVIDER=gemini

# Gemini API Key (required)
GEMINI_API_KEY=your_gemini_api_key_here

# Gemini Model (optional, defaults to 'gemini-flash-latest')
GEMINI_MODEL=gemini-flash-latest
```

### Using Kimi K2

Add to your `.env` file:

```bash
# AI Provider
AI_PROVIDER=kimi

# Kimi API Key (required)
KIMI_API_KEY=your_kimi_api_key_here

# Kimi Model (optional, defaults to 'moonshot-v1-8k')
KIMI_MODEL=moonshot-v1-8k

# Kimi API Base URL (optional, defaults to 'https://api.moonshot.cn/v1')
KIMI_BASE_URL=https://api.moonshot.cn/v1
```

## Switching Providers

To switch between providers:

1. **Edit `.env` file** in the project root
2. **Change `AI_PROVIDER`** to either `gemini` or `kimi`
3. **Ensure the corresponding API key** is set
4. **Restart the backend**

```bash
# Stop backend
pkill -f "python.*main.py"

# Start backend
bash start_backend.sh
```

## Model Selection

### Gemini Models

Available models (as of 2024):
- `gemini-flash-latest` - Fast, cost-effective (recommended)
- `gemini-1.5-flash` - Specific version of Flash
- `gemini-1.5-pro` - More capable, slower, more expensive
- `gemini-pro` - Previous generation

### Kimi Models

Available models:
- `moonshot-v1-8k` - 8K context window (recommended for file organization)
- `moonshot-v1-32k` - 32K context window
- `moonshot-v1-128k` - 128K context window (for large batches)

## Requirements

### For Gemini
```bash
pip install google-generativeai
```

### For Kimi
```bash
pip install openai
```

Both are included in `backend/requirements.txt`.

## Implementation Details

The backend uses a unified `AIModelWrapper` class that provides a consistent interface regardless of the provider:

```python
# Both providers use the same interface
response = ai_model.generate_content(prompt)
text = response.text
```

This means:
- ✅ No code changes needed to switch providers
- ✅ All features work with both providers
- ✅ Easy to add new providers in the future

## Troubleshooting

### "AI service not initialized"
- Check that the API key is set in `.env`
- Verify the API key is valid
- Ensure the provider name is correct (`gemini` or `kimi`)

### "openai package not installed" (Kimi only)
```bash
pip install openai
```

### "Invalid API key"
- Verify the API key in your provider's dashboard
- Check for extra spaces or quotes in `.env`
- Ensure you're using the correct key for the selected provider

## Cost Comparison

### Gemini
- **Free tier:** 60 requests per minute
- **Paid:** Very affordable, pay-per-use
- **Best for:** Most users, high volume

### Kimi
- **Pricing:** Check [Moonshot AI pricing](https://platform.moonshot.cn/pricing)
- **Best for:** Chinese users, specific requirements

## Example .env File

```bash
# ============================================
# AI Configuration
# ============================================

# Choose provider: 'gemini' or 'kimi'
AI_PROVIDER=gemini

# Gemini Configuration
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
GEMINI_MODEL=gemini-flash-latest

# Kimi Configuration (uncomment to use)
# KIMI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# KIMI_MODEL=moonshot-v1-8k
# KIMI_BASE_URL=https://api.moonshot.cn/v1

# ============================================
# Other Configuration
# ============================================
HOST=0.0.0.0
PORT=8000
DEBUG=false
```

## Testing

Test your AI connection:

```bash
curl http://localhost:8000/api/test-ai
```

Expected response:
```json
{
  "success": true,
  "message": "AI connection test successful",
  "provider": "gemini",
  "model": "gemini-flash-latest",
  "response": "AI test successful"
}
```
