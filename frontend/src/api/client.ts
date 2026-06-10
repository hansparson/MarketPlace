import axios from 'axios';

const client = axios.create({
    baseURL: '/api', // Relative path to work with Nginx proxy on any host
    headers: {
        'Content-Type': 'application/json',
    },
});

// Response interceptor for handling global errors (like 401 Unauthorized)
client.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response && error.response.status === 401) {
            // Token is invalid or expired
            localStorage.removeItem('token');
            localStorage.removeItem('role');
            
            // Redirect to home/login if we are not already there
            if (!window.location.pathname.includes('/auth/login')) {
                window.location.href = '/';
            }
        }
        return Promise.reject(error);
    }
);

export default client;
