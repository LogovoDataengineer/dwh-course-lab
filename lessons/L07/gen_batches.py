"""Урок 7: три выгрузки источников «Полки» в CSV, как их кладут в папку inbox дважды в сутки.
Данные вымышлены и детерминированы (seed). Запуск: python3 lessons/L07/gen_batches.py
Что специально испорчено (как бывает в жизни):
  - покупатели и заказы приходят повторно, в более новых версиях;
  - email в разном регистре и с пробелами, бывает пустой; город с маленькой буквы;
  - статусы в разном регистре и с пробелами; сумма «n/a»;
  - заказы покупателей, которых ещё нет в выгрузке (сироты): их покупатели приходят в следующей выгрузке;
  - в выгрузке 3 источник начал присылать новый статус «returned», о котором хранилище не знает.
"""
import csv, random
from datetime import datetime, timedelta
from pathlib import Path

R = random.Random(707)
OUT = Path(__file__).resolve().parent / "inbox"
CITIES = ["Москва", "Санкт-Петербург", "Казань", "Екатеринбург", "Новосибирск"]
FIRST = ["Анна", "Иван", "Ольга", "Дмитрий", "Мария", "Алексей", "Екатерина", "Сергей", "Наталья", "Павел", "Юлия", "Андрей"]
LAST_M = ["Смирнов", "Петров", "Кузнецов", "Соколов", "Попов", "Лебедев", "Козлов", "Новиков", "Морозов", "Волков"]
customers, orders = {}, {}


def customer(cid, at):
    first = FIRST[cid % len(FIRST)]
    last = LAST_M[(cid * 7) % len(LAST_M)] + ("а" if first[-1] == "а" or first[-1] == "я" else "")
    email = f"user{cid}@example.ru"
    if cid % 17 == 0: email = email.upper()
    if cid % 23 == 0: email = " " + email + " "
    if cid % 41 == 0: email = ""
    city = CITIES[cid % 5]
    if cid % 13 == 0: city = city.lower()
    return [cid, f"{first} {last}", email, city, at.strftime("%Y-%m-%d %H:%M:%S")]


def write(n, cust_rows, order_rows):
    d = OUT / f"batch_{n:03d}"; d.mkdir(parents=True, exist_ok=True)
    with open(d / "customers.csv", "w", newline="") as f:
        w = csv.writer(f); w.writerow(["customer_id", "full_name", "email", "city", "updated_at"]); w.writerows(cust_rows)
    with open(d / "orders.csv", "w", newline="") as f:
        w = csv.writer(f); w.writerow(["order_id", "customer_id", "created_at", "status", "amount"]); w.writerows(order_rows)


start = datetime(2026, 3, 1, 8, 0)
for n in (1, 2, 3):
    at = start + timedelta(hours=12 * (n - 1))
    cust_rows, order_rows = [], []
    # новые покупатели выгрузки; покупатели с номером, кратным 50, «опаздывают» на одну выгрузку
    for cid in range(1 + (n - 1) * 200, 1 + n * 200):
        if cid % 50 == 0 and n < 3:
            continue
        cust_rows.append(customer(cid, at - timedelta(minutes=R.randint(1, 600))))
    if n > 1:   # опоздавшие из прошлой выгрузки и обновлённые версии старых покупателей (переезд)
        cust_rows += [customer(cid, at - timedelta(minutes=5)) for cid in range(50, 1 + (n - 1) * 200, 50)]
        for cid in R.sample(range(1, 1 + (n - 1) * 200), 15):
            row = customer(cid, at - timedelta(minutes=R.randint(1, 300)))
            row[3] = R.choice(CITIES); cust_rows.append(row)
    # новые заказы и новые версии старых заказов (смена статуса)
    for oid in range(1000 * n + 1, 1000 * n + 1001):
        cid = R.randint(1, n * 200)
        created = at - timedelta(minutes=R.randint(1, 700))
        status = R.choice(["created", "paid", "paid", "delivered", "cancelled"])
        if oid % 37 == 0: status = " " + status.upper() + " "
        if n == 3 and oid % 25 == 0: status = "returned"
        amount = f"{R.randint(30, 1500) * 10}.00" if oid % 3 else str(R.randint(30, 1500) * 10)
        if oid % 97 == 0: amount = "n/a"
        orders[oid] = [oid, cid, created.strftime("%Y-%m-%d %H:%M:%S"), status, amount]
        order_rows.append(orders[oid])
    if n > 1:
        for oid in R.sample([o for o in orders if o <= 1000 * (n - 1) + 1000 and o < 1000 * n], 300):
            row = list(orders[oid]); row[3] = "delivered" if row[3].strip().lower() == "paid" else row[3]
            order_rows.append(row)
    R.shuffle(order_rows)
    write(n, cust_rows, order_rows)
    print(f"batch_{n:03d}: покупателей {len(cust_rows)}, строк заказов {len(order_rows)}")
