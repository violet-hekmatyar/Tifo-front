import { createRouter, createWebHistory } from 'vue-router'

import AdminLayout from '@/layouts/AdminLayout.vue'
import { createAuthGuard } from './guards'
import { useAuthStore } from '@/stores/auth'
import DashboardView from '@/views/dashboard/DashboardView.vue'
import LoginView from '@/views/auth/LoginView.vue'
import ForbiddenView from '@/views/error/ForbiddenView.vue'
import NotFoundView from '@/views/error/NotFoundView.vue'
import SessionErrorView from '@/views/error/SessionErrorView.vue'
import AdminModulePlaceholder from '@/views/placeholders/AdminModulePlaceholder.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: '/admin/dashboard' },
    { path: '/login', name: 'login', component: LoginView },
    { path: '/403', name: 'forbidden', component: ForbiddenView },
    { path: '/session-error', name: 'session-error', component: SessionErrorView },
    {
      path: '/admin',
      component: AdminLayout,
      meta: { requiresAdmin: true },
      children: [
        { path: '', redirect: '/admin/dashboard' },
        { path: 'dashboard', name: 'dashboard', component: DashboardView },
        {
          path: 'users',
          name: 'users',
          component: AdminModulePlaceholder,
          props: { title: '用户管理', scope: 'F09 将接入真实用户列表与状态维护。' },
        },
        {
          path: 'content',
          name: 'content',
          component: AdminModulePlaceholder,
          props: { title: '内容管理', scope: 'F09 将接入真实内容管理与审核能力。' },
        },
        {
          path: 'football',
          name: 'football',
          component: AdminModulePlaceholder,
          props: { title: '足球数据', scope: 'F10 将接入真实联赛、球队、球员和比赛维护。' },
        },
        {
          path: 'files',
          name: 'files',
          component: AdminModulePlaceholder,
          props: { title: '文件管理', scope: 'F11 将接入真实文件管理能力。' },
        },
      ],
    },
    { path: '/:pathMatch(.*)*', name: 'not-found', component: NotFoundView },
  ],
})

router.beforeEach((to, from) => createAuthGuard(useAuthStore())(to, from, () => undefined))

export default router
