# Rehnumai

Rehnumai (derived from the Urdu word for "Guidance") is an AI-powered classroom assistant and student risk analysis platform designed for educators. The application enables teachers and school administrators to monitor student progress, capture qualitative and quantitative classroom observations, parse paper rosters using Optical Character Recognition (OCR), and leverage multi-agent Generative AI pipelines to detect at-risk students early and generate personalized interventions.

---

## Executive Summary

Educators often struggle to keep track of multidimensional student data, including academic test trends, attendance consistency, fee status, and soft behavioral patterns. Rehnumai unifies these data streams into an intuitive dashboard and applies multi-provider Large Language Models (LLMs) to perform automated risk assessments. By categorizing students into risk tiers (Stable, Medium, High) and providing step-by-step analytical reasoning trails, Rehnumai helps teachers move from reactive intervention to proactive guidance.

---

## Core Modules and Capabilities

### 1. Darsgah (Classroom Dashboard)
* Ustaad's Eye Heatmap: Provides a real-time visual grid categorizing every student by their computed risk tier (Stable, Medium, High Risk).
* Roster Overview: Displays quick metrics including attendance rates, recent test averages, and overdue payment flags.
* Fast Filter & Search: Search students by name, filter by risk severity, or sort by latest performance metrics.

### 2. Nazar (Analytical Reasoning Trails)
* Multi-Agent Risk Evaluation: Evaluates composite data (attendance percentage, exam trajectories, fee arrears, and teacher logs).
* Transparent Reasoning Trails: Explains the underlying causes for a student's risk flag rather than serving as a black box.
* Risk Breakdown: Categorizes risk drivers into academic decline, behavioral shift, attendance drop, or economic strain.

### 3. Amal (Targeted AI Interventions)
* Actionable Guidance: Generates tailored, pedagogical recommendations based on individual student profiles.
* Structured Action Plans: Outlines specific steps for teachers, parents, and counselors to support the student's recovery.
* Strategy Tracking: Helps track which interventions were applied and monitor student responses over time.

### 4. Scan Sheet (OCR Document Ingestion)
* Camera and Gallery Import: Capture physical grade sheets, attendance rosters, or handwritten notes using the device camera or image gallery.
* Google ML Kit Text Recognition: Extracts raw text on-device from scanned images with high precision.
* Automated Student Parsing: Converts unstructured OCR text into structured student records ready for import into the system.

### 5. Daily Observation Logging
* Multi-Category Logging: Record daily observations across Attendance, Academics, Behavior, and General Notes.
* Tagged Teacher Notes: Qualitatively tag observations with author context (for example, class teacher, subject specialist, or school counselor).
* Historical Log Timeline: Maintain a permanent record of daily observations for longitudinal analysis.

### 6. Teacher Profile and Personalization
* Customizable Educator Details: Store teacher demographics (name, experience, specialization) to contextualize AI responses.
* Dynamic Dark and Light Themes: Full dark mode and light mode support backed by local preference persistence.

---

## Technical Architecture

### Multi-Provider LLM Fallback Pipeline
Rehnumai implements a resilient, multi-provider HTTP service (`OpenRouterService`) for LLM inference to ensure zero downtime and cost efficiency.

Priority Cascade:
1. Groq API: Primary endpoint utilizing high-speed inference models (such as Llama 3.3 70B Versatile).
2. Google Gemini API: Secondary endpoint utilizing Google AI Studio (Gemini Flash series).
3. OpenRouter API: Tertiary endpoint providing access to fallback open-source models (such as openrouter/free) on HTTP 429 rate limit or 5xx server errors.

Key Pipeline Features:
* Enforced JSON Output: All LLM requests specify structured JSON response format (`json_object`) for robust data parsing.
* Dynamic Fallback: Automatic recovery if the primary API key is missing, exhausted, or encounters network timeouts.
* Configurable Parameters: Customizable temperature and maximum token constraints tailored for classification versus creative generation tasks.

---

## Repository Structure

```
Girls_Gone_Git/
├── README.md                   # Root repository documentation
├── LICENSE                     # Project license file
└── rehnumai/                   # Main Flutter application package
    ├── .env                    # Environment variables (API keys)
    ├── pubspec.yaml            # Package dependencies and assets
    ├── android/                # Android native project files
    ├── ios/                    # iOS native project files
    ├── assets/                 # Embedded assets (images, app icons)
    └── lib/
        ├── main.dart           # Application entry point
        ├── core/               # Core services, state management, constants
        │   ├── app_state.dart  # Provider state management & local preferences
        │   ├── services/
        │   │   ├── gemini_service.dart  # Multi-provider LLM API engine
        │   │   └── ocr_service.dart     # Camera, image picker & ML Kit OCR
        │   └── utils/          # Utility functions and helper scripts
        ├── data/               # Data layer (models, repositories, mocks)
        │   ├── models/
        │   │   ├── student_model.dart   # Student, Attendance, Fee, TaggedNote models
        │   │   ├── log_entry_model.dart # Observation log schemas
        │   │   └── mock_students.dart   # Seed data for demonstration
        │   └── repositories/
        │       └── student_repository.dart # In-memory data store and CRUD operations
        ├── domain/             # Domain logic and abstractions
        └── presentation/       # Presentation layer (UI components & screens)
            └── screens/
                ├── home/            # Darsgah main dashboard & Ustaad's Eye
                ├── analysis/        # Nazar analytical reasoning trails
                ├── amal/            # Amal targeted interventions screen
                ├── scan_sheet/      # OCR scan sheet interface
                ├── daily_log/       # Daily observation logging screen
                ├── student_list/    # Full student roster list
                └── profile/         # Teacher profile & settings screen
```

---

## Technology Stack

* Framework: Flutter SDK (Dart ^3.12.2)
* State Management: Provider (^6.1.2) with ChangeNotifier
* Local Persistence: SharedPreferences (^2.5.2) and Path Provider (^2.1.6)
* Machine Learning & Computer Vision: Google ML Kit Text Recognition (^0.16.0)
* Hardware Access: Image Picker (^1.1.2) and Permission Handler (^11.3.1)
* Generative AI & Networking: Google Generative AI SDK (^0.4.7), HTTP (^1.6.0), and Flutter Dotenv (^6.0.1)
* UI & Styling: Google Fonts (^6.2.1) and Material Design 3

---

## Environment Setup and Configuration

Create a `.env` file in the `rehnumai/` root directory:

```env
# Primary LLM Provider (Groq - High Speed / High Throughput)
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL=llama-3.3-70b-versatile

# Secondary LLM Provider (Google Gemini Direct)
GEMINI_API_KEY=your_gemini_api_key_here

# Tertiary / Fallback Provider (OpenRouter)
OPENROUTER_API_KEY=your_openrouter_api_key_here
OPENROUTER_MODEL=openrouter/free
```

---

## Installation and Execution Guide

### Prerequisites
1. Install Flutter SDK (version 3.12 or higher).
2. Install Android Studio or Xcode for mobile device emulation.
3. Obtain an API key from Groq Console, Google AI Studio, or OpenRouter.

### Step-by-Step Launch

1. Clone the repository:
   ```bash
   git clone https://github.com/Hadiah-Batool/Girls_Gone_Git.git
   cd Girls_Gone_Git/rehnumai
   ```

2. Configure environment variables:
   Ensure the `.env` file exists in `rehnumai/` with valid API keys.

3. Fetch dependencies:
   ```bash
   flutter pub get
   ```

4. Launch the application:
   ```bash
   # Run on connected device or default emulator
   flutter run
   ```

---

## Key Data Models

* Student: Top-level entity representing a student, containing attendance records, fee status, exam score trajectories, and qualitative teacher notes.
* AttendanceRecord: Captures daily presence/absence status along with optional explanatory teacher notes.
* FeeRecord: Tracks payment due dates, amounts due, amounts paid, overdue status, and total overdue duration in days.
* TaggedNote: Structured qualitative entry containing author role tag (class teacher, subject coordinator) and note content.

---

## License

This project is distributed under the MIT License. See `LICENSE` for details.
