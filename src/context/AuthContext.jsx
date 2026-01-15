import React, { createContext, useState, useContext, useEffect } from 'react'
import { authAPI } from '../api'

const AuthContext = createContext()

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  // Load user from localStorage on mount
  useEffect(() => {
    const token = localStorage.getItem('token')
    const savedUser = localStorage.getItem('user')
    
    if (token && savedUser) {
      setUser(JSON.parse(savedUser))
    }
    
    setLoading(false)
  }, [])

  // Login function
  const login = async (credentials) => {
    try {
      setError(null)
      const response = await authAPI.login(credentials)
      
      const { access_token, user } = response.data
      
      // Save to localStorage
      localStorage.setItem('token', access_token)
      localStorage.setItem('user', JSON.stringify(user))
      
      setUser(user)
      return { success: true, user }
      
    } catch (err) {
      const errorMessage = err.response?.data?.detail || 'Login gagal'
      setError(errorMessage)
      return { success: false, error: errorMessage }
    }
  }

  // Register function
  const register = async (userData) => {
    try {
      setError(null)
      const response = await authAPI.register(userData)
      
      // Auto login after registration
      const loginResponse = await login({
        username: userData.username,
        password: userData.password
      })
      
      return loginResponse
      
    } catch (err) {
      const errorMessage = err.response?.data?.detail || 'Registrasi gagal'
      setError(errorMessage)
      return { success: false, error: errorMessage }
    }
  }

  // Logout function
  const logout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    setUser(null)
    setError(null)
  }

  // Check if user is admin
  const isAdmin = () => {
    return user?.role === 'admin'
  }

  const value = {
    user,
    loading,
    error,
    login,
    register,
    logout,
    isAdmin,
    setError,
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}
