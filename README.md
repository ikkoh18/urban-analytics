# Urban Analytics System – Los Angeles

## 📌 Project Overview

This project develops a structured Urban Analytics System focused on Los Angeles. It integrates multiple public data sources to analyze relationships between:

* 🚔 Crime occurrences
* 🚦 Traffic intensity
* 🌧️ Weather conditions

The objective is to build a professional data pipeline that supports:

* Data ingestion
* Data processing and cleaning
* Cross-domain integration
* Analytical metrics and risk indicators
* A Flutter mobile app with an interactive map and analytics dashboard

---

## 🏗️ System Architecture

```
Public Data Sources
    ├── LA Crime (Open Data API)
    ├── Traffic (Caltrans PeMS)
    └── Weather (Meteostat)

            ↓
        RAW Layer

            ↓
     Processing Layer

            ↓
      Analytics Layer

            ↓
       Backend API
  (FastAPI or Firebase — TBD)

            ↓
     Flutter Mobile App
  ├── Interactive Map
  └── Analytics Dashboard
```

---

## 📂 Project Structure

```
urban-analytics/
│
├── data/
│   ├── raw/
│   │   ├── crime/
│   │   ├── traffic/
│   │   └── weather/
│   └── processed/
│
├── src/
│   ├── ingestion/
│   ├── processing/
│   ├── analytics/
│   └── config/
│
├── app/                    # Flutter app (upcoming)
│   ├── lib/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── pubspec.yaml
│
├── notebooks/
├── docs/
├── .env
├── requirements.txt
└── README.md
```

---

## 🚀 Installation Guide

### 1️⃣ Clone the Repository

```bash
git clone <your-repository-url>
cd urban-analytics
```

### 2️⃣ Create Virtual Environment

```bash
python -m venv .venv
```

Activate it:

**Windows (PowerShell)**
```bash
.venv\Scripts\Activate
```

**macOS / Linux**
```bash
source .venv/bin/activate
```

### 3️⃣ Install Dependencies

```bash
pip install -r requirements.txt
```

### 4️⃣ Environment Variables

Create a `.env` file in the root directory:

```
CRIME_API_URL=https://data.lacity.org/resource/2nrs-mtv8.json
CRIME_API_LIMIT=50000
```

---

## 📥 Data Ingestion

### Crime Data (API)

```bash
python -m src.ingestion.crime_ingest
```

Output: `data/raw/crime/`

### Traffic Data (Caltrans PeMS)

1. Create an account at [PeMS](https://pems.dot.ca.gov) (District 7 – Los Angeles)
2. Download **Station Hour** data for the desired months
3. Extract `.txt.gz` files into `data/raw/traffic/`

### Weather Data (Meteostat)

```bash
python -m src.ingestion.weather_ingest
```

Output: `data/raw/weather/`

---

## 🔄 Processing Pipeline

After completing RAW ingestion:

1. **Clean crime dataset** → `crime_2020_2025_clean.csv`
   - Combine `date_occ` + `time_occ` into a single `timestamp`
   - Filter relevant columns
   - Remove records with `lat == 0` (invalid geocodes)

2. **Clean weather dataset** → `weather_2025_clean.csv`
   - Rename columns to project standard
   - Fill null precipitation with `0`

3. **Hourly aggregation**
   - Crime: group by hour → `crime_count`
   - Traffic: aggregate all stations → `total_flow` (sum), `avg_speed` (mean)

4. **Integrate datasets** → `urban_dataset_2025.csv`
   - Outer join on `timestamp`
   - Forward-fill weather columns

Final schema:
```
timestamp | crime_count | traffic_flow | avg_speed | temperature | precipitation
```

---

## 📱 Flutter App

The presentation layer is a Flutter mobile application with two main screens accessible via a bottom navigation bar.

### Interactive Map

Built with `flutter_map` + OpenStreetMap tiles. Displays four toggleable layers:

| Layer | Data source |
|---|---|
| Crime heatmap | LAPD records (lat/lon) |
| Traffic flow | PeMS avg_speed by road segment |
| Hourly risk alerts | Combined crime + traffic score |
| Weather overlay | Meteostat precipitation/temperature |

Filters: time range, day of week, individual layer toggle. Tap on any region to see its risk score (low / moderate / high).

### Analytics Dashboard

Built with `fl_chart`. Three thematic blocks:

| Block | Visualizations |
|---|---|
| Crime | Occurrences by hour of day · Weekly trend line |
| Traffic | Vehicle flow curve · Avg speed by time slot |
| Correlations | Precipitation vs avg speed · Crime vs traffic by hour |

Period selector at the top: day of week, month, or custom date range.

### Future Recommendations & Predictions

The most advanced layer of the app — a module that anticipates urban conditions rather than just displaying historical data:

| Feature | Approach |
|---|---|
| Traffic prediction | SARIMA or Prophet models on hourly flow/speed time series |
| Risk prediction | Regression / gradient boosting crossing hour, day, temperature, precipitation |
| Contextual recommendations | Plain-language suggestions: best time to cross an area, alternate routes on rainy days, hourly risk alerts by neighborhood |

Models are trained on the backend and served via API. The app consumes final predictions only — no local ML processing.

### Architecture

Pattern: **BLoC** (Business Logic Component) with three layers:
- `data/` — models, repositories, API calls
- `domain/` — use cases, risk score calculation, prediction consumption
- `presentation/` — widgets, screens, BLoCs

### Backend (to be decided after M4)

| Option | Notes |
|---|---|
| FastAPI + PostgreSQL | REST API, analytics logic server-side |
| Firebase | Pre-processed data sync, simpler infra |

---

## 🗺️ Roadmap

| Milestone | Deliverable | Status |
|---|---|---|
| M1 — Ingestion | Raw files in `data/raw/` | ✅ Done |
| M2 — Traffic pipeline | `traffic_2025_core.csv` | ✅ Done |
| M3 — Crime + weather cleaning | Two processed CSVs | 🔄 In progress |
| M4 — Dataset integration | `urban_dataset_2025.csv` | ⏳ Pending |
| M5 — Exploratory analytics | Correlation notebook | ⏳ Pending |
| M6 — Risk indicators | Recommendation rules | ⏳ Pending |
| M7 — Flutter app + backend | Map + dashboard mobile | ⏳ Pending |

---

## 🎯 Project Goals

This project demonstrates:

* Layered data engineering pipeline design (RAW → Processing → Analytics)
* Multi-source public data integration
* Temporal and spatial analytics
* Evidence-based urban risk indicators
* Predictive modeling for traffic and crime (SARIMA, Prophet, gradient boosting)
* Full-stack delivery: Python data pipeline + Flutter mobile app with recommendations

---

## 🧠 Final Note

This is not just a dashboard project.

It is a structured urban data system designed to simulate real-world analytical workflows used in transportation, safety, and city planning — delivered as a mobile application that makes urban intelligence accessible to any user navigating an unfamiliar city.

---

Built with Python, Flutter, and structured engineering principles.
