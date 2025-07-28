import requests
import json

# URL de la API
base_url = "https://apimapeo-927498545444.us-central1.run.app"

# Simular el request que está fallando
def test_plantas_error():
    print("🔍 Debuggeando error de plantas...")
    
    # Simular el request que está enviando el frontend
    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'  # Token simulado
    }
    
    # Datos que está enviando el frontend según la imagen
    planta_data = {
        "id_hilera": 1,
        "planta": 1,
        "ubicacion": "-33.7836829,-70.7396239"
    }
    
    print(f"📤 Datos enviados: {json.dumps(planta_data, indent=2)}")
    
    try:
        response = requests.post(f"{base_url}/api/plantas/", json=planta_data, headers=headers)
        print(f"📥 Status: {response.status_code}")
        print(f"📥 Response: {response.text}")
        
        if response.status_code == 500:
            print("❌ Error 500 detectado")
            # Intentar obtener más detalles del error
            try:
                error_data = response.json()
                print(f"🔍 Error details: {json.dumps(error_data, indent=2)}")
            except:
                print("🔍 No se pudo parsear el error como JSON")
                
    except Exception as e:
        print(f"❌ Exception: {str(e)}")

def test_database_structure():
    """Probar la estructura de la base de datos"""
    print("\n🔍 Probando estructura de BD...")
    
    try:
        response = requests.get(f"{base_url}/api/test-db")
        print(f"📥 Status: {response.status_code}")
        print(f"📥 Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ BD conectada: {data.get('database')}")
            print(f"📊 Tablas disponibles: {data.get('tables', [])[:5]}")
            
    except Exception as e:
        print(f"❌ Exception: {str(e)}")

if __name__ == "__main__":
    test_database_structure()
    test_plantas_error() 