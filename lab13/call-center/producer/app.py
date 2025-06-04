from fastapi import FastAPI, Request
from pydantic import BaseModel
import pika
import os
import json

app = FastAPI()

class ContactRequest(BaseModel):
    clientID: str
    department: str  # 'mortgage', 'cash', 'business'

RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")

@app.post("/contact")
async def contact(request: ContactRequest):
    connection = pika.BlockingConnection(pika.ConnectionParameters(host=RABBITMQ_HOST))
    channel = connection.channel()
    
    queue_name = f"{request.department}_queue"
    channel.queue_declare(queue=queue_name, durable=True)

    message = json.dumps({"clientID": request.clientID})
    channel.basic_publish(exchange="", routing_key=queue_name, body=message)
    connection.close()

    return {"status": "queued", "department": request.department}
