from pathlib import Path
import pandas as pd

from src.config.settings import BASE_DIR


def main():
    print("Integrating datasets...")

    processed_dir = BASE_DIR / "data" / "processed"
    output_file = processed_dir / "urban_dataset_2025.csv"

    # --- Crime: aggregate to hourly crime_count ---
    print("Loading crime data...")
    crime = pd.read_csv(
        processed_dir / "crime" / "crime_2020_2025_clean.csv",
        usecols=["timestamp"],
    )
    crime["timestamp"] = pd.to_datetime(crime["timestamp"], errors="coerce")
    crime_hourly = (
        crime.set_index("timestamp")
        .resample("h")
        .size()
        .rename("crime_count")
        .reset_index()
    )

    # --- Traffic: aggregate to hourly total_flow (sum) and avg_speed (mean) ---
    print("Loading traffic data...")
    traffic = pd.read_csv(
        processed_dir / "traffic" / "traffic_2025_core.csv",
        usecols=["timestamp", "total_flow", "avg_speed"],
    )
    traffic["timestamp"] = pd.to_datetime(traffic["timestamp"], errors="coerce")
    traffic_hourly = (
        traffic.set_index("timestamp")
        .resample("h")
        .agg(traffic_flow=("total_flow", "sum"), avg_speed=("avg_speed", "mean"))
        .reset_index()
    )

    # --- Weather: already hourly ---
    print("Loading weather data...")
    weather = pd.read_csv(
        processed_dir / "weather" / "weather_2025_clean.csv",
        usecols=["timestamp", "temperature", "precipitation"],
    )
    weather["timestamp"] = pd.to_datetime(weather["timestamp"], errors="coerce")

    # --- Outer join on timestamp ---
    print("Merging...")
    merged = (
        crime_hourly
        .merge(traffic_hourly, on="timestamp", how="outer")
        .merge(weather, on="timestamp", how="outer")
        .sort_values("timestamp")
        .reset_index(drop=True)
    )

    # Forward-fill weather columns
    merged[["temperature", "precipitation"]] = merged[["temperature", "precipitation"]].ffill()

    # Final column order
    merged = merged[["timestamp", "crime_count", "traffic_flow", "avg_speed", "temperature", "precipitation"]]

    merged.to_csv(output_file, index=False)

    print(f"Rows saved: {len(merged):,}")
    print(f"Columns: {list(merged.columns)}")
    print(f"Saved at: {output_file}")


if __name__ == "__main__":
    main()
