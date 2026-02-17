from pathlib import Path
import pandas as pd

from src.config.settings import BASE_DIR


def main():
    print("Building cleaned traffic dataset from raw files...")

    raw_dir = BASE_DIR / "data" / "raw" / "traffic"
    output_dir = BASE_DIR / "data" / "processed" / "traffic"
    output_dir.mkdir(parents=True, exist_ok=True)

    output_file = output_dir / "traffic_2025_core.csv"

    files = sorted(raw_dir.glob("*.txt"))

    first_chunk = True

    for file in files:
        print(f"Processing {file.name}")

        for chunk in pd.read_csv(
            file,
            sep=",",
            header=None,
            chunksize=200_000,
            low_memory=False
        ):

            core = chunk[[0, 1, 3, 4, 6, 8, 9, 10, 11]].copy()

            core.columns = [
                "timestamp",
                "station_id",
                "route",
                "direction",
                "station_length",
                "percent_observed",
                "total_flow",
                "avg_occupancy",
                "avg_speed"
            ]

            core["timestamp"] = pd.to_datetime(
                core["timestamp"],
                format="%m/%d/%Y %H:%M:%S",
                errors="coerce"
            )

            core.to_csv(
                output_file,
                mode="w" if first_chunk else "a",
                index=False,
                header=first_chunk
            )

            first_chunk = False

    print("Traffic dataset cleaned successfully.")
    print(f"Saved at: {output_file}")

    
if __name__ == "__main__":
    main()
