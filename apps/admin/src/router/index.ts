import { createRouter, createWebHistory } from 'vue-router'
import NotFoundView from '@/views/error/NotFoundView.vue'
import SkeletonView from '@/views/skeleton/SkeletonView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'skeleton',
      component: SkeletonView,
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: NotFoundView,
    },
  ],
})

export default router
