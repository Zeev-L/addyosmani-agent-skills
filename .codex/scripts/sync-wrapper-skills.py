#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import shutil
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class WrapperSpec:
    alias: str
    title: str
    description: str
    short_description: str
    default_prompt: str


WRAPPERS: tuple[WrapperSpec, ...] = (
    WrapperSpec(
        alias="spec",
        title="Spec",
        description=(
            "Starts the agent-skills spec workflow as an explicit compatibility alias. "
            "Use when you want the `agent-skills:spec` or `/spec` lifecycle entrypoint, "
            "not a generic request to describe something."
        ),
        short_description="Start the agent-skills spec workflow explicitly in Codex.",
        default_prompt="Use @agent-skills:spec to run the agent-skills spec workflow in Codex.",
    ),
    WrapperSpec(
        alias="plan",
        title="Plan",
        description=(
            "Runs the agent-skills planning workflow as an explicit compatibility alias. "
            "Use when you want the `agent-skills:plan` or `/plan` lifecycle entrypoint, "
            "not for generic high-level discussion."
        ),
        short_description="Run the agent-skills planning workflow explicitly in Codex.",
        default_prompt="Use @agent-skills:plan to run the agent-skills plan workflow in Codex.",
    ),
    WrapperSpec(
        alias="build",
        title="Build",
        description=(
            "Runs the agent-skills build workflow as an explicit compatibility alias. "
            "Use when you want the `agent-skills:build` or `/build` lifecycle entrypoint, "
            "not for generic compilation or bundling tasks."
        ),
        short_description="Run the agent-skills build workflow explicitly in Codex.",
        default_prompt="Use @agent-skills:build to run the agent-skills build workflow in Codex.",
    ),
    WrapperSpec(
        alias="test",
        title="Test",
        description=(
            "Runs the agent-skills test workflow as an explicit compatibility alias. "
            "Use when you want the `agent-skills:test` or `/test` lifecycle entrypoint, "
            "not for generic test runner commands."
        ),
        short_description="Run the agent-skills test workflow explicitly in Codex.",
        default_prompt="Use @agent-skills:test to run the agent-skills test workflow in Codex.",
    ),
    WrapperSpec(
        alias="review",
        title="Review",
        description=(
            "Runs the agent-skills review workflow as an explicit compatibility alias. "
            "Use when you want the `agent-skills:review` or `/review` lifecycle entrypoint "
            "for code review."
        ),
        short_description="Run the agent-skills review workflow explicitly in Codex.",
        default_prompt="Use @agent-skills:review to run the agent-skills review workflow in Codex.",
    ),
    WrapperSpec(
        alias="ship",
        title="Ship",
        description=(
            "Runs the agent-skills ship workflow as an explicit compatibility alias. "
            "Use when you want the `agent-skills:ship` or `/ship` lifecycle entrypoint "
            "for release readiness."
        ),
        short_description="Run the agent-skills ship workflow explicitly in Codex.",
        default_prompt="Use @agent-skills:ship to run the agent-skills ship workflow in Codex.",
    ),
    WrapperSpec(
        alias="code-simplify",
        title="Code Simplify",
        description=(
            "Runs the agent-skills code simplification workflow as an explicit compatibility alias. "
            "Use when you want the `agent-skills:code-simplify` or `/code-simplify` lifecycle "
            "entrypoint."
        ),
        short_description="Run the agent-skills code-simplify workflow explicitly in Codex.",
        default_prompt=(
            "Use @agent-skills:code-simplify to run the agent-skills code-simplify workflow "
            "in Codex."
        ),
    ),
)

FRONTMATTER_RE = re.compile(r"^---\n(?P<frontmatter>.*?)\n---\n(?P<body>.*)$", re.S)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync the Codex-only wrapper skills from the Claude command source files."
    )
    parser.add_argument(
        "--output-dir",
        default=None,
        help=(
            "Write wrapper skills into the specified directory instead of the repo-tracked "
            ".codex/plugin/skills directory."
        ),
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Check whether the generated wrapper skills are up to date without writing them.",
    )
    return parser.parse_args()


def extract_command_body(command_path: Path) -> str:
    raw = command_path.read_text(encoding="utf-8")
    match = FRONTMATTER_RE.match(raw)
    if not match:
        raise ValueError(f"{command_path} is missing frontmatter")
    body = match.group("body").lstrip("\n")
    return body.rstrip() + "\n"


def render_skill(wrapper: WrapperSpec, command_path: Path, command_ref: str) -> str:
    body = extract_command_body(command_path)
    return (
        "---\n"
        f"name: {wrapper.alias}\n"
        f"description: {wrapper.description}\n"
        "---\n\n"
        f"# {wrapper.title}\n\n"
        f"> Generated from `{command_ref}` by "
        "`.codex/scripts/sync-wrapper-skills.py`. Edit the command file or generator instead of "
        "this wrapper directly.\n\n"
        f"Compatibility alias for the corresponding Claude command in "
        f"`{command_ref}`.\n\n"
        f"This alias exists so Codex users can invoke the lifecycle workflow explicitly as "
        f"`agent-skills:{wrapper.alias}`.\n"
        "Follow the current session's higher-priority system, developer, and repo rules first.\n"
        "If those rules disagree about commit, approval, documentation, or file locations, obey "
        "those rules instead of this alias.\n\n"
        f"{body}"
    )


def render_openai_yaml(wrapper: WrapperSpec) -> str:
    return (
        "# Generated by .codex/scripts/sync-wrapper-skills.py. Edit the generator instead of this file.\n"
        "interface:\n"
        f'  display_name: "{wrapper.title}"\n'
        f'  short_description: "{wrapper.short_description}"\n'
        f'  default_prompt: "{wrapper.default_prompt}"\n'
    )


def snapshot_tree(root: Path) -> dict[str, bytes]:
    if not root.exists():
        return {}

    snapshot: dict[str, bytes] = {}
    for path in sorted(p for p in root.rglob("*") if p.is_file()):
        rel_path = path.relative_to(root).as_posix()
        snapshot[rel_path] = path.read_bytes()
    return snapshot


def snapshot_wrapper_tree(root: Path) -> dict[str, bytes]:
    if not root.exists():
        return {}

    snapshot: dict[str, bytes] = {}
    for wrapper in WRAPPERS:
        wrapper_root = root / wrapper.alias
        if not wrapper_root.exists():
            continue
        for path in sorted(p for p in wrapper_root.rglob("*") if p.is_file()):
            rel_path = path.relative_to(root).as_posix()
            snapshot[rel_path] = path.read_bytes()
    return snapshot


def build_wrapper_bundle(repo_root: Path, output_root: Path) -> None:
    output_root.mkdir(parents=True, exist_ok=True)

    for wrapper in WRAPPERS:
        command_path = repo_root / ".claude" / "commands" / f"{wrapper.alias}.md"
        if not command_path.exists():
            raise FileNotFoundError(f"Missing command source: {command_path}")

        wrapper_root = output_root / wrapper.alias
        wrapper_root.mkdir(parents=True, exist_ok=True)
        command_ref = command_path.relative_to(repo_root).as_posix()

        (wrapper_root / "SKILL.md").write_text(
            render_skill(wrapper, command_path, command_ref),
            encoding="utf-8",
        )

        agents_root = wrapper_root / "agents"
        agents_root.mkdir(parents=True, exist_ok=True)
        (agents_root / "openai.yaml").write_text(
            render_openai_yaml(wrapper),
            encoding="utf-8",
        )


def main() -> int:
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[2]
    codex_wrappers_root = (
        Path(args.output_dir).expanduser().resolve()
        if args.output_dir is not None
        else repo_root / ".codex" / "plugin" / "skills"
    )

    with tempfile.TemporaryDirectory(prefix="agent-skills-codex-") as temp_dir:
        temp_root = Path(temp_dir) / "skills"
        build_wrapper_bundle(repo_root, temp_root)

        current_snapshot = snapshot_wrapper_tree(codex_wrappers_root)
        expected_snapshot = snapshot_tree(temp_root)

        changed = sorted(set(current_snapshot) ^ set(expected_snapshot))
        changed.extend(
            path for path in sorted(set(current_snapshot) & set(expected_snapshot))
            if current_snapshot[path] != expected_snapshot[path]
        )

        if args.check:
            if changed:
                for path in changed:
                    print(f".codex/plugin/skills/{path}")
                return 1
            return 0

        if not changed:
            print("Codex wrapper skills already up to date")
            return 0

        codex_wrappers_root.parent.mkdir(parents=True, exist_ok=True)

        for wrapper in WRAPPERS:
            target_wrapper_root = codex_wrappers_root / wrapper.alias
            if target_wrapper_root.exists():
                shutil.rmtree(target_wrapper_root)
            shutil.copytree(temp_root / wrapper.alias, target_wrapper_root)

        for path in changed:
            if args.output_dir is not None:
                print(f"updated {codex_wrappers_root.as_posix()}/{path}")
            else:
                print(f"updated .codex/plugin/skills/{path}")
        return 0


if __name__ == "__main__":
    sys.exit(main())
