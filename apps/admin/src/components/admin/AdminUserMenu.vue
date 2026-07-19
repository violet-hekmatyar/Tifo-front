<script setup lang="ts">
import type { AdminUser } from '@/types/auth'

defineProps<{ user: AdminUser }>()
const emit = defineEmits<{ logout: [] }>()
</script>

<template>
  <el-dropdown trigger="click">
    <button class="admin-user-menu" type="button">
      <span class="admin-user-menu__avatar">{{
        (user.nickname || user.username).slice(0, 1)
      }}</span>
      <span class="admin-user-menu__text">
        <strong>{{ user.nickname || user.username }}</strong>
        <small>{{ user.roleType }}</small>
      </span>
    </button>
    <template #dropdown>
      <el-dropdown-menu>
        <el-dropdown-item disabled>{{ user.username }}</el-dropdown-item>
        <el-dropdown-item divided @click="emit('logout')">退出登录</el-dropdown-item>
      </el-dropdown-menu>
    </template>
  </el-dropdown>
</template>
