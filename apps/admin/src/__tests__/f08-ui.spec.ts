import ElementPlus from 'element-plus'
import { createPinia, setActivePinia } from 'pinia'
import { mount } from '@vue/test-utils'
import { createMemoryHistory, createRouter } from 'vue-router'
import { beforeEach, describe, expect, it } from 'vitest'

import AdminLayout from '@/layouts/AdminLayout.vue'
import LoginView from '@/views/auth/LoginView.vue'
import DashboardView from '@/views/dashboard/DashboardView.vue'
import ForbiddenView from '@/views/error/ForbiddenView.vue'
import NotFoundView from '@/views/error/NotFoundView.vue'
import AdminModulePlaceholder from '@/views/placeholders/AdminModulePlaceholder.vue'
import { useAuthStore } from '@/stores/auth'

describe('F08 admin UI', () => {
  beforeEach(() => setActivePinia(createPinia()))

  it('renders login fields, password toggle and no registration', async () => {
    const router = testRouter(LoginView)
    await router.push('/login')
    await router.isReady()
    const wrapper = mount(LoginView, { global: { plugins: [ElementPlus, router] } })
    expect(wrapper.text()).toContain('南看台管理后台')
    expect(wrapper.find('input[autocomplete="username"]').exists()).toBe(true)
    expect(wrapper.find('input[autocomplete="current-password"]').attributes('type')).toBe(
      'password',
    )
    expect(wrapper.text()).not.toContain('注册')
    await wrapper.find('form').trigger('submit')
    expect(wrapper.text()).toContain('请输入用户名')
  })

  it('renders admin shell, highlighted navigation and current admin', async () => {
    const auth = useAuthStore()
    auth.$patch({
      status: 'authenticated',
      user: {
        id: 1,
        username: 'admin_user',
        nickname: '管理员',
        roleType: 'ADMIN',
        status: 'ACTIVE',
      },
    })
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        {
          path: '/admin',
          component: AdminLayout,
          children: [{ path: 'dashboard', component: DashboardView }],
        },
      ],
    })
    await router.push('/admin/dashboard')
    await router.isReady()
    const wrapper = mount(AdminLayout, { global: { plugins: [ElementPlus, router] } })
    expect(wrapper.text()).toContain('工作台')
    expect(wrapper.text()).toContain('用户管理')
    expect(wrapper.text()).toContain('管理员')
    expect(wrapper.find('.router-link-active').exists()).toBe(true)
    await wrapper.find('.admin-topbar__toggle').trigger('click')
    expect(wrapper.classes()).toContain('admin-layout--collapsed')
  })

  it('dashboard and placeholders contain no fake statistics', () => {
    const auth = useAuthStore()
    auth.$patch({
      status: 'authenticated',
      user: { id: 1, username: 'admin_user', roleType: 'ADMIN', status: 'ACTIVE' },
    })
    const dashboard = mount(DashboardView, { global: { plugins: [ElementPlus] } })
    expect(dashboard.text()).toContain('F08 后台基础框架已完成')
    expect(dashboard.text()).not.toMatch(/用户总数|内容总数|比赛总数/)
    const placeholder = mount(AdminModulePlaceholder, {
      props: { title: '用户管理', scope: 'F09 接入。' },
      global: { plugins: [ElementPlus] },
    })
    expect(placeholder.text()).toContain('不展示假业务数据')
  })

  it('renders explicit 403 and 404 pages', () => {
    const router = testRouter(ForbiddenView)
    const forbidden = mount(ForbiddenView, { global: { plugins: [ElementPlus, router] } })
    expect(forbidden.text()).toContain('403')
    const notFound = mount(NotFoundView, { global: { plugins: [ElementPlus, router] } })
    expect(notFound.text()).toContain('404')
  })
})

function testRouter(component: typeof LoginView) {
  return createRouter({ history: createMemoryHistory(), routes: [{ path: '/login', component }] })
}
