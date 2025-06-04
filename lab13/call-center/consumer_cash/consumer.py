import pika
import json
import time

def callback(ch, method, properties, body):
    message = json.loads(body)
    print("[CASH] Received:", message)

connection = pika.BlockingConnection(pika.ConnectionParameters(host="rabbitmq"))
channel = connection.channel()

channel.queue_declare(queue="cash_queue", durable=True)
channel.basic_consume(queue="cash_queue", on_message_callback=callback, auto_ack=True)

print("[CASH] Waiting for messages...")
channel.start_consuming()
