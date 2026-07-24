# 💊 VitaScan — AI-Powered Vitamin D Analysis Platform

VitaScan is an intelligent, web-based healthcare application designed to analyze Vitamin D test strip images using **Google Gemini Vision AI**. It provides real-time concentration estimation (ng/mL), health risk classification, interactive trend tracking, PDF medical report downloading, and multi-channel result sharing (including WhatsApp).

---

## 🌟 Key Features

- 📸 **AI Test Strip Analyzer**: Instant computer-vision quantification of Vitamin D levels using Google Gemini Vision AI (`gemini-3-flash-preview`).
- 🩺 **Clinical Risk Classification**:
  - 🔴 **Deficient**: `< 20 ng/mL`
  - 🟡 **Insufficient**: `20–30 ng/mL`
  - 🟢 **Sufficient**: `30–100 ng/mL`
  - ⛔ **Toxic**: `> 100 ng/mL`
- 📄 **PDF Medical Report Generation**: One-click creation of downloadable PDF health reports complete with branded headers, patient metadata, risk indicators, reference ranges, and personalized recommendations.
- 📲 **Instant Result Sharing**: Share scan reports directly via:
  - 🟢 **WhatsApp** (pre-formatted deep link text)
  - 💬 **SMS**
  - 📧 **Email**
  - ✈️ **Telegram**
  - 📋 **Copy to Clipboard**
  - 📱 **Native Device Share Sheet**
- 📈 **Interactive Trend Analytics**: Visual representation of past test results with interactive bar charts powered by Recharts.
- 🗂️ **Patient Records & History**: Searchable and filterable history of past scans with patient demographic metadata (age, gender, BMI, medical conditions).
- 🔐 **Authentication & Access Control**: Supabase Auth integration supporting Google OAuth & Email/Password login with allowlist filtering.

---

## 🛠️ Technology Stack

- **Frontend**: React 19, Vite, React Router v7
- **Styling**: Modern Vanilla CSS with responsive CSS Grid/Flexbox, custom design tokens, and glassmorphism UI elements
- **Database & Auth**: Supabase (PostgreSQL + Auth)
- **AI / Computer Vision**: Google Gemini AI API (`@google/genai` / REST integration)
- **Data Visualization**: Recharts
- **PDF Generation**: jsPDF
- **Notifications**: React Hot Toast

---

## 🚀 Getting Started

### Prerequisites
- **Node.js**: v18.0.0 or higher
- **npm**: v9.0.0 or higher

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/vitascan.git
cd vitascan/vitadwebsite
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Environment Setup
Create a `.env` file in the root directory (`vitadwebsite/.env`) and populate the following keys:

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://your-supabase-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key

# Google Gemini AI API Key
VITE_GEMINI_API_KEY=your-gemini-api-key

# Allowlisted Account Emails (comma-separated)
VITE_ALLOWED_EMAILS=user1@example.com,user2@example.com
```

### 4. Run the Local Development Server
```bash
npm run dev
```
Open [http://localhost:5173](http://localhost:5173) in your browser.

---

## 📂 Project Structure

```text
vitadwebsite/
├── public/                  # Static public assets
├── src/
│   ├── assets/              # Logos and graphics
│   ├── components/          # Reusable UI components
│   │   ├── ProtectedRoute.jsx
│   │   ├── ReportActions.jsx# PDF download & share buttons/modal
│   │   └── Sidebar.jsx      # Navigation sidebar
│   ├── contexts/            # React Contexts (AuthContext)
│   ├── lib/                 # Core utility libraries
│   │   ├── gemini.js        # Gemini Vision AI API integration
│   │   ├── reportUtils.js   # PDF report generator & share builder
│   │   └── supabase.js      # Supabase client setup & access rules
│   ├── pages/               # Page components
│   │   ├── Dashboard.jsx    # Upload strip, AI analysis & results
│   │   ├── History.jsx      # Historical scan records & modal details
│   │   ├── Profile.jsx      # User profile management
│   │   ├── SignIn.jsx       # Login page
│   │   └── SignUp.jsx       # Registration page
│   ├── App.jsx              # Routing & app container
│   ├── index.css            # Core design system & component styles
│   └── main.jsx             # React entrypoint
├── .env                     # Environment variables configuration
├── package.json             # Project dependencies & scripts
├── vercel.json              # Vercel deployment rewrite rules
└── vite.config.js           # Vite configuration
```

---

## 🚢 Deployment

### Deploying to Vercel
1. Push your repository to GitHub.
2. Import the project into [Vercel](https://vercel.com).
3. Set the Root Directory to `vitadwebsite`.
4. Add environment variables (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_GEMINI_API_KEY`) in Vercel project settings.
5. In your **Supabase Dashboard** ➔ **Authentication** ➔ **URL Configuration**, add your Vercel URL and `http://localhost:5173` to **Redirect URLs**.

---

## 🔒 Disclaimer

*VitaScan is an AI-assisted quantification tool intended for informational and monitoring purposes only. It does not replace professional medical diagnosis, advice, or treatment. Users should always consult a licensed medical professional for clinical interpretation of Vitamin D levels.*
