# Rehnumai Application Package

Rehnumai is a Flutter-based mobile and cross-platform educational application engineered to assist teachers through AI-assisted student risk analysis, optical character recognition (OCR) document scanning, daily observation logging, and actionable intervention planning.

---

## Key Features

* Darsgah (Classroom Heatmap): Visual dashboard displaying students grouped by risk level (Stable, Medium, High).
* Nazar (AI Risk Analysis): Multi-agent reasoning pipeline delivering step-by-step risk diagnoses.
* Amal (Actionable Interventions): AI-generated intervention strategies for academics, behavior, and attendance.
* Scan Sheet (OCR Sheet Scanner): Ingests physical paper rosters using Google ML Kit Text Recognition.
* Daily Logging: Qualitative and quantitative observation recording per student.
* Educator Profile: Dark/Light mode theme switching and teacher profile management.

---

## Technical Stack

* Framework: Flutter SDK (Dart ^3.12.2)
* State Management: Provider (^6.1.2)
* Local Data: SharedPreferences (^2.5.2) and Path Provider (^2.1.6)
* Vision & OCR: Google ML Kit Text Recognition (^0.16.0) & Image Picker (^1.1.2)
* Generative AI Engine: Multi-provider HTTP service (Groq, Google Gemini, OpenRouter)

---

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Setup `.env` file in this directory with valid API keys (`GROQ_API_KEY`, `GEMINI_API_KEY`, or `OPENROUTER_API_KEY`).

3. Run application:
   ```bash
   flutter run
   ```
