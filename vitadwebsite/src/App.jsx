import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider } from './contexts/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import SignIn from './pages/SignIn';
import SignUp from './pages/SignUp';
import Dashboard from './pages/Dashboard';
import History from './pages/History';
import Profile from './pages/Profile';
import './index.css';

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Toaster
          position="top-right"
          toastOptions={{
            style: { fontFamily: 'Inter, sans-serif', fontSize: 14, borderRadius: 12 },
            success: { style: { background: '#34C759', color: '#fff' } },
            error: { style: { background: '#FF3B30', color: '#fff' } },
          }}
        />
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/history" element={<History />} />
          <Route path="/profile" element={<Profile />} />
          <Route path="/signin" element={<SignIn />} />
          <Route path="/signup" element={<SignUp />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
