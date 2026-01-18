import axios from 'axios';

const client = axios.create({
    baseURL: '/api', // Relative path to work with Nginx proxy on any host
    headers: {
        'Content-Type': 'application/json',
    },
});

export default client;
