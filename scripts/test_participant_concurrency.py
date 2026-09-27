#!/usr/bin/env python3
"""Real multi-connection allocation test in an isolated, disposable PostgreSQL container."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import subprocess
import time


def main():
    root = Path(__file__).resolve().parent.parent
    container = subprocess.check_output([
        'docker', 'run', '--rm', '-d', '--network', 'none',
        '-e', 'POSTGRES_HOST_AUTH_METHOD=trust', 'postgres:17',
    ], text=True).strip()

    def sql(statement):
        return subprocess.check_output(['docker', 'exec', '-i', container, 'psql', '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-Atq'], input=statement, text=True).strip()

    try:
        for _ in range(60):
            ready = subprocess.run(['docker', 'exec', container, 'pg_isready', '-U', 'postgres'], capture_output=True)
            if ready.returncode == 0:
                break
            time.sleep(.5)
        else:
            raise RuntimeError('PostgreSQL did not start')
        sql("""create role anon; create role authenticated; create role service_role bypassrls;
            create schema auth; create table auth.users(id uuid primary key);
            create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
            grant usage on schema auth,public to authenticated,anon,service_role;
            insert into auth.users values('00000000-0000-4000-8000-000000000001');""")
        for migration in sorted((root / 'supabase/migrations').glob('*.sql')):
            sql(migration.read_text())
        study = sql("insert into public.studies(name,created_by) values('Concurrent test','00000000-0000-4000-8000-000000000001') returning id;")
        statement = f"begin; insert into public.participants(study_id,sex,dominant_hand) values('{study}','not_reported','right') returning display_number; select pg_sleep(0.05); commit;"
        with ThreadPoolExecutor(max_workers=8) as pool:
            numbers = list(pool.map(lambda _: int(sql(statement)), range(24)))
        assert sorted(numbers) == list(range(1,25)), numbers
        sql(f"begin; insert into public.participants(study_id,sex,dominant_hand) values('{study}','not_reported','right'); rollback;")
        assert sql(f"insert into public.participants(study_id,sex,dominant_hand) values('{study}','not_reported','right') returning display_number;") == '25'
        print('PASS: fresh PostgreSQL migrations; 24 allocations through 8 concurrent connections; rollback safety.')
    finally:
        subprocess.run(['docker', 'rm', '-f', container], check=True, stdout=subprocess.DEVNULL)


if __name__ == '__main__':
    main()
