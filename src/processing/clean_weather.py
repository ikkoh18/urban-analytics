from pathlib import Path
import pandas as pd

from src.config.settings import BASE_DIR


def main():
    print("Cleaning weather dataset...")

    raw_dir = BASE_DIR / "data" / "raw" / "weather"
    output_dir = BASE_DIR / "data" / "processed" / "weather"
    output_dir.mkdir(parents=True, exist_ok=True)

    output_file = output_dir / "weather_2025_clean.csv"

    raw_file = next(raw_dir.glob("*.csv"))
    print(f"Reading {raw_file.name}")

    df = pd.read_csv(raw_file)

    df = df.rename(columns={"time": "timestamp", "temp": "temperature", "prcp": "precipitation"})

    df["timestamp"] = pd.to_datetime(df["timestamp"], errors="coerce")
    df["precipitation"] = df["precipitation"].fillna(0)

    df.to_csv(output_file, index=False)

    print(f"Rows saved: {len(df):,}")
    print(f"Saved at: {output_file}")


if __name__ == "__main__":
    main()
