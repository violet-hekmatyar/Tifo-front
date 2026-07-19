<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
const auth = useAuthStore()
const router = useRouter()
async function retry(): Promise<void> {
  await auth.retryBootstrap()
  if (auth.authenticated) await router.replace('/admin/dashboard')
}
function leave(): void {
  auth.logout()
  void router.replace('/login')
}
</script>
<template>
  <main class="error-view">
    <el-result
      icon="warning"
      title="会话校验失败"
      :sub-title="auth.message || '网络暂时不可用，Access Token 已保留。'"
      ><template #extra
        ><el-button type="primary" @click="retry">重试</el-button
        ><el-button @click="leave">退出登录</el-button></template
      ></el-result
    >
  </main>
</template>
