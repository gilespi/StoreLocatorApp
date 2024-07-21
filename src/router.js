import { createRouter, createWebHistory } from 'vue-router';
import StoreLocator from "./components/StoreLocator.vue";

const routes = [
    {
        path: '/',
        name: 'StoreLocator',
        component: StoreLocator,
    },
];

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes,
});

export default router;