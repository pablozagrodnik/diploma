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

    http.get(`${baseUrl}/compute?n=25`);

    sleep(0.1);
};