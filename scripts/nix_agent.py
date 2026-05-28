#!/usr/bin/env python3
import asyncio
import subprocess
import os
from google.antigravity import Agent, LocalAgentConfig, CapabilitiesConfig
from google.antigravity.hooks import policy
from google.antigravity.types import TemplatedSystemInstructions

def run_nix_command(args: list[str]) -> str:
    """Executes a safe Nix command on the host system and returns its output.

    Args:
        args: A list of command arguments, e.g. ["flake", "check"] or ["eval", ".#nixosConfigurations.container.config.system.stateVersion"].
    """
    # Restrict execution to only nix-related subcommands for safety
    allowed_subcommands = {"flake", "eval", "build", "show", "check"}
    if not args or args[0] not in allowed_subcommands:
        return f"Error: Command denied. Only safe Nix subcommands {allowed_subcommands} are allowed."

    full_command = ["nix"] + args + [
        "--extra-experimental-features", "nix-command flakes",
        "--extra-deprecated-features", "url-literals or-as-identifier broken-string-indentation"
    ]
    try:
        result = subprocess.run(
            full_command,
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout or "Command finished successfully with no stdout output."
    except subprocess.CalledProcessError as e:
        return f"Nix command failed with exit code {e.returncode}\nStdout: {e.stdout}\nStderr: {e.stderr}"
    except Exception as e:
        return f"An error occurred while executing command: {str(e)}"

def search_nixpkgs(query: str) -> str:
    """Queries the local Nix environment to find matching packages for a query.

    Args:
        query: The name or attribute pattern of the package to search for, e.g. "binwalk" or "distorm".
    """
    try:
        # Run nix-env to find packages matching the query in nixpkgs
        result = subprocess.run(
            ["nix-env", "-qaP", f".*{query}.*", "--description"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout or f"No packages found matching query: {query}"
    except subprocess.CalledProcessError as e:
        return f"Failed to search nixpkgs. Stderr: {e.stderr}"

async def main():
    # 1. Define safety policies for the Nix developer agent
    # We allow safe file operations and Nix-only execution, and ask the user for general commands
    policies = [
        policy.allow("view_file"),
        policy.allow("edit_file"),
        policy.allow("list_directory"),
        policy.allow("find_file"),
        # Custom predicate to only allow our Nix tool function, and prompt for general commands
        policy.allow("run_nix_command"),
        policy.allow("search_nixpkgs"),
    ]

    # 2. System persona instructions for the agent
    nix_persona = (
        "You are an elite NixOS and Nix Flakes specialist. Your mission is to automate and resolve "
        "complex Nix/NixOS tasks, including package refactoring, lockfile upgrades, option migrations, "
        "and sandboxed container/MicroVM configurations.\n\n"
        "Guidelines:\n"
        "1. Prioritize precise edits of Nix expressions using search-and-replace blocks.\n"
        "2. Stage changes in Git immediately to expose files to the Nix Flake system.\n"
        "3. Always run verification checks via run_nix_command with ['flake', 'check'] to ensure 100% clean evaluation."
    )

    # 3. Configure the local agent
    config = LocalAgentConfig(
        system_instructions=TemplatedSystemInstructions(identity=nix_persona),
        tools=[run_nix_command, search_nixpkgs],
        capabilities=CapabilitiesConfig(), # Enables built-in file writing/reading tools
        policies=policies
    )

    # 4. Instantiate and chat with the Nix Agent
    print("Initializing NixSpecialist Agent using Google Antigravity SDK...")
    async with Agent(config=config) as agent:
        prompt = (
            "Verify that our current Nix configurations evaluate and build correctly. "
            "If any packages or options are outdated, search for modern alternatives and fix them."
        )
        print(f"\nPrompt: {prompt}\n")
        print("Agent Thoughts & Output:")
        response = await agent.chat(prompt)
        async for chunk in response:
            print(chunk, end="", flush=True)
        print("\n\nExecution finished successfully.")

if __name__ == "__main__":
    # Ensure active GEMINI_API_KEY environment variable is set
    if "GEMINI_API_KEY" not in os.environ:
        print("Warning: GEMINI_API_KEY environment variable not found.")
        print("Please obtain an API key from Google AI Studio: https://aistudio.google.com/app/api-keys")
        print("Then set it via: export GEMINI_API_KEY='your_key'")
    
    asyncio.run(main())
