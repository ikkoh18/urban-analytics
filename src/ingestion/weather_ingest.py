from datetime import datetime
from pathlib import Path
import meteostat as ms
import pandas as pd

from src.config.settings import BASE_DIR


def main():
    print("Fetching hourly weather data...")

    point = ms.Point(34.0522, -118.2437)

    start = datetime(2025, 1, 1)
    end = datetime(2025, 12, 31)

    stations = ms.stations.nearby(point, limit=5)

    data = ms.hourly(stations, start, end)
    df = ms.interpolate(data, point).fetch()

    if df is None or df.empty:
        print("No weather data found.")
        return

    df = df.reset_index()

    weather_dir = BASE_DIR / "data" / "raw" / "weather"
    weather_dir.mkdir(parents=True, exist_ok=True)

    output_file = weather_dir / "weather_hourly_2025.csv"
    df.to_csv(output_file, index=False)

    print("Weather data saved successfully.")
    print(f"Total records: {len(df)}")
    print(f"File saved at: {output_file}")


if __name__ == "__main__":
    main()
