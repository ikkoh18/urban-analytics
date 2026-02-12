import requests
import pandas as pd

from src.config.settings import (
    CRIME_DATA_DIR,
    CRIME_API_URL,
    CRIME_API_LIMIT
)


def fetch_all_crime_data():
    """
    Fetch all crime records from 2020 to present using pagination.
    No filtering. Full raw ingestion.
    """

    all_records = []
    offset = 0

    while True:
        query = {
            "$limit": CRIME_API_LIMIT,
            "$offset": offset,
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


def main():
    CRIME_DATA_DIR.mkdir(parents=True, exist_ok=True)

    print("Starting full crime data ingestion (2020 to present)...")

    records = fetch_all_crime_data()

    if not records:
        print("No records returned.")
        return

    df = pd.DataFrame(records)

    output_file = CRIME_DATA_DIR / "crime_raw_full_2020_present.csv"
    df.to_csv(output_file, index=False)

    print("\nFull crime dataset saved successfully.")
    print(f"Total records collected: {len(df)}")
    print(f"File saved at: {output_file}")


if __name__ == "__main__":
    main()
