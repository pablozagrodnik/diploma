import http from 'k6/http';
import { sleep } from 'k6';


export const options = {
    stages: [
        { duration: '10s', target: 150 },
        { duration: '30s', target: 150 },
        { duration: '15s', target: 500 },
        { duration: '30s', target: 500 },
        { duration: '15s', target: 1000 },
        { duration: '3m', target: 1000 },
        { duration: '10s', target: 0 },
    ],
    systemTags: ['status', 'error'],
};

export default function () {
    const baseUrl = __ENV.API_URL;

    http.get(`${baseUrl}/compute?n=25`);

    sleep(0.1);
};