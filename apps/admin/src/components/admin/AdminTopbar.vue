<script setup lang="ts">
import type { AdminUser } from '@/types/auth'
import AdminUserMenu from './AdminUserMenu.vue'

defineProps<{ collapsed: boolean; user: AdminUser }>()
const emit = defineEmits<{ toggle: []; logout: [] }>()
</script>

<template>
  <header class="admin-topbar">
    <button
      class="admin-topbar__toggle"
      type="button"
      :aria-label="collapsed ? '展开侧边栏' : '折叠侧边栏'"
      @click="emit('toggle')"
    >
      {{ collapsed ? '»' : '«' }}
    </button>
    <div class="admin-topbar__title">
      <strong>南看台管理后台</strong>
      <small>内部管理员工作区</small>
    </div>
    <AdminUserMenu :user="user" @logout="emit('logout')" />
  </header>
</template>
