#!/usr/bin/env python3

import os
import sys
import subprocess

sys.path.insert(0, '/usr/local/bin/t')
from t import TaskDict, AmbiguousPrefix, UnknownPrefix


def find_fossil_root(start=None):
    """Sube el árbol de directorios buscando un checkout Fossil."""
    directory = start or os.getcwd()
    while directory != '/':
        if os.path.isfile(os.path.join(directory, '_FOSSIL_')) or \
           os.path.isfile(os.path.join(directory, '.fslckout')):
            return directory
        directory = os.path.dirname(directory)
    return None


def fossil_commit(root, title):
    """Commitea en Fossil. Si no hay nada en staging, hace addremove primero."""
    staged = subprocess.run(
        ['fossil', 'changes', '--added'],
        capture_output=True, text=True, cwd=root
    )
    has_staged = bool(staged.stdout.strip())

    if not has_staged:
        result = subprocess.run(['fossil', 'addremove'], cwd=root)
        if result.returncode != 0:
            return False

    result = subprocess.run(
        ['fossil', 'commit', '-m', title],
        cwd=root
    )
    return result.returncode == 0


def rollback(root, task_id, task):
    """Devuelve una tarea de .tasks.done a tasks si el commit falló."""
    done_path  = os.path.join(root, '.tasks.done')
    tasks_path = os.path.join(root, 'tasks')

    with open(done_path, 'r') as f:
        lines = f.readlines()

    remaining = [l for l in lines if f'id:{task_id}' not in l]
    restored  = [l for l in lines if f'id:{task_id}' in l]

    with open(done_path, 'w') as f:
        f.writelines(remaining)

    with open(tasks_path, 'a') as f:
        f.writelines(restored)

    print(f'rollback: "{task["text"]}" restaurada a pendiente', file=sys.stderr)


def main():
    args = sys.argv[1:]
    fossil_root = find_fossil_root()

    if fossil_root:
        task_dir = fossil_root
        tasks_path = os.path.join(fossil_root, 'tasks')
        if not os.path.exists(tasks_path):
            open(tasks_path, 'w').close()
    else:
        task_dir = os.path.expanduser('~/tasks')

    td = TaskDict(taskdir=task_dir, name='tasks')

    if args and args[0] in ('-f', '--finish') and len(args) >= 2 and fossil_root:
        prefix = args[1]

        try:
            task = td[prefix]
        except AmbiguousPrefix:
            print(f'error: "{prefix}" coincide con más de una tarea', file=sys.stderr)
            sys.exit(1)
        except UnknownPrefix:
            print(f'error: "{prefix}" no coincide con ninguna tarea', file=sys.stderr)
            sys.exit(1)

        task_id = task['id']
        title   = task['text']

        td.finish_task(prefix)
        td.write()

        print(f'commiteando: {title}')
        if not fossil_commit(fossil_root, title):
            print('error: el commit falló, deshaciendo...', file=sys.stderr)
            rollback(fossil_root, task_id, task)
            sys.exit(1)

    else:
        os.execv(sys.executable, [
            sys.executable, '/usr/local/bin/t/t.py',
            '--task-dir', task_dir,
            '--list', 'tasks',
        ] + args)


if __name__ == '__main__':
    main()
