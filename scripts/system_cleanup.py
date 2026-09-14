#!/usr/bin/env python3
"""Riverdale system cleanup — a Textual TUI for tidying up the Ubuntu host.

Upgrades APT packages and the Docker Compose stack, then cleans Docker
containers/images/volumes/networks/build cache, APT, the systemd journal,
/tmp, the thumbnail cache, old snap revisions, and flushes the DNS resolver
cache.

Usage:
    system_cleanup.py                 launch the TUI
    system_cleanup.py --dry-run       TUI, dry-run switch pre-enabled
    system_cleanup.py --yes           headless: run all default (safe) tasks, no UI
    system_cleanup.py --yes --dry-run headless dry run
"""

from __future__ import annotations

import argparse
import asyncio
import os
import shutil
from collections.abc import AsyncIterator, Callable
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from rich.text import Text
from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical, VerticalScroll
from textual.screen import ModalScreen
from textual.widgets import (
    Button,
    Footer,
    Header,
    Label,
    RichLog,
    Static,
    Switch,
    TabbedContent,
    TabPane,
)
from textual.widgets.selection_list import Selection
from textual.widgets import SelectionList

SUDO: list[str] = [] if os.geteuid() == 0 else ["sudo"]
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
LOG_DIR = REPO_ROOT / "logs"
COMPOSE_FILE = REPO_ROOT / "docker-compose.yml"


# ---------------------------------------------------------------------------
# Task plumbing
# ---------------------------------------------------------------------------


async def stream_argv(argv: list[str], dry_run: bool, *, cwd: Path | None = None) -> AsyncIterator[str]:
    """Run a command, yielding its combined stdout/stderr line by line."""
    if dry_run:
        where = f" (in {cwd})" if cwd else ""
        yield f"[dry-run] would run: {' '.join(argv)}{where}"
        return
    try:
        proc = await asyncio.create_subprocess_exec(
            *argv,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
            cwd=str(cwd) if cwd else None,
        )
    except FileNotFoundError:
        yield f"command not found: {argv[0]}"
        return
    assert proc.stdout is not None
    async for raw in proc.stdout:
        yield raw.decode(errors="replace").rstrip()
    code = await proc.wait()
    if code != 0:
        yield f"[exit code {code}]"


async def task_apt_upgrade(*, dry_run: bool) -> AsyncIterator[str]:
    if not shutil.which("apt-get"):
        yield "apt-get not found, skipping"
        return
    async for line in stream_argv([*SUDO, "apt-get", "update"], dry_run):
        yield line
    async for line in stream_argv([*SUDO, "apt-get", "upgrade", "-y"], dry_run):
        yield line
    if not dry_run and Path("/var/run/reboot-required").exists():
        yield "[!] a reboot is required to finish applying updates (e.g. new kernel)"


async def task_docker_compose_upgrade(*, dry_run: bool) -> AsyncIterator[str]:
    if not shutil.which("docker"):
        yield "docker not found, skipping"
        return
    if not COMPOSE_FILE.is_file():
        yield f"no docker-compose.yml at {COMPOSE_FILE}, skipping"
        return
    argv = ["docker", "compose", "-f", str(COMPOSE_FILE)]
    async for line in stream_argv([*argv, "pull"], dry_run, cwd=REPO_ROOT):
        yield line
    async for line in stream_argv([*argv, "up", "-d"], dry_run, cwd=REPO_ROOT):
        yield line


async def task_docker_prune(subcmd: str, *, dry_run: bool) -> AsyncIterator[str]:
    if not shutil.which("docker"):
        yield "docker not found, skipping"
        return
    async for line in stream_argv(["docker", subcmd, "prune", "-f"], dry_run):
        yield line


async def task_docker_images_all(*, dry_run: bool) -> AsyncIterator[str]:
    if not shutil.which("docker"):
        yield "docker not found, skipping"
        return
    async for line in stream_argv(["docker", "image", "prune", "-a", "-f"], dry_run):
        yield line


async def task_apt_clean(*, dry_run: bool) -> AsyncIterator[str]:
    if not shutil.which("apt-get"):
        yield "apt-get not found, skipping"
        return
    for argv in (
        [*SUDO, "apt-get", "autoremove", "--purge", "-y"],
        [*SUDO, "apt-get", "autoclean", "-y"],
        [*SUDO, "apt-get", "clean"],
    ):
        async for line in stream_argv(argv, dry_run):
            yield line


async def task_journal_vacuum(*, dry_run: bool) -> AsyncIterator[str]:
    if not shutil.which("journalctl"):
        yield "journalctl not found, skipping"
        return
    async for line in stream_argv([*SUDO, "journalctl", "--vacuum-time=7d"], dry_run):
        yield line


async def task_tmp_files(*, dry_run: bool) -> AsyncIterator[str]:
    argv = [*SUDO, "find", "/tmp", "-mindepth", "1", "-maxdepth", "1", "-mtime", "+7", "-exec", "rm", "-rf", "{}", "+"]
    async for line in stream_argv(argv, dry_run):
        yield line
    yield "done"


async def task_thumbnail_cache(*, dry_run: bool) -> AsyncIterator[str]:
    cache_dir = Path.home() / ".cache" / "thumbnails"
    if not cache_dir.is_dir():
        yield f"no thumbnail cache at {cache_dir}, skipping"
        return
    if dry_run:
        yield f"[dry-run] would remove contents of {cache_dir}"
        return
    for child in cache_dir.iterdir():
        try:
            shutil.rmtree(child) if child.is_dir() else child.unlink()
        except OSError as exc:
            yield f"could not remove {child}: {exc}"
    yield "done"


async def task_snap_cleanup(*, dry_run: bool) -> AsyncIterator[str]:
    if not shutil.which("snap"):
        yield "snap not found, skipping"
        return
    proc = await asyncio.create_subprocess_exec(
        "snap", "list", "--all", stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL
    )
    assert proc.stdout is not None
    out = (await proc.stdout.read()).decode(errors="replace")
    await proc.wait()
    revisions = [
        (parts[0], parts[2])
        for line in out.splitlines()
        if "disabled" in line and len(parts := line.split()) >= 3
    ]
    if not revisions:
        yield "no disabled revisions to remove"
        return
    for name, rev in revisions:
        argv = [*SUDO, "snap", "remove", name, f"--revision={rev}"]
        async for line in stream_argv(argv, dry_run):
            yield line


async def task_dns_flush(*, dry_run: bool) -> AsyncIterator[str]:
    if shutil.which("resolvectl"):
        async for line in stream_argv([*SUDO, "resolvectl", "flush-caches"], dry_run):
            yield line
    elif shutil.which("systemd-resolve"):
        async for line in stream_argv([*SUDO, "systemd-resolve", "--flush-caches"], dry_run):
            yield line
    else:
        yield "no known DNS cache service found, skipping"


@dataclass(frozen=True)
class Task:
    id: str
    label: str
    default: bool
    runner: Callable[..., AsyncIterator[str]]
    category: str
    icon: str = "•"
    dangerous: bool = False


CATEGORIES: list[tuple[str, str]] = [
    ("upgrades", "⬆ Upgrades"),
    ("docker", "🐳 Docker"),
    ("apt_snap", "📦 Apt / Snap"),
    ("journal", "📜 Journal"),
    ("tmp", "🗑 Tmp"),
    ("thumbnails", "🖼 Thumbnails"),
    ("dns", "🌐 DNS"),
]

TASKS: list[Task] = [
    Task("apt_upgrade", "Update & upgrade APT packages", True, task_apt_upgrade, "upgrades", icon="⬆"),
    Task("docker_compose_upgrade", "Pull & upgrade Docker Compose images (riverdale stack)", True,
         task_docker_compose_upgrade, "upgrades", icon="⬆"),
    Task("docker_containers", "Remove stopped Docker containers", True,
         lambda **kw: task_docker_prune("container", **kw), "docker", icon="🐳"),
    Task("docker_images", "Remove dangling Docker images", True,
         lambda **kw: task_docker_prune("image", **kw), "docker", icon="🐳"),
    Task("docker_images_all", "Remove ALL unused Docker images (not just dangling)", False,
         task_docker_images_all, "docker", icon="🐳"),
    Task("docker_networks", "Remove unused Docker networks", True,
         lambda **kw: task_docker_prune("network", **kw), "docker", icon="🐳"),
    Task("docker_volumes", "Remove unused Docker volumes", False,
         lambda **kw: task_docker_prune("volume", **kw), "docker", icon="🐳", dangerous=True),
    Task("docker_build_cache", "Remove Docker build cache", True,
         lambda **kw: task_docker_prune("builder", **kw), "docker", icon="🐳"),
    Task("apt_clean", "APT autoremove + autoclean + clean", True, task_apt_clean, "apt_snap", icon="📦"),
    Task("snap_cleanup", "Remove disabled old snap revisions", True, task_snap_cleanup, "apt_snap", icon="📦"),
    Task("journal_vacuum", "Vacuum systemd journal (keep 7 days)", True, task_journal_vacuum, "journal", icon="📜"),
    Task("tmp_files", "Delete /tmp files older than 7 days", True, task_tmp_files, "tmp", icon="🗑"),
    Task("thumbnail_cache", "Clear user thumbnail cache", True, task_thumbnail_cache, "thumbnails", icon="🖼"),
    Task("dns_flush", "Flush DNS resolver cache", True, task_dns_flush, "dns", icon="🌐"),
]
TASKS_BY_ID = {t.id: t for t in TASKS}
TASKS_BY_CATEGORY: dict[str, list[Task]] = {
    cat_id: [t for t in TASKS if t.category == cat_id] for cat_id, _ in CATEGORIES
}

STATUS_ICON = {"running": "◐", "ok": "✔", "fail": "✘"}
STATUS_STYLE = {"running": "bold yellow", "ok": "bold green", "fail": "bold red"}


MUTED = "#949CC1"  # foreground-darken-1 — reads as muted but stays >=5:1 against $surface


def task_prompt(task: Task, status: str | None = None) -> Text:
    text = Text()
    if status:
        text.append(f"{STATUS_ICON[status]} ", style=STATUS_STYLE[status])
    else:
        text.append(f"{task.icon} ", style=MUTED)
    text.append(task.label, style="bold red" if task.dangerous else "")
    return text

DANGER_NOTE = (
    "Unused Docker volumes can hold config/data for services that are just "
    "stopped, not gone. Deleting them can lose real data."
)


# ---------------------------------------------------------------------------
# Headless mode (for cron / --yes)
# ---------------------------------------------------------------------------


async def run_headless(task_ids: list[str], dry_run: bool, log_file: Path) -> None:
    log_file.parent.mkdir(parents=True, exist_ok=True)
    with log_file.open("w") as fh:
        def emit(text: str) -> None:
            print(text)
            fh.write(text + "\n")

        emit(f"Riverdale system cleanup ({datetime.now():%Y-%m-%d %H:%M:%S})")
        before = shutil.disk_usage("/").free
        for task_id in task_ids:
            task = TASKS_BY_ID[task_id]
            emit(f"\n==> {task.label}")
            async for line in task.runner(dry_run=dry_run):
                emit(f"    {line}")
        after = shutil.disk_usage("/").free
        emit(f"\nFree space on / — before: {before // 1_000_000_000} GB, after: {after // 1_000_000_000} GB")
        emit(f"Log saved to {log_file}")


# ---------------------------------------------------------------------------
# TUI
# ---------------------------------------------------------------------------


class ConfirmScreen(ModalScreen[bool]):
    DEFAULT_CSS = """
    ConfirmScreen {
        align: center middle;
        background: $background 60%;
    }
    #dialog {
        width: 64;
        height: auto;
        max-height: 90%;
        padding: 1 2;
        border: round $primary;
        background: $surface;
    }
    #message-scroll { height: auto; max-height: 14; margin-bottom: 1; }
    #dialog Horizontal { height: auto; align: right middle; }
    #dialog Button { margin-left: 1; min-width: 12; }
    """

    def __init__(self, message: str) -> None:
        super().__init__()
        self._message = message

    def compose(self) -> ComposeResult:
        with Vertical(id="dialog") as dialog:
            dialog.border_title = "Confirm"
            with VerticalScroll(id="message-scroll"):
                yield Static(self._message, markup=True)
            with Horizontal():
                yield Button("Cancel", id="no")
                yield Button("Run", id="yes", variant="success")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        self.dismiss(event.button.id == "yes")


class CleanupApp(App):
    TITLE = "Riverdale Cleanup"
    BINDINGS = [
        ("r", "run_selected", "Run"),
        ("a", "select_defaults", "Defaults"),
        ("t", "change_theme", "Theme"),
        ("q", "quit", "Quit"),
    ]
    CSS = """
    Screen { background: $background; }

    #body { height: 1fr; padding: 1 1 0 1; }

    #tabs {
        width: 2fr;
        border: round $primary;
        background: $surface;
    }
    #tabs SelectionList { padding: 0 1; background: $surface; }

    #side {
        width: 26;
        margin-left: 1;
        padding: 1;
        border: round $primary;
        background: $surface;
    }
    #side .side-label { color: $text-muted; margin-top: 1; }
    #side #dry_run_row { height: 3; align: left middle; }
    #side #dry_run_row Label { margin-right: 1; }
    #side Button { width: 100%; margin-top: 1; }
    #stats { margin-top: 1; color: $text-muted; }
    #stats .value { color: $text; text-style: bold; }

    #log {
        height: 1fr;
        margin: 1 1 1 1;
        border: round $secondary;
        background: $surface;
        padding: 0 1;
    }
    """

    def __init__(self, dry_run_default: bool) -> None:
        super().__init__()
        self.theme = "tokyo-night"
        self._dry_run_default = dry_run_default
        self._cleanup_running = False
        self.log_file = LOG_DIR / f"cleanup-{datetime.now():%Y%m%d-%H%M%S}.log"

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Horizontal(id="body"):
            with TabbedContent(id="tabs") as tabs:
                for cat_id, cat_label in CATEGORIES:
                    cat_tasks = TASKS_BY_CATEGORY[cat_id]
                    with TabPane(f"{cat_label} ({len(cat_tasks)})", id=f"tab_{cat_id}"):
                        selections = [
                            Selection(task_prompt(t), t.id, t.default, id=t.id)
                            for t in cat_tasks
                        ]
                        yield SelectionList[str](*selections, id=f"picker_{cat_id}")
            tabs.border_title = "Tasks"
            tabs.border_subtitle = f"{sum(t.default for t in TASKS)}/{len(TASKS)} selected by default"
            with Vertical(id="side") as side:
                side.border_title = "Controls"
                with Horizontal(id="dry_run_row"):
                    yield Label("Dry run")
                    yield Switch(value=self._dry_run_default, id="dry_run")
                yield Button("▶ Run selected", id="run", variant="success")
                yield Button("Select defaults", id="reset")
                yield Button("Quit", id="quit")
                yield Static("STATUS", classes="side-label")
                yield Static(self._stats_text(), id="stats")
        log = RichLog(id="log", wrap=True, markup=True, auto_scroll=True)
        log.border_title = "Output"
        yield log
        yield Footer()

    def on_mount(self) -> None:
        self.query_one("#log", RichLog).border_subtitle = str(self.log_file)

    def _stats_text(self, status: str = "idle") -> str:
        free_gb = shutil.disk_usage("/").free // 1_000_000_000
        return f"💾 free /: [b]{free_gb} GB[/]\n⏱ state: [b]{status}[/]"

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "run":
            self.action_run_selected()
        elif event.button.id == "quit":
            self.exit()
        elif event.button.id == "reset":
            self.action_select_defaults()

    def _picker_for(self, task: Task) -> SelectionList:
        return self.query_one(f"#picker_{task.category}", SelectionList)

    def action_select_defaults(self) -> None:
        for cat_id, _ in CATEGORIES:
            picker = self.query_one(f"#picker_{cat_id}", SelectionList)
            picker.deselect_all()
            for task in TASKS_BY_CATEGORY[cat_id]:
                if task.default:
                    picker.select(task.id)

    def action_run_selected(self) -> None:
        if self._cleanup_running:
            return
        selected_ids: set[str] = set()
        for cat_id, _ in CATEGORIES:
            picker = self.query_one(f"#picker_{cat_id}", SelectionList)
            selected_ids.update(picker.selected)
        selected: list[str] = [t.id for t in TASKS if t.id in selected_ids]
        if not selected:
            self.notify("No tasks selected", severity="warning")
            return
        labels = "\n".join(f"  • {TASKS_BY_ID[i].label}" for i in selected)
        message = f"Run these {len(selected)} task(s)?\n\n{labels}"
        if "docker_volumes" in selected:
            message += f"\n\n[bold red]⚠ {DANGER_NOTE}[/]"

        def handle_confirm(confirmed: bool | None) -> None:
            if confirmed:
                self.run_worker(self._execute(selected), exclusive=True)

        self.push_screen(ConfirmScreen(message), handle_confirm)

    async def _execute(self, task_ids: list[str]) -> None:
        self._cleanup_running = True
        log = self.query_one("#log", RichLog)
        dry_run = self.query_one("#dry_run", Switch).value
        run_button = self.query_one("#run", Button)
        run_button.disabled = True
        self.query_one("#stats", Static).update(self._stats_text("running…"))

        LOG_DIR.mkdir(parents=True, exist_ok=True)
        before = shutil.disk_usage("/").free
        with self.log_file.open("a") as fh:
            def emit(text: str) -> None:
                log.write(text)
                fh.write(Text.from_markup(text).plain + "\n")

            emit(f"[bold]Riverdale system cleanup[/]  [{MUTED}]{datetime.now():%Y-%m-%d %H:%M:%S}[/]")
            if dry_run:
                emit("[bold yellow]Dry-run mode:[/] no changes will be made")
            for task_id in task_ids:
                task = TASKS_BY_ID[task_id]
                picker = self._picker_for(task)
                picker.replace_option_prompt(task.id, task_prompt(task, "running"))
                emit(f"\n[bold cyan]{task.icon} {task.label}[/]")
                failed = False
                async for line in task.runner(dry_run=dry_run):
                    if "[exit code" in line:
                        failed = True
                        emit(f"    [bold red]{line}[/]")
                    elif line.startswith("[!]") or line.startswith("[dry-run]"):
                        emit(f"    [yellow]{line}[/]")
                    else:
                        emit(f"    {line}")
                picker.replace_option_prompt(task.id, task_prompt(task, "fail" if failed else "ok"))

            after = shutil.disk_usage("/").free
            delta = (after - before) // 1_000_000
            emit(
                f"\n[bold green]✔ Done.[/] Free space on / — before: "
                f"{before // 1_000_000_000} GB, after: {after // 1_000_000_000} GB "
                f"[{MUTED}]({'+' if delta >= 0 else ''}{delta} MB)[/]"
            )
            emit(f"[{MUTED}]Log saved to {self.log_file}[/]")

        self.query_one("#stats", Static).update(self._stats_text("idle"))
        run_button.disabled = False
        self._cleanup_running = False


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def prune_old_logs(days: int = 30) -> None:
    if not LOG_DIR.is_dir():
        return
    cutoff = datetime.now().timestamp() - days * 86400
    for f in LOG_DIR.glob("cleanup-*.log"):
        if f.stat().st_mtime < cutoff:
            f.unlink(missing_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--yes", "-y", action="store_true", help="run default tasks headlessly, no UI")
    parser.add_argument("--dry-run", action="store_true", help="show what would run without changing anything")
    args = parser.parse_args()

    prune_old_logs()

    if SUDO and not args.dry_run and os.isatty(0):
        # Cache sudo credentials up front, before the TUI takes the terminal.
        # Skipped with no TTY (e.g. run from a systemd timer) — that path
        # should run as root instead, where SUDO is empty and this is moot.
        import subprocess

        subprocess.run(["sudo", "-v"])

    if args.yes:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        log_file = LOG_DIR / f"cleanup-{datetime.now():%Y%m%d-%H%M%S}.log"
        task_ids = [t.id for t in TASKS if t.default]
        asyncio.run(run_headless(task_ids, args.dry_run, log_file))
        return

    app = CleanupApp(dry_run_default=args.dry_run)
    app.run()


if __name__ == "__main__":
    main()
