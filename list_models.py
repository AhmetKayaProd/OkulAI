import requests

API_KEY = "AIzaSyDIJ2ugrWmZCjhHH43JG6ll0JbDwGnbup4"

print("🔍 Listing available Gemini models...")
print("=" * 60)

response = requests.get(
    f"https://generativelanguage.googleapis.com/v1/models?key={API_KEY}"
)

if response.status_code == 200:
    data = response.json()
    models = data.get('models', [])
    
    print(f"\n✅ Found {len(models)} models:\n")
    
    for model in models:
        name = model.get('name', '')
        supported = model.get('supportedGenerationMethods', [])
        if 'generateContent' in supported:
            print(f"  ✓ {name}")
            print(f"    Methods: {', '.join(supported)}")
    
else:
    print(f"❌ Error: {response.status_code}")
    print(response.text)
