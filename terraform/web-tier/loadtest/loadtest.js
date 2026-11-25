import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 50 },   // ramp up
    { duration: '6m', target: 200 },  // sustained load
    { duration: '2m', target: 0 },    // ramp down
  ],
};

export default function () {
  const res = http.get(`http://${__ENV.ALB}/api/food/list`);
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(0.1);
}
