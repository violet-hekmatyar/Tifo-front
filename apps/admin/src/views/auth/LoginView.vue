<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { safeAdminRedirect } from '@/router/guards'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const router = useRouter()
const route = useRoute()
const showPassword = ref(false)
const form = reactive({ username: '', password: '' })
const errors = reactive({ username: '', password: '' })

async function submit(): Promise<void> {
  errors.username = form.username.trim() ? '' : '请输入用户名。'
  errors.password = form.password ? '' : '请输入密码。'
  if (errors.username || errors.password || auth.submitting) return
  if (await auth.login(form.username, form.password)) {
    await router.replace(safeAdminRedirect(route.query.redirect))
  }
}
</script>

<template>
  <main class="login-page">
    <section class="login-page__brand">
      <div class="login-page__badge">南</div>
      <h1>南看台管理后台</h1>
      <p>仅限已授权的内部管理员访问</p>
    </section>
    <el-card class="login-card" shadow="always">
      <template #header><strong>管理员登录</strong></template>
      <form novalidate @submit.prevent="submit">
        <label for="admin-username">用户名</label>
        <el-input
          id="admin-username"
          v-model="form.username"
          autocomplete="username"
          :disabled="auth.submitting"
          @keyup.enter="submit"
        />
        <p v-if="errors.username" class="form-error">{{ errors.username }}</p>
        <label for="admin-password">密码</label>
        <el-input
          id="admin-password"
          v-model="form.password"
          :type="showPassword ? 'text' : 'password'"
          autocomplete="current-password"
          :disabled="auth.submitting"
          @keyup.enter="submit"
        >
          <template #suffix
            ><button class="password-toggle" type="button" @click="showPassword = !showPassword">
              {{ showPassword ? '隐藏' : '显示' }}
            </button></template
          >
        </el-input>
        <p v-if="errors.password" class="form-error">{{ errors.password }}</p>
        <el-alert
          v-if="auth.message"
          :title="auth.message"
          type="error"
          :closable="false"
          show-icon
        />
        <el-button
          class="login-card__submit"
          type="primary"
          native-type="submit"
          :loading="auth.submitting"
          :disabled="auth.submitting"
          >登录</el-button
        >
      </form>
    </el-card>
  </main>
</template>
