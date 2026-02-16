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
* Analytical metrics
* Future recommendations and predictions

The system is designed with engineering best practices, separating raw ingestion from processing and analytics layers.

---

# 🧱 Architecture Overview

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
   Insights & Predictions
```

---

# 📂 Project Structure

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
├── docs/
├── src/
│   ├── ingestion/
│   ├── processing/
│   ├── analytics/
│   └── config/
│
├── .env
├── requirements.txt
└── README.md
```

---

# 🚀 Installation Guide

Follow these steps carefully to set up the project correctly.

---

## 1️⃣ Clone the Repository

```bash
git clone <your-repository-url>
cd urban-analytics
```

---

## 2️⃣ Create Virtual Environment

```bash
python -m venv .venv
```

Activate it:

### Windows (PowerShell)

```bash
.venv\Scripts\Activate
```

### macOS / Linux

```bash
source .venv/bin/activate
```

You should see:

```
(.venv)
```

---

## 3️⃣ Install Dependencies

```bash
pip install -r requirements.txt
```

Verify installation:

```bash
pip list
```

---

## 4️⃣ Environment Variables

Create a `.env` file in the root directory:

```
CRIME_API_URL=https://data.lacity.org/resource/2nrs-mtv8.json
CRIME_API_LIMIT=50000
```

---

# 📥 Data Ingestion

## Crime Data (API)

Run:

```bash
python -m src.ingestion.crime_ingest
```

Data will be saved in:

```
data/raw/crime/
```

---

## Traffic Data (Caltrans PeMS)

1. Create an account at PeMS (District 7 – Los Angeles)
2. Download **Station Hour** data
3. Select desired months (e.g., full 2025)
4. Extract `.txt.gz` files
5. Place them in:

```
data/raw/traffic/
```

---

## Weather Data (Meteostat)

Run:

```bash
python -m src.ingestion.weather_ingest
```

Data will be saved in:

```
data/raw/weather/
```

---

# 🔄 Next Steps (Processing Phase)

After completing all RAW ingestion:

1. Merge monthly traffic files
2. Standardize timestamps across domains
3. Clean individual datasets
4. Align temporal granularity
5. Integrate crime, traffic, and weather
6. Generate analytical metrics
7. Develop insights and predictive components

---

# 🎯 Project Goals

This project aims to demonstrate:

* Data engineering pipeline design
* Multi-source integration
* Temporal and spatial analytics
* Urban mobility analysis
* Evidence-based decision support

---

# 🧠 Final Note

This is not just a dashboard project.

It is a structured urban data system designed to simulate real-world analytical workflows used in transportation, safety, and city planning environments.

---

Built with Python and structured engineering principles.
