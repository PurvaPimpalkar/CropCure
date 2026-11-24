# CropCure 🌱

> **AI-Powered Crop Disease Detection App**
>
> Photograph a crop leaf → Identify the disease → Get the full treatment plan — in seconds.

---

## Project Structure

```
cropcure/
├── mobile/         # Flutter Android app (Dart)
├── backend/        # FastAPI REST API (Python)
└── model/          # CNN model training & inference (TensorFlow)
```

---

## Quick Start

### 1. Start the Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

> **Mock Mode**: If no trained model `.h5` is found, the backend automatically runs in **mock/demo mode** — returning realistic simulated predictions so the Flutter app works end-to-end for development.

API documentation available at: http://localhost:8000/docs

### 2. Run the Flutter App

```bash
cd mobile
flutter pub get
flutter run
```

> For a **physical Android device**, update `_baseUrl` in `mobile/lib/services/api_service.dart`:
> ```dart
> // Replace with your PC's local IP address
> static const String _baseUrl = 'http://192.168.x.x:8000';
> ```

### 3. Train the CNN Model (Optional)

```bash
cd model
pip install -r requirements.txt

# Download PlantVillage dataset, organize as:
#   dataset/train/<class_label>/*.jpg
#   dataset/val/<class_label>/*.jpg

python train.py --data_dir ./dataset --epochs 20 --batch_size 32
# Trained model saved to: model/saved_model/cropcure_model.h5
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter 3.x, Dart |
| Backend API | FastAPI, Python 3.10+ |
| AI Model | MobileNetV2 + TensorFlow/Keras |
| State Mgmt | Provider |
| UI Libraries | flutter_animate, lottie, google_fonts |

## Supported Crops & Diseases

**14 crop types, 38 disease classes** based on the PlantVillage dataset:

Apple, Blueberry, Cherry, Corn, Grape, Orange, Peach, Bell Pepper, Potato, Raspberry, Soybean, Squash, Strawberry, Tomato

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | Server health & model status |
| POST | `/predict` | Upload image → disease + treatment |
| GET | `/diseases` | Full disease catalogue (38 entries) |
| GET | `/diseases/{label}` | Single disease detail |
| GET | `/crops` | List of supported crops |
