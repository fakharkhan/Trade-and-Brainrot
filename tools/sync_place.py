#!/usr/bin/env python3
"""Rebuild TradeAndBrainrot.rbxlx from src/ so Studio can play without Rojo."""
from __future__ import annotations

import html
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "TradeAndBrainrot.rbxlx"

REF = 0


def rid() -> str:
    global REF
    REF += 1
    return f"RBX{REF}"


def uid() -> str:
    return uuid.uuid4().hex


def cdata(text: str) -> str:
    # Avoid ending the CDATA early
    return text.replace("]]>", "]]]]><![CDATA[>")


def module_item(name: str, source: str) -> str:
    return f"""\t\t\t<Item class="ModuleScript" referent="{rid()}">
\t\t\t\t<Properties>
\t\t\t\t\t<ProtectedString name="Source"><![CDATA[{cdata(source)}]]></ProtectedString>
\t\t\t\t\t<string name="Name">{html.escape(name)}</string>
\t\t\t\t</Properties>
\t\t\t</Item>
"""


def script_item(name: str, source: str, class_name: str = "Script") -> str:
    return f"""\t\t\t<Item class="{class_name}" referent="{rid()}">
\t\t\t\t<Properties>
\t\t\t\t\t<ProtectedString name="Source"><![CDATA[{cdata(source)}]]></ProtectedString>
\t\t\t\t\t<bool name="Disabled">false</bool>
\t\t\t\t\t<string name="Name">{html.escape(name)}</string>
\t\t\t\t</Properties>
\t\t\t</Item>
"""


def folder_item(name: str, children: str) -> str:
    return f"""\t\t\t<Item class="Folder" referent="{rid()}">
\t\t\t\t<Properties>
\t\t\t\t\t<string name="Name">{html.escape(name)}</string>
\t\t\t\t</Properties>
{children}\t\t\t</Item>
"""


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def main() -> None:
    shared_dir = ROOT / "src/ReplicatedStorage/Shared"
    modules_dir = ROOT / "src/ServerScriptService/Modules"
    sss = ROOT / "src/ServerScriptService"
    client = ROOT / "src/StarterPlayer/StarterPlayerScripts/TradeClient.client.lua"

    shared_children = ""
    for p in sorted(shared_dir.glob("*.lua")):
        shared_children += module_item(p.stem, read(p))

    module_children = ""
    for p in sorted(modules_dir.glob("*.lua")):
        module_children += module_item(p.stem, read(p))

    scripts = ""
    scripts += script_item("Main", read(sss / "Main.server.lua"), "Script")
    scripts += script_item("TradeServer", read(sss / "TradeServer.server.lua"), "Script")
    scripts += folder_item("Modules", module_children)

    shared_folder = folder_item("Shared", shared_children)
    client_script = script_item("TradeClient", read(client), "LocalScript")

    xml = f"""<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
\t<Item class="Workspace" referent="{rid()}">
\t\t<Properties>
\t\t\t<string name="Name">Workspace</string>
\t\t</Properties>
\t</Item>
\t<Item class="ReplicatedStorage" referent="{rid()}">
\t\t<Properties>
\t\t\t<string name="Name">ReplicatedStorage</string>
\t\t</Properties>
{shared_folder}\t</Item>
\t<Item class="ServerScriptService" referent="{rid()}">
\t\t<Properties>
\t\t\t<string name="Name">ServerScriptService</string>
\t\t</Properties>
{scripts}\t</Item>
\t<Item class="ServerStorage" referent="{rid()}">
\t\t<Properties>
\t\t\t<string name="Name">ServerStorage</string>
\t\t</Properties>
\t</Item>
\t<Item class="StarterPlayer" referent="{rid()}">
\t\t<Properties>
\t\t\t<string name="Name">StarterPlayer</string>
\t\t</Properties>
\t\t<Item class="StarterPlayerScripts" referent="{rid()}">
\t\t\t<Properties>
\t\t\t\t<string name="Name">StarterPlayerScripts</string>
\t\t\t</Properties>
{client_script}\t\t</Item>
\t</Item>
</roblox>
"""
    OUT.write_text(xml, encoding="utf-8")
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
