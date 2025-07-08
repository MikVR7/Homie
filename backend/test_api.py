#!/usr/bin/env python3
import os
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()

api_key = os.getenv('GEMINI_API_KEY')
print(f"API key loaded: {api_key[:8]}..." if api_key else "No API key found")

try:
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-1.5-flash')
    response = model.generate_content("Hello, can you respond with just 'API working!'?")
    print(f"✅ API Response: {response.text}")
except Exception as e:
    print(f"❌ API Error: {e}")
