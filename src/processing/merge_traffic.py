from pathlib import Path
import pandas as pd

from src.config.settings import BASE_DIR


def main():
    print("Merging traffic files (memory safe)...")

    traffic_raw_dir = BASE_DIR / "data" / "raw" / "traffic"
    traffic_processed_dir = BASE_DIR / "data" / "processed" / "traffic"
    traffic_processed_dir.mkdir(parents=True, exist_ok=True)

    output_file = traffic_processed_dir / "traffic_2025_full.csv"

    files = sorted(traffic_raw_dir.glob("*.txt"))

    first_file = True

    for file in files:
        print(f"Processing {file.name}")

        for chunk in pd.read_csv(
            file,
            sep=",",
            header=None,
            chunksize=100_000,  # lê em blocos
            low_memory=False
        ):
            # Converter timestamp
            chunk[0] = pd.to_datetime(
                chunk[0],
                format="%m/%d/%Y %H:%M:%S",
                errors="coerce"
            )

            # Salvar incrementalmente
            chunk.to_csv(
                output_file,
                mode="w" if first_file else "a",
                index=False,
                header=first_file
            )

            first_file = False

    print("Traffic merge completed successfully.")
    print(f"Saved at: {output_file}")


if __name__ == "__main__":
    main()

