import pika
import json
import time

def callback(ch, method, properties, body):
    message = json.loads(body)
    print("[BUSINESS] Received:", message)

connection = pika.BlockingConnection(pika.ConnectionParameters(host="rabbitmq"))
channel = connection.channel()

channel.queue_declare(queue="business_queue", durable=True)
channel.basic_consume(queue="business_queue", on_message_callback=callback, auto_ack=True)

print("[BUSINESS] Waiting for messages...")
channel.start_consuming()
