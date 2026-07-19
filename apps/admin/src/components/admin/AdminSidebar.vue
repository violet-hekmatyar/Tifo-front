<script setup lang="ts">
defineProps<{ collapsed: boolean }>()

const menu = [
  { path: '/admin/dashboard', label: '工作台', mark: '⌂' },
  { path: '/admin/users', label: '用户管理', mark: '人' },
  { path: '/admin/content', label: '内容管理', mark: '文' },
  { path: '/admin/football', label: '足球数据', mark: '球' },
  { path: '/admin/files', label: '文件管理', mark: '件' },
]
</script>

<template>
  <aside class="admin-sidebar" :class="{ 'admin-sidebar--collapsed': collapsed }">
    <div class="admin-sidebar__brand">
      <span class="admin-sidebar__logo">南</span>
      <div v-if="!collapsed">
        <strong>南看台</strong>
        <small>管理后台</small>
      </div>
    </div>
    <nav aria-label="后台主导航">
      <RouterLink v-for="item in menu" :key="item.path" :to="item.path" class="admin-sidebar__link">
        <span class="admin-sidebar__mark">{{ item.mark }}</span>
        <span v-if="!collapsed">{{ item.label }}</span>
      </RouterLink>
    </nav>
  </aside>
</template>
