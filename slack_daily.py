import requests
from datetime import datetime, timedelta
import os

WEBHOOK_URL = os.environ["SLACK_WEBHOOK"]

def send_message(text):
    payload = {"text": text}
    requests.post(WEBHOOK_URL, json=payload)

today = datetime.today()

days_ahead = 7 - today.weekday()
next_monday = today + timedelta(days=days_ahead)

weekdays = ["월", "화", "수", "목", "금"]

for i, day_name in enumerate(weekdays):
    target_date = next_monday + timedelta(days=i)
    date_str = target_date.strftime("%m%d")

    send_message(f"{date_str}({day_name}) 데일리 공유")