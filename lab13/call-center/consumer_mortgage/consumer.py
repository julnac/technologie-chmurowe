import pika
import json
import time

def callback(ch, method, properties, body):
    message = json.loads(body)
    print("[MORTGAGE] Received:", message)

connection = pika.BlockingConnection(pika.ConnectionParameters(host="rabbitmq"))
channel = connection.channel()

channel.queue_declare(queue="mortgage_queue", durable=True)
channel.basic_consume(queue="mortgage_queue", on_message_callback=callback, auto_ack=True)

print("[MORTGAGE] Waiting for messages...")
channel.start_consuming()
