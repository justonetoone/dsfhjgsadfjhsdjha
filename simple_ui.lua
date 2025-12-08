--[[
    simple_ui.lua
    Simple UI with input handling - Python embedded in Lua
    Similar structure to get_hwid.lua
    Uses su -c inside Python for root commands
]]

local function run_ui()
    local python_ui = [=[
import os
import subprocess

def clear_screen():
    os.system('clear' if os.name == 'posix' else 'cls')

def print_header(title="Main Menu"):
    print("=" * 50)
    print(f"        {title}")
    print("=" * 50)
    print()

def print_menu(options):
    for i, option in enumerate(options, 1):
        print(f"  {i}. {option}")
    print()
    print("  0. Exit")
    print()

def get_input(prompt="Select option: "):
    try:
        return input(prompt).strip()
    except (EOFError, KeyboardInterrupt):
        return "0"

def show_message(msg, style="info"):
    styles = {
        "info": "[INFO]",
        "success": "[SUCCESS]",
        "error": "[ERROR]",
        "warning": "[WARNING]"
    }
    prefix = styles.get(style, "[INFO]")
    print(f"{prefix} {msg}")
    print()

def pause():
    input("Press Enter to continue...")

# ==========================================
# Root command helpers (su -c)
# ==========================================

def run_root_cmd(cmd):
    """Run a command with su -c and return output"""
    try:
        result = subprocess.run(
            ["su", "-c", cmd],
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "", "Command timed out", -1
    except Exception as e:
        return "", str(e), -1

def run_normal_cmd(cmd):
    """Run a command without root and return output"""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "", "Command timed out", -1
    except Exception as e:
        return "", str(e), -1

def main_menu():
    options = [
        "Run command with su -c",
        "Run command without root",
        "Test getprop (su -c)",
        "Test getprop (no root)",
        "Read file with su -c",
        "Compare root vs non-root",
        "Settings"
    ]
    
    while True:
        clear_screen()
        print_header("Root Command Tester")
        print_menu(options)
        
        choice = get_input()
        
        if choice == "0":
            clear_screen()
            print("Goodbye!")
            break
        elif choice == "1":
            run_custom_root_cmd()
        elif choice == "2":
            run_custom_normal_cmd()
        elif choice == "3":
            test_getprop_root()
        elif choice == "4":
            test_getprop_normal()
        elif choice == "5":
            read_file_root()
        elif choice == "6":
            compare_root_nonroot()
        elif choice == "7":
            settings_menu()
        else:
            show_message("Invalid option. Please try again.", "error")
            pause()

def run_custom_root_cmd():
    clear_screen()
    print_header("Run Command with su -c")
    
    print("Enter command to run with root:")
    cmd = get_input("> ")
    
    if cmd:
        print()
        print("Running: su -c")
        print("-" * 40)
        
        stdout, stderr, code = run_root_cmd(cmd)
        
        print()
        print("Exit code:")
        print()
        if stdout:
            print("STDOUT:")
            print(stdout[:500] if len(stdout) > 500 else stdout)
        if stderr:
            print("STDERR:")
            print(stderr[:500] if len(stderr) > 500 else stderr)
        if not stdout and not stderr:
            print("(no output)")
    else:
        show_message("No command entered.", "warning")
    
    print()
    pause()

def run_custom_normal_cmd():
    clear_screen()
    print_header("Run Command (No Root)")
    
    print("Enter command to run:")
    cmd = get_input("> ")
    
    if cmd:
        print()
        print(f"Running: {cmd}")
        print("-" * 40)
        
        stdout, stderr, code = run_normal_cmd(cmd)
        
        print()
        print(f"Exit code: {code}")
        print()
        if stdout:
            print("STDOUT:")
            print(stdout[:500] if len(stdout) > 500 else stdout)
        if stderr:
            print("STDERR:")
            print(stderr[:500] if len(stderr) > 500 else stderr)
        if not stdout and not stderr:
            print("(no output)")
    else:
        show_message("No command entered.", "warning")
    
    print()
    pause()

def test_getprop_root():
    clear_screen()
    print_header("Test getprop (su -c)")
    
    props = [
        "ro.product.model",
        "ro.product.brand",
        "ro.product.manufacturer",
        "ro.build.fingerprint",
        "ro.serialno"
    ]
    
    print("Testing getprop with su -c...")
    print("-" * 40)
    print()
    
    for prop in props:
        stdout, stderr, code = run_root_cmd(f"getprop {prop}")
        status = "OK" if code == 0 and stdout else "FAIL"
        value = stdout[:40] + "..." if len(stdout) > 40 else stdout
        print(f"[{status}] {prop}")
        print(f"      = {value if value else '(empty)'}")
        print()
    
    pause()

def test_getprop_normal():
    clear_screen()
    print_header("Test getprop (No Root)")
    
    props = [
        "ro.product.model",
        "ro.product.brand",
        "ro.product.manufacturer",
        "ro.build.fingerprint",
        "ro.serialno"
    ]
    
    print("Testing getprop without root...")
    print("-" * 40)
    print()
    
    for prop in props:
        stdout, stderr, code = run_normal_cmd(f"getprop {prop}")
        status = "OK" if code == 0 and stdout else "FAIL"
        value = stdout[:40] + "..." if len(stdout) > 40 else stdout
        print(f"[{status}] {prop}")
        print(f"      = {value if value else '(empty)'}")
        print()
    
    pause()

def read_file_root():
    clear_screen()
    print_header("Read File with su -c")
    
    print("Enter file path to read:")
    filepath = get_input("> ")
    
    if not filepath:
        filepath = "/proc/version"
        print(f"Using default: {filepath}")
    
    print()
    print(f"Running: su -c \"cat {filepath}\"")
    print("-" * 40)
    
    stdout, stderr, code = run_root_cmd(f"cat {filepath}")
    
    print()
    print(f"Exit code: {code}")
    print()
    if stdout:
        print("Content:")
        print(stdout[:1000] if len(stdout) > 1000 else stdout)
    if stderr:
        print("Error:")
        print(stderr)
    if not stdout and not stderr:
        print("(no output)")
    
    print()
    pause()

def compare_root_nonroot():
    clear_screen()
    print_header("Compare Root vs Non-Root")
    
    print("Enter command to compare:")
    cmd = get_input("> ")
    
    if not cmd:
        cmd = "getprop ro.product.model"
        print(f"Using default: {cmd}")
    
    print()
    print("=" * 40)
    print("WITH su -c:")
    print("=" * 40)
    stdout1, stderr1, code1 = run_root_cmd(cmd)
    print(f"Exit: {code1}")
    print(f"Out: {stdout1[:200] if stdout1 else '(empty)'}")
    if stderr1:
        print(f"Err: {stderr1[:100]}")
    
    print()
    print("=" * 40)
    print("WITHOUT root:")
    print("=" * 40)
    stdout2, stderr2, code2 = run_normal_cmd(cmd)
    print(f"Exit: {code2}")
    print(f"Out: {stdout2[:200] if stdout2 else '(empty)'}")
    if stderr2:
        print(f"Err: {stderr2[:100]}")
    
    print()
    print("=" * 40)
    print("COMPARISON:")
    print("=" * 40)
    if stdout1 == stdout2:
        print("Results are IDENTICAL")
    else:
        print("Results are DIFFERENT")
    
    print()
    pause()

def settings_menu():
    settings = {
        "debug_mode": False,
        "timeout": 10,
        "show_stderr": True
    }
    
    while True:
        clear_screen()
        print_header("Settings")
        
        print(f"  1. Debug Mode: {'ON' if settings['debug_mode'] else 'OFF'}")
        print(f"  2. Command Timeout: {settings['timeout']}s")
        print(f"  3. Show STDERR: {'ON' if settings['show_stderr'] else 'OFF'}")
        print()
        print("  0. Back to Main Menu")
        print()
        
        choice = get_input()
        
        if choice == "0":
            break
        elif choice == "1":
            settings['debug_mode'] = not settings['debug_mode']
            show_message(f"Debug Mode {'enabled' if settings['debug_mode'] else 'disabled'}.", "success")
            pause()
        elif choice == "2":
            new_timeout = get_input("Enter timeout in seconds: ")
            try:
                settings['timeout'] = int(new_timeout)
                show_message(f"Timeout set to {settings['timeout']}s.", "success")
            except ValueError:
                show_message("Invalid number.", "error")
            pause()
        elif choice == "3":
            settings['show_stderr'] = not settings['show_stderr']
            show_message(f"Show STDERR {'enabled' if settings['show_stderr'] else 'disabled'}.", "success")
            pause()
        else:
            show_message("Invalid option.", "error")
            pause()

if __name__ == "__main__":
    try:
        main_menu()
    except Exception as e:
        print(f"[ERROR] {e}")
]=]

    os.execute('python3 -c "' .. python_ui:gsub('"', '\\"') .. '"')
end


-- Main entry point
run_ui()

