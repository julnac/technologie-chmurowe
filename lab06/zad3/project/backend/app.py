from flask import Flask
import psycopg2
import os

app = Flask(__name__)

@app.route('/health')
def health():
    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST", "database"),
            user=os.getenv("DB_USER", "user"),
            password=os.getenv("DB_PASSWORD", "password"),
            dbname=os.getenv("DB_NAME", "mydb")
        )
        conn.close()
        return "Backend OK + DB OK", 200
    except Exception as e:
        return f"Backend Error: {str(e)}", 500

@app.route('/')
def hello():
    return "Hello from backend!", 200
