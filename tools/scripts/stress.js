import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
    stages: [
        { duration: '30s', target: 20 },
        { duration: '30s', target: 20 },
        { duration: '30s', target: 0 },
    ],
};

export default () => {
    const baseUrl = __ENV.API_URL || 'http://localhost:8080';
    const urlRes = http.get(`${baseUrl}/api/health`);

    check(res, {
        'status - 200': (r) => r.status === 200
    })


    sleep(1);
};