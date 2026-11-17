"""Урок 18: генератор кликов сайта. Печатает сообщения «ключ|json» с заданной скоростью; их читает kafka-console-producer.
Ключ — user_id, поэтому клики одного пользователя попадают в одну партицию. 3% событий опаздывают: мобильное
приложение было без сети, и event_time у них на 30 секунд — 4 минуты раньше момента отправки."""
import json, random, sys, time, uuid
from datetime import datetime, timedelta, timezone

seconds, rate = int(sys.argv[1]), int(sys.argv[2])
pages = ["/", "/catalog", "/catalog/books", "/catalog/electronics", "/product", "/cart", "/checkout"]
end = time.time() + seconds
sent = 0
while time.time() < end:
    tick = time.time()
    for _ in range(rate // 10):
        now = datetime.now(timezone.utc)
        late = random.random() < 0.03
        ev_time = now - timedelta(seconds=random.uniform(30, 240)) if late else now
        user = random.randint(1, 5000)
        ev = {"event_id": str(uuid.uuid4()), "user_id": user, "page": random.choice(pages),
              "event_time": ev_time.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]}
        print(f"{user}|{json.dumps(ev)}")
        sent += 1
    sys.stdout.flush()
    time.sleep(max(0, 0.1 - (time.time() - tick)))
print(f"отправлено {sent}", file=sys.stderr)
