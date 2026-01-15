import axios from 'axios'

// Create axios instance
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000',
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor untuk menambahkan token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor untuk handle errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Token expired or invalid
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

// Auth API
export const authAPI = {
  login: (credentials) => api.post('/api/auth/login', credentials),
  register: (userData) => api.post('/api/auth/register', userData),
}

// Ticket API
export const ticketAPI = {
  getAll: (params) => api.get('/api/tickets', { params }),
  getById: (id) => api.get(`/api/tickets/${id}`),
  create: (data) => api.post('/api/tickets', data),
  update: (id, data) => api.put(`/api/tickets/${id}`, data),
  delete: (id) => api.delete(`/api/tickets/${id}`),
}

// Category API
export const categoryAPI = {
  getAll: () => api.get('/api/categories'),
  create: (data) => api.post('/api/categories', data),
}

// Dashboard API
export const dashboardAPI = {
  getStats: () => api.get('/api/dashboard/stats'),
  getSLASummary: () => api.get('/api/dashboard/sla-summary'),
}

// Maintenance API
export const maintenanceAPI = {
  getChecklistItems: (category) => api.get('/api/maintenance/checklist-items', { params: { category } }),
  createSession: (data) => api.post('/api/maintenance/sessions', data),
}

// Backup API
export const backupAPI = {
  getReports: (params) => api.get('/api/backup/reports', { params }),
  createReport: (data) => api.post('/api/backup/reports', data),
}

// Export API
export const exportAPI = {
  exportTickets: (data) => api.post('/api/export/tickets', data, { responseType: 'blob' }),
}

// Upload API
export const uploadAPI = {
  uploadImage: (file) => {
    const formData = new FormData()
    formData.append('file', file)
    return api.post('/api/upload/image', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
  },
}

// Knowledge Base API
export const knowledgeAPI = {
  search: (query, category) => api.get('/api/knowledge/search', { params: { query, category } }),
}

export default api
