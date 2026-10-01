import http from 'k6/http';
import { sleep, check } from 'k6';


export const options = {
    stages: [
        { duration: '5s', target: 10 },
        { duration: '5s', target: 10 },
        { duration: '2s', target: 0 },
    ],
};

export default () => {
    const baseUrl = __ENV.API_URL || 'http://localhost:8080';
    const healthRes = http.get(`${baseUrl}/health`);

    check(healthRes, {
        'health status - 200': (r) => r.status === 200
    });

    const resetRes = http.post(`${baseUrl}/reset`);
    check(resetRes, {
        'reset status - 200': (r) => r.status === 200
    });

    sleep(1);
};