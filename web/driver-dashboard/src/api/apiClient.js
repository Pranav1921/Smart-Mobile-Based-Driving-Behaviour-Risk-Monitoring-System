import axios from "axios";

const BACKEND_HOST = typeof window !== 'undefined' && window.location.hostname && window.location.hostname !== 'localhost'
  ? window.location.hostname
  : 'localhost';

const apiClient = axios.create({
  baseURL: `http://${BACKEND_HOST}:3000/api/v1`,
  headers: {
    "Content-Type": "application/json",
  },
});

// Automatically inject JWT token into requests
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem("fg_admin_token");
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Redirect to login if unauthorized
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem("fg_admin_token");
      localStorage.removeItem("fg_admin_user");
      if (window.location.pathname !== "/") {
        window.location.href = "/";
      }
    }
    return Promise.reject(error);
  }
);

export default apiClient;
