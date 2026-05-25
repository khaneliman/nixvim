#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3

import argparse
import json
import subprocess
from html import escape


KINDS = {
    "plugins": "plugin",
    "colorschemes": "colorscheme",
}


def main():
    parser = argparse.ArgumentParser(
        description="Generate announcement messages for added Nixvim plugins"
    )
    parser.add_argument(
        "--diff-json",
        required=True,
        help="compact JSON produced by diff-plugins.py",
    )
    parser.add_argument(
        "--flake-ref",
        default=".",
        help="flake ref to read plugin metadata from",
    )
    parser.add_argument(
        "--metadata-json",
        help="precomputed metadata JSON, mainly for tests",
    )
    parser.add_argument("--pr-number", type=int)
    parser.add_argument("--pr-url")
    parser.add_argument("--pr-author-name")
    parser.add_argument("--pr-author-url")
    parser.add_argument(
        "--compact",
        "-c",
        action="store_true",
        help="produce compact JSON instead of prettifying",
    )
    args = parser.parse_args()

    diff = json.loads(args.diff_json)
    pr = pr_from_args(args)
    metadata = (
        json.loads(args.metadata_json)
        if args.metadata_json is not None
        else read_metadata(args.flake_ref, added_entries(diff))
    )
    result = build_announcements(diff, metadata, pr)

    print(
        json.dumps(
            result,
            separators=((",", ":") if args.compact else None),
            indent=(None if args.compact else 2),
            sort_keys=True,
        )
    )


def pr_from_args(args):
    if args.pr_number is None:
        return None
    return {
        "number": args.pr_number,
        "url": args.pr_url,
        "author_name": args.pr_author_name,
        "author_url": args.pr_author_url,
    }


def added_entries(diff):
    return flatten_diff(diff, "added")


def removed_entries(diff):
    return flatten_diff(diff, "removed")


def flatten_diff(diff, action):
    entries = []
    for namespace in sorted(KINDS):
        for name in sorted(diff.get(action, {}).get(namespace, [])):
            entries.append(
                {
                    "name": name,
                    "namespace": namespace,
                    "kind": KINDS[namespace],
                }
            )
    return entries


def read_metadata(flake_ref, entries):
    if not entries:
        return []

    expr = f"""
      cfg:
      let
        plugins = builtins.fromJSON ''{json.dumps(entries, separators=(",", ":"))}'';
        get = namespace: name: cfg.config.meta.nixvimInfo.${{namespace}}.${{name}} or {{}};
        package = namespace: name: cfg.options.${{namespace}}.${{name}}.package.default or null;
      in
      map
        (entry:
          let
            info = get entry.namespace entry.name;
            pkg = package entry.namespace entry.name;
          in
          entry // {{
            displayName = info.originalName or entry.name;
            url = info.url or (if pkg == null then null else pkg.meta.homepage or null);
            description = info.description or (if pkg == null then null else pkg.meta.description or null);
          }}
        )
        plugins
    """
    cmd = [
        "nix",
        "eval",
        f"{flake_ref}#nixvimConfiguration",
        "--apply",
        expr,
        "--json",
    ]
    out = subprocess.check_output(cmd)
    return json.loads(out)


def build_announcements(diff, metadata, pr):
    removed = removed_entries(diff)
    metadata_by_key = {
        (entry["namespace"], entry["name"]): entry for entry in metadata
    }
    added = []

    for entry in added_entries(diff):
        plugin = metadata_by_key.get((entry["namespace"], entry["name"]), entry)
        plugin = {**entry, **plugin}
        added.append(render_added(plugin, pr))

    blocked = bool(removed)
    summary_markdown = render_summary(added, removed, blocked)
    comment_markdown = render_comment(added, removed) if blocked else None

    return {
        "added": added,
        "blocked": blocked,
        "comment_markdown": comment_markdown,
        "removed": removed,
        "summary_markdown": summary_markdown,
    }


def render_added(plugin, pr):
    name = plugin["name"]
    namespace = plugin["namespace"]
    kind = plugin["kind"]
    title = kind.upper()
    display_name = plugin.get("displayName") or name
    url = plugin.get("url")
    description = plugin.get("description")
    docs_url = f"https://nix-community.github.io/nixvim/{namespace}/{name}/index.html"

    lines = [
        f"[NEW {title}]",
        "",
        f"{display_name} support has been added!",
    ]
    if description:
        lines.extend(["", f"Description: {description}"])
    if url:
        lines.append(f"URL: {url}")
    lines.append(f"Docs: {docs_url}")
    if pr:
        lines.append(f"PR #{pr['number']} by {pr['author_name']}: {pr['url']}")

    markdown_lines = [
        f"### NEW {title}: {display_name}",
        "",
        f"`{namespace}.{name}` support has been added.",
    ]
    if description:
        markdown_lines.extend(["", description])
    links = [f"[Documentation]({docs_url})"]
    if url:
        links.insert(0, f"[Upstream]({url})")
    if pr:
        links.append(
            f"[PR #{pr['number']}]({pr['url']}) by [{pr['author_name']}]({pr['author_url']})"
        )
    markdown_lines.extend(["", " | ".join(links)])

    html_parts = [
        f"<h3>NEW {escape(title)}: {escape(display_name)}</h3>",
        f"<p><code>{escape(namespace)}.{escape(name)}</code> support has been added.</p>",
    ]
    if description:
        html_parts.append(f"<p>{escape(description)}</p>")
    html_links = [f'<a href="{escape(docs_url)}">Documentation</a>']
    if url:
        html_links.insert(0, f'<a href="{escape(url)}">Upstream</a>')
    if pr:
        html_links.append(
            f'<a href="{escape(pr["url"])}">PR #{pr["number"]}</a> by '
            f'<a href="{escape(pr["author_url"])}">{escape(pr["author_name"])}</a>'
        )
    html_parts.append(f"<p>{' | '.join(html_links)}</p>")

    return {
        "description": description,
        "displayName": display_name,
        "docsUrl": docs_url,
        "html": "\n".join(html_parts),
        "kind": kind,
        "markdown": "\n".join(markdown_lines),
        "name": name,
        "namespace": namespace,
        "plain": "\n".join(lines),
        "url": url,
    }


def render_summary(added, removed, blocked):
    if not added and not removed:
        return "## Plugin announcements\n\nNo plugin or colorscheme announcements were generated.\n"

    lines = ["## Plugin announcements", ""]
    if blocked:
        lines.extend(
            [
                "> [!WARNING]",
                "> Automatic announcements were not prepared because this PR removes plugin options.",
                "> Please review the plugin changes and announce them manually if needed.",
                "",
            ]
        )

    if added:
        lines.extend(["### Added", ""])
        for entry in added:
            lines.extend([entry["markdown"], ""])

    if removed:
        lines.extend(["### Removed", ""])
        for entry in removed:
            lines.append(f"- `{entry['namespace']}.{entry['name']}`")
        lines.append("")

    return "\n".join(lines)


def render_comment(added, removed):
    lines = [
        "> [!WARNING]",
        "> Automatic plugin announcements were not prepared because this PR removes plugin options.",
        "> Please review the plugin changes and announce them manually if needed.",
        "",
    ]

    if added:
        lines.extend(["Added:", ""])
        for entry in added:
            lines.append(f"- `{entry['namespace']}.{entry['name']}`")
        lines.append("")

    lines.extend(["Removed:", ""])
    for entry in removed:
        lines.append(f"- `{entry['namespace']}.{entry['name']}`")

    return "\n".join(lines)


if __name__ == "__main__":
    main()
