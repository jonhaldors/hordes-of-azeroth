import argparse
import ctypes
import functools
import os
import re
import signal
import socket
import stat
import subprocess
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SERVER = ROOT / 'server'
RUN = SERVER / 'run'
LOGS = SERVER / 'logs'
DATABASE = SERVER / 'mariadb-data'
SOCKET = RUN / 'mariadb.sock'
PORT = 13306


@functools.lru_cache()
def mariadb_root():
    return Path(os.environ.get('MARIADB_ROOT') or subprocess.check_output(
        ['brew', '--prefix', 'mariadb@11.4'], text=True).strip())


def query(sql, database=None, password='root'):
    command = [str(mariadb_root() / 'bin/mariadb'), '--no-defaults',
               '--skip-ssl', '--protocol=SOCKET', f'--socket={SOCKET}', '-u', 'root', '-N', '-B']
    if database:
        command.append(database)
    command += ['-e', sql]
    return subprocess.check_output(command, env={**os.environ, 'MYSQL_PWD': password}, text=True).strip()


def import_sql(path, database=None):
    command = [str(mariadb_root() / 'bin/mariadb'), '--no-defaults',
               '--skip-ssl', '--protocol=SOCKET', f'--socket={SOCKET}', '-u', 'root']
    if database:
        command.append(database)
    with path.open('rb') as source:
        subprocess.run(command, stdin=source, env={**os.environ, 'MYSQL_PWD': 'root'}, check=True)


def port_open(port):
    try:
        with socket.create_connection(('127.0.0.1', port), timeout=0.2):
            return True
    except OSError:
        return False


def wait_for(process, ready, name, limit=180):
    deadline = time.monotonic() + limit
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError(f'{name} exited with {process.returncode}; inspect {LOGS}')
        if ready():
            return
        time.sleep(0.5)
    raise RuntimeError(f'{name} did not become ready; inspect {LOGS}')


def write_configs():
    LOGS.mkdir(parents=True, exist_ok=True)
    for name in ('mangosd', 'realmd'):
        lines = (RUN / f'{name}.conf.dist').read_text().splitlines()
        settings = {}
        for line in (ROOT / f'config/{name}.overrides.conf').read_text().splitlines():
            match = re.match(r'^\s*([\w.]+)\s*=', line)
            if match:
                settings[match[1]] = line.strip()
        settings['WaitAtStartupError'] = 'WaitAtStartupError = 0'
        settings['ShowProgressBars'] = 'ShowProgressBars = 0'
        for index, line in enumerate(lines):
            match = re.match(r'^\s*([\w.]+)\s*=', line)
            if match:
                key = match[1]
                lines[index] = settings.pop(key, line)
                if 'Database.Info' in key or key == 'LoginDatabaseInfo':
                    lines[index] = re.sub(r';\d+;', f';{PORT};', lines[index], count=1)
        lines += list(settings.values())
        (RUN / f'{name}.conf').write_text('\n'.join(lines) + '\n')
    launcher = ROOT / 'HordesOfAzeroth'
    launcher.mkdir(exist_ok=True)
    (launcher / 'database-port.txt').write_text(str(PORT))


def ensure_database_login():
    try:
        location = query('SELECT @@datadir')
    except subprocess.CalledProcessError:
        if (DATABASE / '.hoa-bootstrap-ready').exists():
            raise
        location = query('SELECT @@datadir', password='')
        if Path(location).resolve() != DATABASE.resolve():
            raise RuntimeError('MariaDB is using an unexpected data directory.')
        query("ALTER USER 'root'@'localhost' IDENTIFIED BY 'root'", password='')
    if Path(location).resolve() != DATABASE.resolve():
        raise RuntimeError('MariaDB is using an unexpected data directory.')
    (DATABASE / '.hoa-bootstrap-ready').write_text('1\n')


def start_database():
    if SOCKET.exists():
        try:
            ensure_database_login()
            return
        except subprocess.CalledProcessError:
            pass
        raise RuntimeError(f'Existing database socket could not be verified: {SOCKET}')
    if port_open(PORT):
        raise RuntimeError(f'Port {PORT} is already in use by another service.')
    base = mariadb_root()
    LOGS.mkdir(parents=True, exist_ok=True)
    if not (DATABASE / 'mysql').is_dir():
        DATABASE.mkdir(parents=True, exist_ok=True)
        with (LOGS / 'database-init.log').open('w') as output:
            subprocess.run([str(base / 'bin/mariadb-install-db'), '--no-defaults',
                            f'--basedir={base}', f'--datadir={DATABASE}',
                            '--auth-root-authentication-method=normal', '--skip-test-db'],
                           stdout=output, stderr=subprocess.STDOUT, check=True)
    with (LOGS / 'database-console.log').open('a') as output:
        process = subprocess.Popen([str(base / 'bin/mariadbd'),
                                    f'--defaults-file={ROOT / "config/mariadb.ini"}',
                                    f'--basedir={base}', f'--datadir={DATABASE}',
                                    f'--socket={SOCKET}', f'--port={PORT}',
                                    f'--pid-file={RUN / "mariadbd.pid"}',
                                    f'--log-error={LOGS / "database-error.log"}'],
                                   stdin=subprocess.DEVNULL, stdout=output,
                                   stderr=subprocess.STDOUT, start_new_session=True)
    wait_for(process, lambda: SOCKET.exists() and port_open(PORT), 'MariaDB', 60)
    ensure_database_login()
    print(f'MariaDB ready on 127.0.0.1:{PORT}', flush=True)


def setup():
    if own_pid('mangosd'):
        raise RuntimeError('Stop the world server before importing databases or applying migrations.')
    for name in ('characters', 'logon', 'logs', 'world'):
        if not (SERVER / f'sql/{name}.sql').is_file():
            raise RuntimeError('Download the database first: python3 tools/macos/fetch-database.py')
    write_configs()
    start_database()
    import_sql(ROOT / 'config/create-databases.sql')
    for database, name in [('realmd', 'logon'), ('logs', 'logs'),
                           ('characters', 'characters'), ('mangos', 'world')]:
        tables = query(f"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='{database}'")
        if tables == '0':
            print(f'Importing {database}', flush=True)
            import_sql(SERVER / f'sql/{name}.sql', database)
    targets = {'world': 'mangos', 'characters': 'characters', 'logon': 'realmd', 'logs': 'logs'}
    count = 0
    for path in sorted((SERVER / 'core/sql/migrations').glob('*.sql')):
        match = re.fullmatch(r'(\d{14})_(world|characters|logon|logs)', path.stem)
        if match:
            database = targets[match[2]]
            if query(f"SELECT COUNT(*) FROM migrations WHERE id='{match[1]}'", database) == '0':
                import_sql(path, database)
                count += 1
    query("INSERT INTO realmlist (id,name,address,port) VALUES "
          "(1,'Hordes of Azeroth','127.0.0.1',8085) "
          "ON DUPLICATE KEY UPDATE name=VALUES(name),address=VALUES(address),port=VALUES(port)", 'realmd')
    print(f'Databases ready; applied {count} migrations.', flush=True)


def process_path(pid):
    library = ctypes.CDLL('/usr/lib/libproc.dylib')
    path = ctypes.create_string_buffer(4096)
    length = library.proc_pidpath(pid, path, len(path))
    return Path(os.fsdecode(path.value)).resolve() if length > 0 else None


def own_pid(name):
    path = RUN / f'{name}.pid'
    if path.exists():
        pid = int(path.read_text().strip())
        if process_path(pid) == (RUN / name).resolve():
            return pid
    return None


def start():
    write_configs()
    start_database()
    for name, port in [('realmd', 3724), ('mangosd', 8085)]:
        if own_pid(name):
            print(f'{name} already running.', flush=True)
            continue
        if port_open(port):
            raise RuntimeError(f'Port {port} is already in use by another service.')
        console = None
        if name == 'mangosd':
            fifo = RUN / 'world-console'
            if not fifo.exists():
                os.mkfifo(fifo, 0o600)
            if not stat.S_ISFIFO(fifo.stat().st_mode):
                raise RuntimeError(f'Expected a console pipe: {fifo}')
            console = os.open(fifo, os.O_RDWR)
        try:
            with (LOGS / f'{name}-console.log').open('a') as output:
                process = subprocess.Popen([str(RUN / name), '-c', f'{name}.conf'], cwd=RUN,
                                           stdin=console if console is not None else subprocess.DEVNULL,
                                           stdout=output, stderr=subprocess.STDOUT, start_new_session=True)
            (RUN / f'{name}.pid').write_text(str(process.pid))
            wait_for(process, lambda: port_open(port), name)
        finally:
            if console is not None:
                os.close(console)
        print(f'{name} ready on 127.0.0.1:{port}', flush=True)


def stop():
    for name in ('mangosd', 'realmd'):
        pid = own_pid(name)
        if pid:
            os.kill(pid, signal.SIGINT)
            deadline = time.monotonic() + 60
            while process_path(pid) == (RUN / name).resolve():
                if time.monotonic() > deadline:
                    raise RuntimeError(f'{name} has not shut down; inspect {LOGS}')
                if name == 'mangosd':
                    try:
                        console = os.open(RUN / 'world-console', os.O_WRONLY | os.O_NONBLOCK)
                        try:
                            os.write(console, b'\n')
                        finally:
                            os.close(console)
                    except OSError:
                        pass
                time.sleep(0.5)
        (RUN / f'{name}.pid').unlink(missing_ok=True)
    if SOCKET.exists():
        if Path(query('SELECT @@datadir')).resolve() != DATABASE.resolve():
            raise RuntimeError('Refusing to stop a database with a different data directory.')
        query('SHUTDOWN')
        deadline = time.monotonic() + 60
        while SOCKET.exists() or port_open(PORT):
            if time.monotonic() > deadline:
                raise RuntimeError('MariaDB has not finished shutting down.')
            time.sleep(0.5)
    print('Local server stopped.', flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['setup', 'start', 'stop', 'status', 'console'])
    parser.add_argument('command', nargs='?')
    args = parser.parse_args()
    if args.action == 'setup':
        setup()
    elif args.action == 'start':
        start()
    elif args.action == 'stop':
        stop()
    elif args.action == 'status':
        for name, port in [('MariaDB', PORT), ('realmd', 3724), ('mangosd', 8085)]:
            print(f'{name}: {"listening" if port_open(port) else "stopped"} on 127.0.0.1:{port}')
    elif args.action == 'console':
        if not args.command or not own_pid('mangosd'):
            parser.error('A running world server and a quoted console command are required.')
        with (RUN / 'world-console').open('w') as console:
            console.write(args.command + '\n')


if __name__ == '__main__':
    main()
