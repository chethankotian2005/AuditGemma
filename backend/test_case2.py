import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.signal_layer import run_signal_layer

case_data = {
    "amounts": [8900 + (day * 15) for day in range(1, 32)],
    "transactions": []
}

res = run_signal_layer(case_data)
print("Benford's Law Signal:")
print(res["signals"].get("benfords_law"))
