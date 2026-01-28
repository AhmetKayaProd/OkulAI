import requests
import json

# Test Gemini API with the embedded key
API_KEY = "AIzaSyDIJ2ugrWmZCjhHH43JG6ll0JbDwGnbup4"
API_URL = f"https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key={API_KEY}"

# Test program text
test_program = """
Pazartesi
09:00-10:00 Matematik - Toplama çıkarma
10:00-11:00 Türkçe - Okuma
11:00-12:00 Beden Eğitimi

Salı
09:00-10:00 Fen Bilgisi - Bitkiler
10:00-11:00 Sosyal Bilgiler - Aile
"""

# Build prompt (same as in app)
prompt = f"""
Bir Kreş/Anaokulu için haftalık program metnini JSON formatına çevir.

Program Metni:
{test_program}

Çıktı formatı (JSON):
{{
  "blocks": [
    {{
      "dayOfWeek": 1,
      "startTime": "09:00",
      "endTime": "10:00",
      "label": "Matematik",
      "notes": "Toplama çıkarma"
    }}
  ]
}}

KURALLAR:
- Sadece JSON döndür, açıklama ekleme
- Saatleri HH:mm formatında yaz
- dayOfWeek: 1=Pazartesi, 7=Pazar
- dayOfWeek kullan
- label kısa ve öz olsun
"""

print("🧪 Testing Gemini API Program Parsing...")
print("=" * 60)

# Make API call
try:
    response = requests.post(
        API_URL,
        headers={"Content-Type": "application/json"},
        json={
            "contents": [{
                "parts": [{"text": prompt}]
            }],
            "generationConfig": {
                "temperature": 0.2,
                "maxOutputTokens": 2048,
            }
        },
        timeout=30
    )
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        text = data['candidates'][0]['content']['parts'][0]['text']
        
        print("\n✅ API Call Successful!")
        print("\n📝 Raw Response:")
        print(text)
        
        # Extract JSON
        cleaned = text.strip()
        if cleaned.startswith('```json'):
            cleaned = cleaned[7:]
        elif cleaned.startswith('```'):
            cleaned = cleaned[3:]
        if cleaned.endswith('```'):
            cleaned = cleaned[:-3]
        cleaned = cleaned.strip()
        
        print("\n🔍 Parsed JSON:")
        parsed = json.loads(cleaned)
        print(json.dumps(parsed, indent=2, ensure_ascii=False))
        
        blocks = parsed.get('blocks', [])
        print(f"\n📊 Result: {len(blocks)} blocks parsed")
        
        for i, block in enumerate(blocks, 1):
            day_names = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']
            day = day_names[block['dayOfWeek'] - 1]
            print(f"  {i}. {day} {block['startTime']}-{block['endTime']}: {block['label']}")
            if block.get('notes'):
                print(f"     ({block['notes']})")
        
        print("\n✅ TEST PASSED - API key is valid and parsing works!")
        
    else:
        print(f"\n❌ API Error: {response.status_code}")
        print(response.text)
        
except Exception as e:
    print(f"\n❌ Error: {e}")
    
print("\n" + "=" * 60)
