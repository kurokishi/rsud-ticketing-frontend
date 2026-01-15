import React from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import PrivateRoute from './components/PrivateRoute'
import Dashboard from './components/Dashboard'
import TicketList from './components/TicketList'
import TicketModal from './components/TicketModal'
import MaintenanceChecklist from './components/MaintenanceChecklist'
import BackupReports from './components/BackupReports'
import EKinerjaReport from './components/EKinerjaReport'
import Login from './components/Login'
import Register from './components/Register'
import './App.css'

function App() {
  return (
    <Router>
      <AuthProvider>
        <div className="app-container">
          <Routes>
            {/* Public Routes */}
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            
            {/* Private Routes */}
            <Route path="/" element={
              <PrivateRoute>
                <Dashboard />
              </PrivateRoute>
            } />
            
            <Route path="/tickets" element={
              <PrivateRoute>
                <TicketList />
              </PrivateRoute>
            } />
            
            <Route path="/tickets/new" element={
              <PrivateRoute>
                <TicketModal />
              </PrivateRoute>
            } />
            
            <Route path="/maintenance" element={
              <PrivateRoute>
                <MaintenanceChecklist />
              </PrivateRoute>
            } />
            
            <Route path="/backup" element={
              <PrivateRoute>
                <BackupReports />
              </PrivateRoute>
            } />
            
            <Route path="/reports" element={
              <PrivateRoute>
                <EKinerjaReport />
              </PrivateRoute>
            } />
            
            {/* Redirect unknown routes to dashboard */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </div>
      </AuthProvider>
    </Router>
  )
}

export default App
