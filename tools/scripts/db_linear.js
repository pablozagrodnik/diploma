import http from 'k6/http';
import { sleep } from 'k6';


export const options = {
    stages: [
        { duration: '3m', target: 1000 },
        { duration: '15s', target: 0 },
    ],
    systemTags: ['status', 'error'],
};

export default function () {
    const baseUrl = __ENV.API_URL;

    http.post(`${baseUrl}/records`);

    const randomId = Math.floor(Math.random() * 10000) +1;
    http.get(`${baseUrl}/records/${randomId}`);

    sleep(0.1);
};