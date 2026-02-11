import requests
import pandas as pd
from datetime import datetime, timedelta
from src.config.settings import (
    CRIME_DATA_DIR,
    CRIME_API_URL,
    CRIME_API_LIMIT
)

def fetch_crime_data(start_date):
    query = {
        "$limit": CRIME_API_LIMIT,
        "$where": f"date_occ >= '{start_date}'"
    }
    response = requests.get(CRIME_API_URL, params=query)
    response.raise_for_status()
    return response.json()


def main():
    CRIME_DATA_DIR.mkdir(parents=True, exist_ok=True)

    start_date = (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d")
    data = fetch_crime_data(start_date)

    df = pd.DataFrame(data)

    output_file = CRIME_DATA_DIR / "crime_raw.csv"
    df.to_csv(output_file, index=False)

    print(f"Crime data saved at {output_file}")
    print(f"Records collected: {len(df)}")


if __name__ == "__main__":
    main()
