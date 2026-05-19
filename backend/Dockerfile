FROM python:3.11-slim

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia o código do backend
COPY backend/ .

# Copia os dados processados para o caminho que config.py espera
# (_ROOT = Path(__file__).parent.parent = /app/.. = /, logo /data/processed/...)
COPY data/processed/ /data/processed/

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
