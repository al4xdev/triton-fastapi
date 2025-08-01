import requests
import concurrent.futures
import time
import json

NUM_REQUESTS = 500  # Número total de requisições a serem feitas

base_url = "http://35.202.207.194/inference_server/v1/chat/completions"
headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer aU2KI22aKAkUdIQjQkEE+adTIC32AVH+E4rLXpnSBM0="
}

original_messages = [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "I am planning a 10-day trip to Japan. I want to visit the cities Tokyo, Kyoto, and Osaka. For each city, what are the three must-see tourist spots, and what is the best way to travel between them considering a moderate budget?"}
]

city_combinations = [
    "Tokyo, Kyoto, and Osaka",
    "Tokyo, Osaka, and Kyoto",
    "Kyoto, Tokyo, and Osaka",
    "Osaka, Tokyo, and Kyoto",
    "Osaka, Kyoto, and Tokyo",
    "Kyoto, Osaka, and Tokyo"
]

message_variations = []
for city_combo in city_combinations:
    modified_user_content = original_messages[1]["content"].replace(
        "Tokyo, Kyoto, and Osaka", city_combo
    )
    message_variations.append([
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": modified_user_content}
    ])

while len(message_variations) < NUM_REQUESTS:
    modified_user_content = original_messages[1]["content"].replace(
        "three must-see tourist spots", "one must-see tourist spot"
    )
    message_variations.append([
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": modified_user_content}
    ])

def send_request(messages):
    start_time = time.time()
    data = {
        "model": "GLM-4.1",
        "messages": messages,
        "temperature": 0.2,
        "max_tokens": 2048  # limit to avoid long loops / timeouts
    }
    try:
        response = requests.post(base_url, headers=headers, json=data, timeout=200)
        latency = time.time() - start_time
        return latency, response.status_code
    except Exception as e:
        print(f"Request error: {e}")
        return float('inf'), 0  # infinite latency and status 0 on error

latencies = []
status_codes = []

with concurrent.futures.ThreadPoolExecutor(max_workers=NUM_REQUESTS) as executor:
    futures = [executor.submit(send_request, message_variations[i % len(message_variations)]) for i in range(NUM_REQUESTS)]
    for future in concurrent.futures.as_completed(futures):
        latency, status_code = future.result()
        latencies.append(latency)
        status_codes.append(status_code)

successful_latencies = [lat for lat, status in zip(latencies, status_codes) if status == 200]

total_requests = len(status_codes)
success_count = status_codes.count(200)
success_rate = (success_count / total_requests) * 100 if total_requests > 0 else 0

total_time = sum(successful_latencies)
average_latency = total_time / len(successful_latencies) if successful_latencies else 0
max_latency = max(successful_latencies) if successful_latencies else 0
min_latency = min(successful_latencies) if successful_latencies else 0
percentile_90 = sorted(successful_latencies)[int(0.9 * len(successful_latencies))] if successful_latencies else 0

print(f"Total Requests: {total_requests}")
print(f"Success (200): {success_count}")
print(f"Success Rate: {success_rate:.2f}%")
print(f"Average Latency: {average_latency:.2f} seconds")
print(f"Max Latency: {max_latency:.2f} seconds")
print(f"Min Latency: {min_latency:.2f} seconds")
print(f"90th Percentile Latency: {percentile_90:.2f} seconds")
