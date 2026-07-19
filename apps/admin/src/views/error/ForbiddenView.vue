<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
const auth = useAuthStore()
const router = useRouter()
function leave(): void {
  auth.logout()
  void router.replace('/login')
}
</script>
<template>
  <main class="error-view">
    <el-result icon="error" title="403" sub-title="当前账号没有后台管理权限。"
      ><template #extra
        ><el-button type="primary" @click="leave">返回登录</el-button></template
      ></el-result
    >
  </main>
</template>
