# AI System Improvements - TODO

## 1. Better Error Handling ✅ IMPLEMENTED

**Status**: Complete - Detailed error handling implemented in backend

The system now returns structured error responses with specific error types:
- Authentication errors (401)
- Insufficient credits (402)
- Rate limits (429)
- Model not found (404)
- Timeouts (504)
- Server errors (500)

See [CONTENT_ANALYSIS_IMPLEMENTATION.md](CONTENT_ANALYSIS_IMPLEMENTATION.md) for details on error handling.

---

## 2. Context vs Prompt Clarification ✅

### Important Clarification
**There is NO separate "context" that's cheaper than "prompt"!**

In AI APIs:
- **Input tokens** = Everything you send (prompt + context + files + rules)
- **Output tokens** = Everything AI returns

Both "context" and "prompt" are input tokens and cost the same.

### What You're Seeing in Logs
```
Context: 340 chars
Prompt length: 8265 chars
```

- **Context (340 chars)**: Just the AI context string (destinations + drives)
- **Prompt (8265 chars)**: FULL prompt including context, rules, files, examples

The "context" is a PART of the prompt, not separate.

### Token Cost
- Input: $0.10 per 1M tokens (Kimi)
- Output: $0.40 per 1M tokens (Kimi)

**Output costs 4x more than input!**

So we should:
- ✅ Keep prompts concise (already optimized with indices)
- ✅ Minimize output (already using indexed format)
- ❌ Don't worry about "context" vs "prompt" - they're the same cost

---

## 3. AI Parameters (Temperature, etc.) ✅ IMPLEMENTED

**Status**: Complete - Temperature and max_tokens parameters implemented

Current configuration:
- **Temperature**: 0.3 (consistent results for file organization)
- **Max_tokens**: 500 (prevents runaway costs)
- **Finish_reason logging**: Tracks if responses are truncated

### Available Parameters

#### Temperature (0.0 - 1.0)
Controls randomness/creativity:
- **0.0**: Deterministic, same output every time
- **0.3**: Slightly varied, good for structured tasks
- **0.7**: Balanced (default for most tasks)
- **1.0**: Very creative, unpredictable

**For file organization**: 0.3-0.5 is ideal (consistent but flexible)

#### Top_p (0.0 - 1.0)
Nucleus sampling (alternative to temperature):
- **0.1**: Very focused
- **0.9**: More diverse
- Usually use temperature OR top_p, not both

#### Max_tokens
Limits response length:
- Prevents runaway costs
- For our indexed format: ~500 tokens should be enough for 100 files

#### Presence_penalty / Frequency_penalty
Reduces repetition:
- **0.0**: No penalty
- **2.0**: Strong penalty
- Useful if AI repeats same folder names

### Confidence/Certainty Data

Most AI APIs don't return explicit "confidence scores", but some provide:

#### 1. Logprobs (Token Probabilities)
Shows probability of each token:
```json
{
  "choices": [{
    "logprobs": {
      "tokens": ["move", "Documents"],
      "token_logprobs": [-0.1, -0.3]
    }
  }]
}
```
Higher (closer to 0) = more confident

#### 2. Finish_reason
Why AI stopped:
- `"stop"`: Completed naturally (good)
- `"length"`: Hit max_tokens (might be truncated)
- `"content_filter"`: Blocked by safety filter

#### 3. Multiple Choices
Request multiple responses and compare:
```python
response = client.chat.completions.create(
    model="kimi-k2-0905-preview",
    messages=[...],
    n=3  # Get 3 different responses
)
```
If all 3 agree → high confidence

### Implementation Example

```python
# In AIModelWrapper.generate_content()
response = self.model.chat.completions.create(
    model=self.model_name,
    messages=[{"role": "user", "content": prompt}],
    temperature=0.3,        # Low for consistency
    max_tokens=500,         # Limit response length
    top_p=0.9,             # Nucleus sampling
    presence_penalty=0.1,   # Slight penalty for repetition
    # logprobs=True,        # Get confidence scores (if supported)
    # n=1                   # Number of responses
)
```

---

## 4. Optimization Opportunities

### Current Prompt Structure (8265 chars)
```
SOURCE FOLDERS: [...]           ~100 chars
DESTINATION FOLDERS: [...]      ~200 chars
ACTION TYPES: [...]             ~40 chars
AI CONTEXT: [...]               ~340 chars
METADATA KEYS: [...]            ~150 chars
GRANULARITY RULES: [...]        ~300 chars
ARCHIVE HANDLING: [...]         ~400 chars
FILES: [...]                    ~6000 chars (22 files)
RESPONSE FORMAT: [...]          ~700 chars
```

### Optimization Ideas

#### A. Reduce Response Format Examples
Current: ~700 chars of examples
Could reduce to: ~200 chars (just show format, not examples)
**Savings**: ~500 chars (~125 tokens)

#### B. Shorten Rule Descriptions
Current rules are verbose for clarity
Could use more compact notation
**Savings**: ~200 chars (~50 tokens)

#### C. Remove Redundant Instructions
Some instructions are repeated
**Savings**: ~100 chars (~25 tokens)

**Total potential savings**: ~200 tokens per request

**Cost impact**: 
- 100K requests/month
- 200 tokens × 100K = 20M tokens saved
- 20M × $0.10/1M = **$2 saved/month**

Not huge, but every bit helps!

---

## 5. Implementation Status

### ✅ Completed
1. **Better error handling** - Detailed error responses with user-friendly messages
2. **Temperature parameter** - Set to 0.3 for consistent file organization
3. **Max_tokens limit** - Set to 500 to prevent runaway costs
4. **Finish_reason logging** - Tracks response completion status
5. **Error type detection** - Parses specific error codes from AI providers

### 🔄 In Progress
6. **Prompt optimization** - Ongoing refinement of prompt structure
7. **Token estimation** - Accurate cost preview before AI calls

### 📋 Future Enhancements
8. **Logprobs support** - Track confidence scores if provider supports it
9. **Multiple responses** - Compare multiple AI responses for critical operations
10. **Adaptive temperature** - Adjust based on operation type

---

## 6. Questions Answered

### Q: "Why is context only 340 chars but prompt 8265 chars?"
**A**: Context (340 chars) is just the destinations/drives info. The full prompt (8265 chars) includes context + rules + files + examples. Both are input tokens and cost the same.

### Q: "Can we move things to context to save money?"
**A**: No, because "context" IS part of the prompt. They're both input tokens. The only way to save money is to reduce the total prompt size or reduce output tokens.

### Q: "Is prompt more expensive than context?"
**A**: No, they're the same cost (both input tokens). Output tokens are 4x more expensive than input.

### Q: "Can we control AI creativity?"
**A**: Yes! Use `temperature` parameter:
- 0.0 = deterministic
- 0.3 = slightly varied (recommended for file organization)
- 0.7 = balanced
- 1.0 = very creative

### Q: "Can we get confidence scores?"
**A**: Some APIs support `logprobs` which shows token probabilities. Kimi might support this - need to check their docs. Otherwise, we can request multiple responses and compare them.

---

## Next Steps

1. Implement better error handling with specific error types
2. Add temperature=0.3 for more consistent results
3. Add max_tokens=500 to limit response length
4. Test if Kimi supports logprobs for confidence scores
5. Optimize prompt by removing verbose examples

Would you like me to implement any of these now?
