from pathlib import Path
import pandas as pd

from src.config.settings import BASE_DIR

KEEP_COLS = ["timestamp", "crm_cd_desc", "vict_age", "vict_sex", "weapon_used_cd", "lat", "lon", "area_name"]


def main():
    print("Cleaning crime dataset...")

    raw_dir = BASE_DIR / "data" / "raw" / "crime"
    output_dir = BASE_DIR / "data" / "processed" / "crime"
    output_dir.mkdir(parents=True, exist_ok=True)

    output_file = output_dir / "crime_2020_2025_clean.csv"

    raw_file = next(raw_dir.glob("*.csv"))
    print(f"Reading {raw_file.name}")

    df = pd.read_csv(raw_file, low_memory=False)

    # Build timestamp from date_occ (date part) + time_occ (HHMM integer)
    date_part = pd.to_datetime(df["date_occ"], errors="coerce").dt.normalize()
    time_str = df["time_occ"].astype(str).str.zfill(4)
    time_delta = pd.to_timedelta(time_str.str[:2].astype(int), unit="h") + \
                 pd.to_timedelta(time_str.str[2:].astype(int), unit="m")
    df["timestamp"] = date_part + time_delta

    # Keep only required columns
    df = df[KEEP_COLS].copy()

    # Drop rows where lat == 0 or timestamp is NaT
    df = df[df["lat"] != 0]
    df = df[df["timestamp"].notna()]

    df.to_csv(output_file, index=False)

    print(f"Rows saved: {len(df):,}")
    print(f"Saved at: {output_file}")


if __name__ == "__main__":
    main()
