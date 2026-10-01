import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
    stages: [
        { duration: '5s', target: 10 },
        { duration: '5s', target: 10 },
        { duration: '2s', target: 0 },
    ],
};

export default () => {
    const baseUrl = __ENV.API_URL || 'http://localhost:8080';
    const urlRes = http.get(`${baseUrl}/health`);

    check(urlRes, {
        'status - 200': (r) => r.status === 200
    })


    sleep(1);
};