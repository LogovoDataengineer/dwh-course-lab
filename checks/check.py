#!/usr/bin/env python3
"""make check-NN: проверяет практику урока NN на настоящем стенде.

Каждая проверка — функция lesson_NN() в модуле checks/lNN.py: она вызывает ok(...) для каждого пункта.
Запросы к сервисам идут через docker compose exec, поэтому проверка видит ровно то, что сделали вы.
"""
import importlib.util
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
results = []


def run(service, *cmd, stdin=None):
    r = subprocess.run(["docker", "compose", "exec", "-T", service, *cmd], cwd=ROOT, input=stdin,
                       capture_output=True, text=True)
    if r.returncode:
        raise RuntimeError(r.stderr.strip() or r.stdout.strip())
    return r.stdout.strip()


def pg(sql, db="shop"):
    """Результат запроса к PostgreSQL: список строк, поля через |."""
    out = run("postgres", "psql", "-U", "dwh", "-d", db, "-AtX", "-v", "ON_ERROR_STOP=1", "-c", sql)
    return [line.split("|") for line in out.splitlines() if line]


def ch(sql):
    """Результат запроса к ClickHouse: список строк, поля через табуляцию."""
    out = run("clickhouse", "clickhouse-client", "--user", "dwh", "--password", "dwh", "-q", sql)
    return [line.split("\t") for line in out.splitlines() if line]


def gp(sql, db="shop"):
    out = run("greenplum", "su", "-", "gpadmin", "-c", f"psql -d {db} -AtX -v ON_ERROR_STOP=1", stdin=sql)
    return [line.split("|") for line in out.splitlines() if line]


def ok(condition, title, hint=""):
    results.append((bool(condition), title, hint))


def safe(fn, *args, default=None):
    """Запрос, который может упасть, если ученик ещё не создал таблицу: тогда вернётся default."""
    try:
        return fn(*args)
    except Exception:
        return default


def main():
    n = f"{int(sys.argv[1]):02d}"
    path = ROOT / "checks" / f"l{n}.py"
    if not path.exists():
        print(f"Для урока {n} автоматической проверки нет: практика проверяется по выводу команд в уроке.")
        return 0
    spec = importlib.util.spec_from_file_location(f"l{n}", path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["check"] = sys.modules[__name__]
    spec.loader.exec_module(mod)
    try:
        mod.check()
    except RuntimeError as e:
        print(f"Не удалось обратиться к стенду: {e}\nПоднимите стенд урока: make lesson-{n}")
        return 2
    print(f"Урок {n}: проверка практики на стенде\n")
    for good, title, hint in results:
        print(f"  {'✔' if good else '✘'} {title}")
        if not good and hint:
            print(f"      → {hint}")
    passed = sum(1 for r in results if r[0])
    print(f"\nВыполнено {passed} из {len(results)}." + (" Практика урока сделана." if passed == len(results) else ""))
    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
