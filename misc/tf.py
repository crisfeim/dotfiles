#!/usr/bin/env python3
import os
import sys
import subprocess
sys.path.insert(0, os.path.expanduser('~/dotfiles/misc/t'))
from t import TaskDict, AmbiguousPrefix, UnknownPrefix


# ── VCS detection ──────────────────────────────────────────────────────────────

def find_fossil_root(start=None):
    """Sube el árbol de directorios buscando un checkout Fossil."""
    directory = start or os.getcwd()
    while directory != '/':
        if os.path.isfile(os.path.join(directory, '_FOSSIL_')) or \
           os.path.isfile(os.path.join(directory, '.fslckout')):
            return directory
        directory = os.path.dirname(directory)
    return None


def find_git_root(start=None):
    """Sube el árbol de directorios buscando un repositorio Git."""
    directory = start or os.getcwd()
    while directory != '/':
        if os.path.isdir(os.path.join(directory, '.git')):
            return directory
        directory = os.path.dirname(directory)
    return None


def find_vcs_root(start=None):
    """
    Devuelve (root, vcs) donde vcs es 'fossil' o 'git', o (None, None).
    Fossil tiene prioridad si ambos están presentes en el mismo directorio.
    """
    fossil_root = find_fossil_root(start)
    git_root    = find_git_root(start)

    if fossil_root and git_root:
        # El que esté más profundo (path más largo) gana
        if len(fossil_root) >= len(git_root):
            return fossil_root, 'fossil'
        return git_root, 'git'
    if fossil_root:
        return fossil_root, 'fossil'
    if git_root:
        return git_root, 'git'
    return None, None


# ── VCS commit helpers ─────────────────────────────────────────────────────────

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


def git_commit(root, title):
    """
    Commitea en Git.
    Si no hay nada en el index, hace 'git add -A' primero.
    """
    staged = subprocess.run(
        ['git', 'diff', '--cached', '--quiet'],
        cwd=root
    )
    has_staged = staged.returncode != 0   # returncode != 0 → hay cambios staged

    if not has_staged:
        result = subprocess.run(['git', 'add', '-A'], cwd=root)
        if result.returncode != 0:
            return False

    result = subprocess.run(
        ['git', 'commit', '-m', title],
        cwd=root
    )
    return result.returncode == 0


def vcs_commit(root, vcs, title):
    """Delega al helper correcto según el VCS detectado."""
    if vcs == 'fossil':
        return fossil_commit(root, title)
    if vcs == 'git':
        return git_commit(root, title)
    return False


# ── Rollback ───────────────────────────────────────────────────────────────────

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


# ── Entry point ────────────────────────────────────────────────────────────────

def main():
    args = sys.argv[1:]
    vcs_root, vcs = find_vcs_root()

    if vcs_root:
        task_dir   = vcs_root
        tasks_path = os.path.join(vcs_root, 'tasks')
        if not os.path.exists(tasks_path):
            open(tasks_path, 'w').close()
    else:
        task_dir = os.path.expanduser('~/tasks')

    td = TaskDict(taskdir=task_dir, name='tasks')

    if args and args[0] in ('-f', '--finish') and len(args) >= 2 and vcs_root:
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
        print(f'commiteando ({vcs}): {title}')
        if not vcs_commit(vcs_root, vcs, title):
            print('error: el commit falló, deshaciendo...', file=sys.stderr)
            rollback(vcs_root, task_id, task)
            sys.exit(1)
    else:
        os.execv(sys.executable, [
            sys.executable, os.path.expanduser('~/dotfiles/misc/t/t.py'),
            '--task-dir', task_dir,
            '--list', 'tasks',
        ] + args)


if __name__ == '__main__':
    main()
