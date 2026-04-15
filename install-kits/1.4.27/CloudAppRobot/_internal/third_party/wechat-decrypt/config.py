"""
Configuration loader for wechat-decrypt.

This is a lightly adapted version for our local Windows environment:
- supports modern Windows WeChat 4.x data under "Documents\\WeChat Files\\<wxid>\\Msg"
- defaults to the new WeChatAppEx process name
- keeps the original relative-path behaviour for keys/decrypted outputs
"""
import glob
import json
import os
import platform
import sys

CONFIG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config.json")

_SYSTEM = platform.system().lower()

if _SYSTEM == "linux":
    _DEFAULT_TEMPLATE_DIR = os.path.expanduser("~/Documents/xwechat_files/your_wxid/db_storage")
    _DEFAULT_PROCESS = "wechat"
elif _SYSTEM == "darwin":
    _DEFAULT_TEMPLATE_DIR = os.path.expanduser("~/Documents/xwechat_files/your_wxid/db_storage")
    _DEFAULT_PROCESS = "WeChat"
else:
    _DEFAULT_TEMPLATE_DIR = r"C:\Users\Administrator\Documents\WeChat Files\your_wxid\Msg"
    _DEFAULT_PROCESS = "WeChatAppEx"

_DEFAULT = {
    "db_dir": _DEFAULT_TEMPLATE_DIR,
    "keys_file": "all_keys.json",
    "decrypted_dir": "decrypted",
    "decoded_image_dir": "decoded_images",
    "wechat_process": _DEFAULT_PROCESS,
}


def _choose_candidate(candidates):
    if len(candidates) == 1:
        return candidates[0]
    if len(candidates) > 1:
        if not sys.stdin.isatty():
            return candidates[0]
        print("[!] Detected multiple WeChat data directories, please choose one:")
        for i, candidate in enumerate(candidates, 1):
            print(f"    {i}. {candidate}")
        print("    0. Skip and configure manually")
        try:
            while True:
                choice = input(f"Choose [0-{len(candidates)}]: ").strip()
                if choice == "0":
                    return None
                if choice.isdigit() and 1 <= int(choice) <= len(candidates):
                    return candidates[int(choice) - 1]
                print("    Invalid choice, try again")
        except (EOFError, KeyboardInterrupt):
            print()
            return None
    return None


def _add_candidate(candidates, seen, path):
    normalized = os.path.normcase(os.path.normpath(path))
    if os.path.isdir(path) and normalized not in seen:
        seen.add(normalized)
        candidates.append(path)


def _auto_detect_db_dir_windows():
    appdata = os.environ.get("APPDATA", "")
    config_dir = os.path.join(appdata, "Tencent", "xwechat", "config")

    data_roots = []
    if os.path.isdir(config_dir):
        for ini_file in glob.glob(os.path.join(config_dir, "*.ini")):
            try:
                content = None
                for enc in ("utf-8", "gbk"):
                    try:
                        with open(ini_file, "r", encoding=enc) as handle:
                            content = handle.read(1024).strip()
                        break
                    except UnicodeDecodeError:
                        continue
                if not content or any(ch in content for ch in "\n\r\x00"):
                    continue
                if os.path.isdir(content):
                    data_roots.append(content)
            except OSError:
                continue

    candidates = []
    seen = set()

    for root in data_roots:
        for match in glob.glob(os.path.join(root, "xwechat_files", "*", "db_storage")):
            _add_candidate(candidates, seen, match)
        for match in glob.glob(os.path.join(root, "WeChat Files", "*", "Msg")):
            _add_candidate(candidates, seen, match)

    documents = os.path.join(os.path.expanduser("~"), "Documents")
    for match in glob.glob(os.path.join(documents, "WeChat Files", "*", "Msg")):
        _add_candidate(candidates, seen, match)

    return _choose_candidate(candidates)


def _auto_detect_db_dir_linux():
    seen = set()
    candidates = []
    search_roots = [os.path.expanduser("~/Documents/xwechat_files")]

    sudo_user = os.environ.get("SUDO_USER")
    if sudo_user:
        import pwd

        try:
            sudo_home = pwd.getpwnam(sudo_user).pw_dir
        except KeyError:
            sudo_home = None
        if sudo_home:
            fallback = os.path.join(sudo_home, "Documents", "xwechat_files")
            if fallback not in search_roots:
                search_roots.append(fallback)

    for root in search_roots:
        if not os.path.isdir(root):
            continue
        for match in glob.glob(os.path.join(root, "*", "db_storage")):
            _add_candidate(candidates, seen, match)

    old_path = os.path.expanduser("~/.local/share/weixin/data/db_storage")
    if os.path.isdir(old_path):
        _add_candidate(candidates, seen, old_path)

    def _mtime(path):
        msg_dir = os.path.join(path, "message")
        target = msg_dir if os.path.isdir(msg_dir) else path
        try:
            return os.path.getmtime(target)
        except OSError:
            return 0

    candidates.sort(key=_mtime, reverse=True)
    return _choose_candidate(candidates)


def auto_detect_db_dir():
    if _SYSTEM == "windows":
        return _auto_detect_db_dir_windows()
    if _SYSTEM == "linux":
        return _auto_detect_db_dir_linux()
    return None


def load_config():
    cfg = {}
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, encoding="utf-8") as handle:
                cfg = json.load(handle)
        except json.JSONDecodeError:
            print(f"[!] {CONFIG_FILE} is invalid JSON, using defaults")
            cfg = {}

    db_dir = cfg.get("db_dir", "")
    if not db_dir or db_dir == _DEFAULT_TEMPLATE_DIR or "your_wxid" in db_dir:
        detected = auto_detect_db_dir()
        if detected:
            print(f"[+] Auto-detected WeChat data dir: {detected}")
            cfg = {**_DEFAULT, **cfg, "db_dir": detected}
            with open(CONFIG_FILE, "w", encoding="utf-8") as handle:
                json.dump(cfg, handle, indent=4, ensure_ascii=False)
            print(f"[+] Saved config to: {CONFIG_FILE}")
        else:
            if not os.path.exists(CONFIG_FILE):
                with open(CONFIG_FILE, "w", encoding="utf-8") as handle:
                    json.dump(_DEFAULT, handle, indent=4, ensure_ascii=False)
            print(f"[!] Could not auto-detect WeChat data dir")
            print(f"    Please edit {CONFIG_FILE} and set db_dir manually")
            sys.exit(1)
    else:
        cfg = {**_DEFAULT, **cfg}

    base = os.path.dirname(os.path.abspath(__file__))
    for key in ("keys_file", "decrypted_dir", "decoded_image_dir"):
        if key in cfg and not os.path.isabs(cfg[key]):
            cfg[key] = os.path.join(base, cfg[key])

    db_dir = cfg.get("db_dir", "")
    if db_dir and os.path.basename(db_dir) in {"db_storage", "Msg"}:
        cfg["wechat_base_dir"] = os.path.dirname(db_dir)
    else:
        cfg["wechat_base_dir"] = db_dir

    if "decoded_image_dir" not in cfg:
        cfg["decoded_image_dir"] = os.path.join(base, "decoded_images")

    return cfg
