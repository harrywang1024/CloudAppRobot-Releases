"""
Extract per-database raw encryption keys from WeChat process memory on Windows.

Adapted for both legacy Weixin.exe and modern WeChatAppEx processes.
"""
import ctypes
import ctypes.wintypes as wt
import os
import re
import sys
import time

import functools

print = functools.partial(print, flush=True)

from key_scan_common import (
    collect_db_files,
    cross_verify_keys,
    save_results,
    scan_memory_for_keys,
)

kernel32 = ctypes.windll.kernel32
MEM_COMMIT = 0x1000
READABLE = {0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80}


class MBI(ctypes.Structure):
    _fields_ = [
        ("BaseAddress", ctypes.c_uint64),
        ("AllocationBase", ctypes.c_uint64),
        ("AllocationProtect", wt.DWORD),
        ("_pad1", wt.DWORD),
        ("RegionSize", ctypes.c_uint64),
        ("State", wt.DWORD),
        ("Protect", wt.DWORD),
        ("Type", wt.DWORD),
        ("_pad2", wt.DWORD),
    ]


def get_pids():
    from config import load_config
    import psutil
    import subprocess

    cfg = load_config()
    configured = cfg.get("wechat_process", "").strip()
    process_names = []
    if configured:
        process_names.append(configured)
    for fallback in ("WeChatAppEx", "WeChatAppEx.exe", "Weixin.exe", "WeChat.exe"):
        if fallback not in process_names:
            process_names.append(fallback)

    pids = []
    seen = set()

    normalized_names = {name.lower() for name in process_names}
    normalized_names |= {
        name.lower().removesuffix(".exe") for name in process_names
    }

    for proc in psutil.process_iter(["pid", "name", "memory_info"]):
        try:
            proc_name = str(proc.info.get("name") or "").strip()
            if not proc_name:
                continue
            proc_name_l = proc_name.lower()
            proc_name_base = proc_name_l.removesuffix(".exe")
            if proc_name_l not in normalized_names and proc_name_base not in normalized_names:
                continue
            pid = int(proc.info["pid"])
            if pid in seen:
                continue
            seen.add(pid)
            mem_info = proc.info.get("memory_info")
            mem = int(getattr(mem_info, "rss", 0) // 1024) if mem_info else 0
            pids.append((pid, mem, proc_name))
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess, KeyError, ValueError):
            continue

    for process_name in process_names:
        result = subprocess.run(
            ["tasklist", "/FI", f"IMAGENAME eq {process_name}", "/FO", "CSV", "/NH"],
            capture_output=True,
            text=True,
        )
        for line in result.stdout.strip().split("\n"):
            if not line.strip():
                continue
            parts = line.strip('"').split('","')
            if len(parts) < 5:
                continue
            pid = int(parts[1])
            if pid in seen:
                continue
            seen.add(pid)
            mem = int(parts[4].replace(",", "").replace(" K", "").strip() or "0")
            pids.append((pid, mem, process_name))

    if not pids:
        raise RuntimeError("No supported WeChat process is running")

    pids.sort(key=lambda item: item[1], reverse=True)
    for pid, mem, process_name in pids:
        print(f"[+] {process_name} PID={pid} ({mem // 1024}MB)")
    return [(pid, mem) for pid, mem, _ in pids]


def read_mem(handle, addr, size):
    buf = ctypes.create_string_buffer(size)
    n_read = ctypes.c_size_t(0)
    if kernel32.ReadProcessMemory(handle, ctypes.c_uint64(addr), buf, size, ctypes.byref(n_read)):
        return buf.raw[: n_read.value]
    return None


def enum_regions(handle):
    regions = []
    addr = 0
    mbi = MBI()
    while addr < 0x7FFFFFFFFFFF:
        if kernel32.VirtualQueryEx(
            handle, ctypes.c_uint64(addr), ctypes.byref(mbi), ctypes.sizeof(mbi)
        ) == 0:
            break
        if mbi.State == MEM_COMMIT and mbi.Protect in READABLE and 0 < mbi.RegionSize < 500 * 1024 * 1024:
            regions.append((mbi.BaseAddress, mbi.RegionSize))
        nxt = mbi.BaseAddress + mbi.RegionSize
        if nxt <= addr:
            break
        addr = nxt
    return regions


def main():
    from config import load_config

    cfg = load_config()
    db_dir = cfg["db_dir"]
    out_file = cfg["keys_file"]

    print("=" * 60)
    print("  Extracting WeChat database keys")
    print("=" * 60)

    db_files, salt_to_dbs = collect_db_files(db_dir)
    print(f"\nFound {len(db_files)} databases, {len(salt_to_dbs)} unique salts")

    pids = get_pids()

    hex_re = re.compile(b"x'([0-9a-fA-F]{64,192})'")
    key_map = {}
    remaining_salts = set(salt_to_dbs.keys())
    all_hex_matches = 0
    t0 = time.time()

    for pid, _mem_kb in pids:
        handle = kernel32.OpenProcess(0x0010 | 0x0400, False, pid)
        if not handle:
            print(f"[WARN] Cannot open PID={pid}, skipping")
            continue

        try:
            regions = enum_regions(handle)
            total_bytes = sum(size for _, size in regions)
            total_mb = total_bytes / 1024 / 1024
            print(f"\n[*] Scanning PID={pid} ({total_mb:.0f}MB, {len(regions)} regions)")

            scanned_bytes = 0
            for idx, (base, size) in enumerate(regions):
                data = read_mem(handle, base, size)
                scanned_bytes += size
                if not data:
                    continue

                all_hex_matches += scan_memory_for_keys(
                    data,
                    hex_re,
                    db_files,
                    salt_to_dbs,
                    key_map,
                    remaining_salts,
                    base,
                    pid,
                    print,
                )

                if (idx + 1) % 200 == 0:
                    elapsed = time.time() - t0
                    progress = scanned_bytes / total_bytes * 100 if total_bytes else 100
                    print(
                        f"  [{progress:.1f}%] {len(key_map)}/{len(salt_to_dbs)} salts matched, "
                        f"{all_hex_matches} hex patterns, {elapsed:.1f}s"
                    )
        finally:
            kernel32.CloseHandle(handle)

        if not remaining_salts:
            print("\n[+] All salts matched, skipping remaining processes")
            break

    elapsed = time.time() - t0
    print(f"\nScan complete: {elapsed:.1f}s, {len(pids)} processes, {all_hex_matches} hex matches")

    cross_verify_keys(db_files, salt_to_dbs, key_map, print)
    save_results(db_files, salt_to_dbs, key_map, db_dir, out_file, print)


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as exc:
        print(f"\n[ERROR] {exc}")
        sys.exit(1)
