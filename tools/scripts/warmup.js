import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
    stages: [
        { duration: '20s', target: 20 },
        { duration: '30s', target: 60 },
        { duration: '1m', target: 80 },
        { duration: '10s', target: 0 },
    ],
};

export default function () {
    const baseUrl = __ENV.API_URL;
    http.get(`${baseUrl}/compute?n=25`);

    http.post(`${baseUrl}/records`);

    const randomId = Math.floor(Math.random() * 10000) + 1;
    http.get(`${baseUrl}/records/${randomId}`)
    sleep(0.5);

}