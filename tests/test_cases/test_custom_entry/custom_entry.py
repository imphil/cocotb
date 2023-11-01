import sys
import threading
from typing import List

from cocotb.log import _filter_from_c, _log_from_c  # noqa: F401


def entry_func(argv: List[str]) -> None:
    print("thread for entry_func: " + str(threading.current_thread()))
    sys.stdout.flush()
    with open("results.log", "w") as file:
        print("got entry", file=file)


def _sim_event(message: str) -> None:
    print("thread for _sim_event: " + str(threading.current_thread()))
    sys.stdout.flush()
    with open("results.log", "a") as file:
        print(f"got event message={message}", file=file)
