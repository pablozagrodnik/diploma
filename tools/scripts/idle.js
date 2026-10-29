import { sleep } from 'k6';

export const options = {
    vus: 1,
    duration: '2m',
    systemTags: ['status', 'error'],

}

export default function () {
    sleep(1);
}