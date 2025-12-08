--[[
    get_hwid_non_root.lua
    Runs the HWID generator Python script and captures the output.
    Run with su -c from outside to have root access.
    
    Usage:
    su -c "cd /storage/emulated/0/Reconnect && export PATH=$PATH:/data/data/com.termux/files/usr/bin && export TERM=xterm-256color && lua ./get_hwid_non_root.lua"
]]

local function get_hwid()
    -- Embedded Python script for HWID generation
    -- Includes root test function to verify root access
    local python_hwid = [=[
import asyncio,hashlib,platform,subprocess,uuid,os
from typing import Optional,List

def test_root_access():
    """Test if we have root access by trying root-only operations"""
    results = []
    
    # Test 1: Check if running as root (uid 0)
    uid = os.getuid()
    results.append(f"UID: {uid} ({'ROOT' if uid == 0 else 'NOT ROOT'})")
    
    # Test 2: Try to read /data/system (root only)
    try:
        files = os.listdir("/data/system")
        results.append(f"/data/system: READABLE ({len(files)} files)")
    except PermissionError:
        results.append("/data/system: PERMISSION DENIED")
    except Exception as e:
        results.append(f"/data/system: {e}")
    
    # Test 3: Try to read /data/data (root only)
    try:
        files = os.listdir("/data/data")
        results.append(f"/data/data: READABLE ({len(files)} apps)")
    except PermissionError:
        results.append("/data/data: PERMISSION DENIED")
    except Exception as e:
        results.append(f"/data/data: {e}")
    
    # Test 4: Try to read ro.serialno (often needs root)
    try:
        serial = subprocess.check_output(["getprop", "ro.serialno"], text=True, stderr=subprocess.DEVNULL).strip()
        results.append(f"ro.serialno: {serial if serial else '(empty)'}")
    except Exception as e:
        results.append(f"ro.serialno: FAILED - {e}")
    
    # Test 5: Try to read /sys/block/mmcblk0/device/serial (may need root)
    try:
        with open("/sys/block/mmcblk0/device/serial", "r") as f:
            storage_serial = f.read().strip()
        results.append(f"Storage serial: {storage_serial}")
    except PermissionError:
        results.append("Storage serial: PERMISSION DENIED")
    except FileNotFoundError:
        results.append("Storage serial: FILE NOT FOUND")
    except Exception as e:
        results.append(f"Storage serial: {e}")
    
    return results

async def _run_getprop(prop:str)->Optional[str]:
    loop=asyncio.get_running_loop()
    try:
        def _call():
            try:return subprocess.check_output(["getprop",prop],text=True,stderr=subprocess.DEVNULL).strip()
            except:return None
        return await loop.run_in_executor(None,_call)or None
    except:return None

async def _read_file(path:str)->Optional[str]:
    loop=asyncio.get_running_loop()
    try:
        def _read():
            try:
                with open(path,"r")as f:return f.read().strip()
            except:return None
        return await loop.run_in_executor(None,_read)
    except:return None

async def get_hwid()->str:
    ids:List[str]=[]
    props=["ro.product.model","ro.product.name","ro.product.brand","ro.product.manufacturer","ro.product.device","ro.board.platform","ro.hardware","ro.build.fingerprint","ro.bootloader","ro.serialno"]
    for p in props:
        v=await _run_getprop(p)
        if v:ids.append(v)
    kv=await _read_file("/proc/version")
    if kv:ids.append(kv.replace(" ",""))
    cpu=await _read_file("/proc/cpuinfo")
    if cpu:ids.append(cpu)
    stor=await _read_file("/sys/block/mmcblk0/device/serial")
    if stor:ids.append(stor)
    hwid=None
    if ids:hwid=hashlib.sha256("-".join(filter(None,ids)).encode()).hexdigest()
    if not hwid:
        fb=[str(uuid.getnode()),platform.node(),platform.machine()]
        hwid=hashlib.sha256("-".join(filter(None,fb)).encode()).hexdigest()
    return hwid

# Run root test first
print("ROOT_TEST_START")
for line in test_root_access():
    print(line)
print("ROOT_TEST_END")

# Then get HWID
print("HWID:" + asyncio.run(get_hwid()))
]=]

    -- Use io.popen to capture Python output
    local handle = io.popen('python3 -c "' .. python_hwid:gsub('"', '\\"') .. '"')
    local output = nil
    
    if handle then
        output = handle:read("*a")
        handle:close()
    end
    
    return output
end


-- Main entry point
print("")
print("==============================================")
print("   HWID Generator with Root Test")
print("==============================================")
print("")

local output = get_hwid()

if output and output ~= "" then
    -- Parse the output
    local in_root_test = false
    local hwid = nil
    
    print("[ROOT ACCESS TEST]")
    print("-" .. string.rep("-", 44))
    
    for line in output:gmatch("[^\r\n]+") do
        if line == "ROOT_TEST_START" then
            in_root_test = true
        elseif line == "ROOT_TEST_END" then
            in_root_test = false
            print("-" .. string.rep("-", 44))
            print("")
        elseif in_root_test then
            print("  " .. line)
        elseif line:match("^HWID:") then
            hwid = line:sub(6)
        end
    end
    
    if hwid and hwid ~= "" then
        print("[HWID GENERATED]")
        print("")
        print("  " .. hwid)
        print("")
        print("Length: " .. #hwid .. " characters")
    else
        print("[ERROR] Failed to extract HWID")
    end
else
    print("[ERROR] Failed to run Python script")
end
