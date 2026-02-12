import requests
import pandas as pd
from datetime import datetime, timedelta

from src.config.settings import (
    CRIME_DATA_DIR,
    CRIME_API_URL,
    CRIME_API_LIMIT
)


def fetch_crime_data():
    """
    Fetch last 30 days based on latest available date.
    """

    # Step 1: Get most recent date
    latest_query = {
        "$limit": 1,
        "$order": "date_occ DESC"
    }

    latest_response = requests.get(CRIME_API_URL, params=latest_query)
    latest_response.raise_for_status()

    latest_data = latest_response.json()

    if not latest_data:
        print("No data found in dataset.")
        return []

    latest_date_str = latest_data[0]["date_occ"]
    print(f"Latest available date: {latest_date_str}")

    latest_dt = datetime.strptime(latest_date_str[:10], "%Y-%m-%d")
    start_dt = latest_dt - timedelta(days=30)
    start_date = start_dt.strftime("%Y-%m-%dT00:00:00.000")

    print(f"Fetching data from: {start_date}")

    # Step 2: Paginated fetch
    all_records = []
    offset = 0

    while True:
        query = {
            "$limit": CRIME_API_LIMIT,
            "$offset": offset,
            "$where": f"date_occ >= '{start_date}'",
            "$order": "date_occ ASC"
        }

        response = requests.get(CRIME_API_URL, params=query)
        response.raise_for_status()

        data = response.json()

        if not data:
            break

        all_records.extend(data)
        offset += CRIME_API_LIMIT

        print(f"Fetched {len(all_records)} records so far...")

    return all_records


def select_columns(df):
    columns_needed = [
        "date_occ",
        "area_name",
        "crm_cd_desc",
        "lat",
        "lon"
    ]

    df = df[columns_needed].copy()

    df.rename(columns={
        "date_occ": "date",
        "area_name": "neighborhood",
        "crm_cd_desc": "crime_type",
        "lat": "latitude",
        "lon": "longitude"
    }, inplace=True)

    return df


def main():
    CRIME_DATA_DIR.mkdir(parents=True, exist_ok=True)

    print("Fetching crime data...")

    records = fetch_crime_data()

    if not records:
        print("No records returned.")
        return

    df = pd.DataFrame(records)
    df_clean = select_columns(df)

    output_file = CRIME_DATA_DIR / "crime_raw.csv"
    df_clean.to_csv(output_file, index=False)

    print("\nCrime data saved successfully.")
    print(f"Total records collected: {len(df_clean)}")
    print(f"File saved at: {output_file}")


if __name__ == "__main__":
    main()

